defmodule Commanded.Event.ResetEventHandlerTest do
  use ExUnit.Case

  import Commanded.Assertions.EventAssertions
  import ExUnit.CaptureLog

  alias Commanded.Event.Handler
  alias Commanded.Event.Mapper
  alias Commanded.EventStore
  alias Commanded.EventStore.RecordedEvent
  alias Commanded.EventStore.Subscription
  alias Commanded.ExampleDomain.BankAccount.BankAccountHandler
  alias Commanded.ExampleDomain.BankAccount.Events.BankAccountOpened
  alias Commanded.ExampleDomain.BankApp
  alias Commanded.Helpers.Wait
  alias Commanded.UUID

  defmodule PendingSubscriptionHandler do
    use Commanded.Event.Handler,
      application: Commanded.ExampleDomain.BankApp,
      name: "PendingSubscriptionHandler"
  end

  describe "reset event handler" do
    setup do
      start_supervised!(BankApp)
      :ok
    end

    test "should be reset when starting from `:origin`" do
      stream_uuid = UUID.uuid4()
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]

      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!(BankAccountHandler)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["ACC123"]
      end)

      :ok = BankAccountHandler.change_prefix("PREF_")

      send(handler, :reset)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["PREF_ACC123"]
      end)
    end

    test "should discard events delivered by the subscription before the reset" do
      stream_uuid = UUID.uuid4()
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]

      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!(BankAccountHandler)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["ACC123"]
      end)

      :ok = :sys.suspend(handler)

      send(handler, :reset)

      stale_events = [%BankAccountOpened{account_number: "ACC456", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 1, to_event_data(stale_events))

      Wait.until(fn ->
        assert {:messages, [:reset, {:events, [_event]}]} = Process.info(handler, :messages)
      end)

      :ok = :sys.resume(handler)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["ACC123", "ACC456"]
      end)
    end

    test "should discard the `DOWN` message of a subscription that died before the reset" do
      stream_uuid = UUID.uuid4()
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]

      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!(BankAccountHandler)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["ACC123"]
      end)

      %Handler{subscription: %Subscription{subscription_pid: subscription_pid}} =
        :sys.get_state(handler)

      :ok = BankAccountHandler.change_prefix("PREF_")

      :ok = :sys.suspend(handler)

      send(handler, :reset)

      :ok = EventStore.unsubscribe(BankApp, subscription_pid)

      Wait.until(fn ->
        assert {:messages, [:reset, {:DOWN, _ref, :process, ^subscription_pid, _reason}]} =
                 Process.info(handler, :messages)
      end)

      log =
        capture_log(fn ->
          :ok = :sys.resume(handler)

          Wait.until(fn ->
            assert BankAccountHandler.current_accounts() == ["PREF_ACC123"]
          end)
        end)

      refute log =~ "received unexpected message"
    end

    test "should discard the `subscribed` message of a subscription deleted by a later reset" do
      stream_uuid = UUID.uuid4()
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]

      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!(BankAccountHandler)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["ACC123"]
      end)

      :ok = BankAccountHandler.change_prefix("PREF_")

      :ok = :sys.suspend(handler)

      send(handler, :reset)
      send(handler, :reset)

      Wait.until(fn ->
        assert {:messages, [:reset, :reset]} = Process.info(handler, :messages)
      end)

      log =
        capture_log(fn ->
          :ok = :sys.resume(handler)

          Wait.until(fn ->
            assert BankAccountHandler.current_accounts() == ["PREF_ACC123"]
          end)
        end)

      refute log =~ "received unexpected message"
    end

    test "should keep a `subscribed` message sent by anything other than the reset subscription" do
      stream_uuid = UUID.uuid4()
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]

      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!(BankAccountHandler)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["ACC123"]
      end)

      :ok = BankAccountHandler.change_prefix("PREF_")

      :ok = :sys.suspend(handler)

      send(handler, :reset)
      send(handler, {:subscribed, self()})

      Wait.until(fn ->
        assert {:messages, [:reset, {:subscribed, _}]} = Process.info(handler, :messages)
      end)

      log =
        capture_log(fn ->
          :ok = :sys.resume(handler)

          Wait.until(fn ->
            assert BankAccountHandler.current_accounts() == ["PREF_ACC123"]
          end)
        end)

      assert log =~ "received unexpected message: {:subscribed, #{inspect(self())}}"
    end

    test "should keep messages unrelated to the subscription it reset" do
      stream_uuid = UUID.uuid4()
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]

      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!(BankAccountHandler)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["ACC123"]
      end)

      :ok = BankAccountHandler.change_prefix("PREF_")

      :ok = :sys.suspend(handler)

      send(handler, :reset)
      send(handler, :first_unrelated_message)
      send(handler, {:second_unrelated_message, self()})

      Wait.until(fn ->
        assert {:messages, [:reset, :first_unrelated_message, {:second_unrelated_message, _}]} =
                 Process.info(handler, :messages)
      end)

      log =
        capture_log(fn ->
          :ok = :sys.resume(handler)

          Wait.until(fn ->
            assert BankAccountHandler.current_accounts() == ["PREF_ACC123"]
          end)
        end)

      assert log =~
               ~r/received unexpected message: :first_unrelated_message.*received unexpected message: \{:second_unrelated_message/s
    end

    test "should discard every message queued by the subscription it reset" do
      level = Logger.level()
      Logger.configure(level: :debug)
      on_exit(fn -> Logger.configure(level: level) end)

      stream_uuid = UUID.uuid4()
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]

      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!(BankAccountHandler)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["ACC123"]
      end)

      %Handler{subscription: %Subscription{subscription_pid: subscription_pid}} =
        :sys.get_state(handler)

      :ok = BankAccountHandler.change_prefix("PREF_")

      :ok = :sys.suspend(handler)

      send(handler, :reset)
      send(handler, {:events, []})
      send(handler, {:events, []})
      send(handler, {:subscribed, subscription_pid})

      Wait.until(fn ->
        assert {:messages,
                [:reset, {:events, []}, {:events, []}, {:subscribed, ^subscription_pid}]} =
                 Process.info(handler, :messages)
      end)

      log =
        capture_log(fn ->
          :ok = :sys.resume(handler)

          Wait.until(fn ->
            assert BankAccountHandler.current_accounts() == ["PREF_ACC123"]
          end)
        end)

      assert log =~ "discarded 3 message(s) queued by the subscription it reset"
      refute log =~ "received unexpected message"
    end

    test "should be reset while its subscription attempt is still being retried" do
      {:ok, competing_subscription} =
        EventStore.subscribe_to(BankApp, :all, "PendingSubscriptionHandler", self(), :origin, [])

      handler = start_supervised!(PendingSubscriptionHandler)

      Wait.until(fn ->
        assert %Handler{
                 subscribe_timer: subscribe_timer,
                 subscription: %Subscription{subscription_pid: nil}
               } = :sys.get_state(handler)

        assert is_reference(subscribe_timer)
      end)

      :ok = EventStore.unsubscribe(BankApp, competing_subscription)

      ref = Process.monitor(handler)

      send(handler, :reset)

      refute_receive {:DOWN, ^ref, :process, ^handler, _reason}

      Wait.until(fn ->
        assert %Handler{subscription: %Subscription{subscription_pid: subscription_pid}} =
                 :sys.get_state(handler)

        assert is_pid(subscription_pid)
      end)
    end

    test "should cancel a pending subscription retry when reset" do
      {:ok, competing_subscription} =
        EventStore.subscribe_to(BankApp, :all, "PendingSubscriptionHandler", self(), :origin, [])

      handler = start_supervised!(PendingSubscriptionHandler)

      subscribe_timer =
        Wait.until(fn ->
          assert %Handler{
                   subscribe_timer: subscribe_timer,
                   subscription: %Subscription{subscription_pid: nil}
                 } = :sys.get_state(handler)

          assert is_reference(subscribe_timer)

          subscribe_timer
        end)

      :ok = EventStore.unsubscribe(BankApp, competing_subscription)

      send(handler, :reset)

      Wait.until(fn ->
        assert %Handler{
                 subscribe_timer: nil,
                 subscription: %Subscription{subscription_pid: subscription_pid}
               } = :sys.get_state(handler)

        assert is_pid(subscription_pid)
      end)

      assert Process.read_timer(subscribe_timer) == false
    end

    test "should be reset while another subscriber still holds its subscription name" do
      {:ok, competing_subscription} =
        EventStore.subscribe_to(BankApp, :all, "PendingSubscriptionHandler", self(), :origin, [])

      assert_receive {:subscribed, ^competing_subscription}

      handler = start_supervised!(PendingSubscriptionHandler)

      Wait.until(fn ->
        assert %Handler{
                 subscribe_timer: subscribe_timer,
                 subscription: %Subscription{subscription_pid: nil}
               } = :sys.get_state(handler)

        assert is_reference(subscribe_timer)
      end)

      event_store_pid = Process.whereis(Module.concat([BankApp, "EventStore"]))
      handler_ref = Process.monitor(handler)
      event_store_ref = Process.monitor(event_store_pid)

      send(handler, :reset)

      refute_receive {:DOWN, ^handler_ref, :process, ^handler, _reason}
      refute_receive {:DOWN, ^event_store_ref, :process, ^event_store_pid, _reason}

      stream_uuid = UUID.uuid4()
      events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(events))

      assert_receive {:events, [%RecordedEvent{}]}
    end

    test "should discard a subscription retry that expired before the reset" do
      {:ok, competing_subscription} =
        EventStore.subscribe_to(BankApp, :all, "PendingSubscriptionHandler", self(), :origin, [])

      handler = start_supervised!(PendingSubscriptionHandler)

      Wait.until(fn ->
        assert %Handler{
                 subscribe_timer: subscribe_timer,
                 subscription: %Subscription{subscription_pid: nil}
               } = :sys.get_state(handler)

        assert is_reference(subscribe_timer)
      end)

      :ok = :sys.suspend(handler)

      send(handler, :reset)

      # The retry has to expire while the handler is suspended, so its message is already queued
      # behind the reset by the time cancelling the timer can no longer recall it.
      Wait.until(3_000, fn ->
        assert {:messages, [:reset, :subscribe_to_events]} = Process.info(handler, :messages)
      end)

      :ok = EventStore.unsubscribe(BankApp, competing_subscription)

      log =
        capture_log(fn ->
          :ok = :sys.resume(handler)

          Wait.until(fn ->
            assert %Handler{
                     subscribe_timer: nil,
                     subscription: %Subscription{subscription_pid: subscription_pid}
                   } = :sys.get_state(handler)

            assert is_pid(subscription_pid)
          end)
        end)

      refute log =~ "failed to subscribe to event store"
    end

    test "should be reset when starting from `:current`" do
      stream_uuid = UUID.uuid4()

      # Ignored initial events
      initial_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(initial_events))

      handler = start_supervised!({BankAccountHandler, start_from: :current})

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == []
      end)

      :ok = BankAccountHandler.change_prefix("PREF_")

      %Handler{subscription: %Subscription{subscription_pid: subscription_pid}} =
        :sys.get_state(handler)

      send(handler, :reset)

      # Subscribing from `:current` resolves the checkpoint when the replacement subscription is
      # created, so an event appended before that lands behind it and is never delivered.
      Wait.until(fn ->
        assert %Handler{subscription: %Subscription{subscription_pid: reset_subscription_pid}} =
                 :sys.get_state(handler)

        assert is_pid(reset_subscription_pid)
        refute reset_subscription_pid == subscription_pid
      end)

      new_event = [%BankAccountOpened{account_number: "ACC1234", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 1, to_event_data(new_event))

      wait_for_event(BankApp, BankAccountOpened, fn event, recorded_event ->
        event.account_number == "ACC1234" and recorded_event.event_number == 2
      end)

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["PREF_ACC1234"]
      end)
    end

    test "should not apply an event delivered before a reset that starts from `:current`" do
      stream_uuid = UUID.uuid4()

      # Ignored initial events
      ignored_events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 0, to_event_data(ignored_events))

      handler = start_supervised!({BankAccountHandler, start_from: :current})

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == []
      end)

      %Handler{subscription: %Subscription{subscription_pid: subscription_pid}} =
        :sys.get_state(handler)

      :ok = BankAccountHandler.change_prefix("PREF_")

      :ok = :sys.suspend(handler)

      send(handler, :reset)

      in_flight_events = [%BankAccountOpened{account_number: "ACC456", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 1, to_event_data(in_flight_events))

      Wait.until(fn ->
        assert {:messages, [:reset, {:events, [_event]}]} = Process.info(handler, :messages)
      end)

      :ok = :sys.resume(handler)

      Wait.until(fn ->
        assert %Handler{subscription: %Subscription{subscription_pid: reset_subscription_pid}} =
                 :sys.get_state(handler)

        assert is_pid(reset_subscription_pid)
        refute reset_subscription_pid == subscription_pid
      end)

      new_events = [%BankAccountOpened{account_number: "ACC789", initial_balance: 1_000}]
      :ok = EventStore.append_to_stream(BankApp, stream_uuid, 2, to_event_data(new_events))

      Wait.until(fn ->
        assert BankAccountHandler.current_accounts() == ["PREF_ACC789"]
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
