defmodule Commanded.Event.BatchResetEventHandlerTest do
  use ExUnit.Case

  import Commanded.Assertions.EventAssertions

  alias Commanded.Event.Handler
  alias Commanded.Event.Mapper
  alias Commanded.EventStore
  alias Commanded.EventStore.Subscription
  alias Commanded.ExampleDomain.BankAccount.BankAccountBatchHandler
  alias Commanded.ExampleDomain.BankAccount.Events.BankAccountOpened
  alias Commanded.ExampleDomain.BankApp
  alias Commanded.Helpers.Wait
  alias Commanded.UUID

  describe "reset batch event handler" do
    setup do
      start_supervised!(BankApp)
      :ok
    end

    test "should be reset when starting from `:origin`" do
      stream_uuid = UUID.uuid4()
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]

      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!(BankAccountBatchHandler)

      Wait.until(fn ->
        assert BankAccountBatchHandler.current_accounts() == ["ACC123"]
      end)

      :ok = BankAccountBatchHandler.change_prefix("PREF_")

      send(handler, :reset)

      Wait.until(fn ->
        assert BankAccountBatchHandler.current_accounts() == ["PREF_ACC123"]
      end)
    end

    test "should discard events buffered for a batch before the reset" do
      stream_uuid = UUID.uuid4()

      handler =
        start_supervised!({BankAccountBatchHandler, start_from: :current, batch_timeout: 500})

      Wait.until(fn ->
        assert BankAccountBatchHandler.subscribed?()
      end)

      %Handler{subscription: %Subscription{subscription_pid: subscription_pid}} =
        :sys.get_state(handler)

      buffered_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(buffered_events))

      Wait.until(fn ->
        assert %Handler{batch_buffer: [_buffered_event]} = :sys.get_state(handler)
      end)

      :ok = BankAccountBatchHandler.change_prefix("PREF_")

      send(handler, :reset)

      Wait.until(fn ->
        assert %Handler{subscription: %Subscription{subscription_pid: pid}} =
                 :sys.get_state(handler)

        refute pid in [nil, subscription_pid]
      end)

      events_after_reset = [%BankAccountOpened{account_number: "ACC456", initial_balance: 2_000}]

      :ok =
        EventStore.append_to_stream(BankApp, stream_uuid, 1, to_event_data(events_after_reset))

      Wait.until(2_000, fn ->
        assert BankAccountBatchHandler.current_accounts() == ["PREF_ACC456"]
      end)
    end

    test "should rearm the batch timer when its timeout expired before the reset" do
      stream_uuid = UUID.uuid4()

      handler = start_supervised!({BankAccountBatchHandler, batch_timeout: 1_000})

      Wait.until(fn ->
        assert BankAccountBatchHandler.subscribed?()
      end)

      buffered_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(buffered_events))

      Wait.until(fn ->
        assert %Handler{batch_buffer: [_buffered_event], batch_timer_ref: batch_timer_ref} =
                 :sys.get_state(handler)

        assert is_reference(batch_timer_ref)
      end)

      :ok = BankAccountBatchHandler.change_prefix("PREF_")

      :ok = :sys.suspend(handler)

      send(handler, :reset)

      # Letting the batch timeout expire while suspended queues its message behind the reset, so
      # the reset must clear it: a `batch_timer_ref` left behind keeps the replayed batch from
      # ever arming a timer of its own.
      Wait.until(3_000, fn ->
        assert {:messages, [:reset, :flush_batch_timeout]} = Process.info(handler, :messages)
      end)

      :ok = :sys.resume(handler)

      Wait.until(5_000, fn ->
        assert BankAccountBatchHandler.current_accounts() == ["PREF_ACC123"]
      end)
    end

    test "should be reset when starting from `:current`" do
      stream_uuid = UUID.uuid4()

      # Ignored initial events - add these BEFORE starting the handler
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      # Start handler with :current - should ignore existing events
      handler = start_supervised!({BankAccountBatchHandler, start_from: :current})

      Wait.until(fn ->
        assert BankAccountBatchHandler.current_accounts() == []
      end)

      :ok = BankAccountBatchHandler.change_prefix("PREF_")

      # Use a more robust reset approach with proper synchronization
      ref = Process.monitor(handler)
      send(handler, :reset)

      # Wait for the reset message to be processed
      receive do
        {:DOWN, ^ref, :process, ^handler, _reason} ->
          # Handler died, this shouldn't happen
          flunk("Handler died during reset")
      after
        # Reset message should be processed by now
        100 -> :ok
      end

      Process.demonitor(ref)

      # Ensure reset completed and accounts are cleared
      Wait.until(fn ->
        assert BankAccountBatchHandler.current_accounts() == []
      end)

      # Add new event after reset
      new_event = [%BankAccountOpened{account_number: "ACC1234", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 1, to_event_data(new_event))

      wait_for_event(BankApp, BankAccountOpened, fn event, recorded_event ->
        event.account_number == "ACC1234" and recorded_event.event_number == 2
      end)

      Wait.until(fn ->
        assert BankAccountBatchHandler.current_accounts() == ["PREF_ACC1234"]
      end)
    end
  end

  defp to_event_data(events) do
    Mapper.map_to_event_data(events,
      causation_id: UUID.uuid4(),
      correlation_id: UUID.uuid4(),
      metadata: %{}
    )
  end
end
