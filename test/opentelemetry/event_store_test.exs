defmodule Commanded.OpenTelemetry.EventStoreTest do
  @moduledoc """
  Tests for EventStore OpenTelemetry instrumentation.

  Follows the same patterns as ApplicationTest, AggregateTest, etc.
  """

  use Commanded.OpenTelemetryCase, async: false

  import Commanded.TestSupport.Factory

  alias Commanded.Application, as: CommandedApplication
  alias Commanded.Application.Config, as: AppConfig
  alias Commanded.DefaultApp
  alias Commanded.EventStore
  alias Commanded.EventStore.{AdapterTestData, SnapshotData}
  alias Commanded.OpenTelemetry.EventStore, as: OTelEventStore
  alias Commanded.UUID

  @events ~w(
    append_to_stream
    delete_snapshot
    read_snapshot
    record_snapshot
    stream_forward
  )a

  setup do
    detach_handlers()
    OTelEventStore.setup()

    :ok
  end

  describe "setup/0" do
    test "attaches telemetry handlers for event store operations" do
      detach_handlers()

      OTelEventStore.setup()

      for event <- @events do
        for suffix <- [:start, :stop, :exception] do
          handlers = :telemetry.list_handlers([:commanded, :event_store, event, suffix])

          assert Enum.any?(
                   handlers,
                   &match?(%{id: {OTelEventStore, ^event}}, &1)
                 ),
                 "Expected handler for event [:commanded, :event_store, #{event}, #{suffix}]"
        end
      end
    end

    test "calling setup twice raises MatchError (fail fast)" do
      detach_handlers()

      :ok = OTelEventStore.setup()

      handlers = :telemetry.list_handlers([:commanded, :event_store, :append_to_stream, :start])
      assert length(handlers) == 1

      assert_raise MatchError, fn ->
        OTelEventStore.setup()
      end
    end
  end

  describe "runtime spans" do
    setup do
      start_supervised!(DefaultApp)

      [destination_name: expected_event_store_destination(DefaultApp)]
    end

    test "append_to_stream uses the configured event store as destination", %{
      destination_name: destination_name
    } do
      stream_uuid = UUID.uuid4()

      assert :ok = EventStore.append_to_stream(DefaultApp, stream_uuid, 0, build_events(1))

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("append_to_stream #{destination_name}")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :publish,
               "messaging.operation.name": "append_to_stream",
               "messaging.destination.name": destination_name,
               "code.function": "append_to_stream",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.stream.uuid": stream_uuid,
               "commanded.expected_version": 0,
               "commanded.event.count": 1,
               "db.system": :in_memory
             }
    end

    test "stream_forward uses the configured event store as destination", %{
      destination_name: destination_name
    } do
      stream_uuid = UUID.uuid4()

      assert :ok = EventStore.append_to_stream(DefaultApp, stream_uuid, 0, build_events(1))
      _ = assert_receive_span_named("append_to_stream #{destination_name}")

      assert [_event] = EventStore.stream_forward(DefaultApp, stream_uuid, 0)

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("stream_forward #{destination_name}")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :receive,
               "messaging.operation.name": "stream_forward",
               "messaging.destination.name": destination_name,
               "code.function": "stream_forward",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.stream.uuid": stream_uuid,
               "commanded.stream.start_version": 0,
               "commanded.stream.batch_size": 1000,
               "db.system": :in_memory
             }
    end

    test "record_snapshot uses the configured event store as destination", %{
      destination_name: destination_name
    } do
      source_uuid = UUID.uuid4()
      snapshot = build_snapshot(source_uuid)

      assert :ok = EventStore.record_snapshot(DefaultApp, snapshot)

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("record_snapshot #{destination_name}")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :publish,
               "messaging.operation.name": "record_snapshot",
               "messaging.destination.name": destination_name,
               "code.function": "record_snapshot",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.source.uuid": source_uuid,
               "db.system": :in_memory
             }
    end

    test "read_snapshot uses the configured event store as destination", %{
      destination_name: destination_name
    } do
      source_uuid = UUID.uuid4()
      snapshot = build_snapshot(source_uuid)

      assert :ok = EventStore.record_snapshot(DefaultApp, snapshot)
      _ = assert_receive_span_named("record_snapshot #{destination_name}")

      assert {:ok, %SnapshotData{source_uuid: ^source_uuid}} =
               EventStore.read_snapshot(DefaultApp, source_uuid)

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("read_snapshot #{destination_name}")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :receive,
               "messaging.operation.name": "read_snapshot",
               "messaging.destination.name": destination_name,
               "code.function": "read_snapshot",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.source.uuid": source_uuid,
               "db.system": :in_memory
             }
    end

    test "delete_snapshot uses the configured event store as destination", %{
      destination_name: destination_name
    } do
      source_uuid = UUID.uuid4()
      snapshot = build_snapshot(source_uuid)

      assert :ok = EventStore.record_snapshot(DefaultApp, snapshot)
      _ = assert_receive_span_named("record_snapshot #{destination_name}")

      assert :ok = EventStore.delete_snapshot(DefaultApp, source_uuid)

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("delete_snapshot #{destination_name}")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.name": "delete_snapshot",
               "messaging.destination.name": destination_name,
               "code.function": "delete_snapshot",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.source.uuid": source_uuid,
               "db.system": :in_memory
             }
    end

    test "stream_forward marks the span as an error when the stream is missing", %{
      destination_name: destination_name
    } do
      stream_uuid = UUID.uuid4()

      assert {:error, :stream_not_found} = EventStore.stream_forward(DefaultApp, stream_uuid)

      assert span(
               kind: :client,
               status: {:status, :error, ":stream_not_found"},
               attributes: attributes
             ) = assert_receive_span_named("stream_forward #{destination_name}")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :receive,
               "messaging.operation.name": "stream_forward",
               "messaging.destination.name": destination_name,
               "code.function": "stream_forward",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.stream.uuid": stream_uuid,
               "commanded.stream.start_version": 0,
               "commanded.stream.batch_size": 1000,
               "db.system": :in_memory,
               "error.type": ":stream_not_found"
             }
    end

    test "append_to_stream marks the span as an error when the expected version is stale", %{
      destination_name: destination_name
    } do
      stream_uuid = UUID.uuid4()
      span_name = "append_to_stream #{destination_name}"

      assert :ok = EventStore.append_to_stream(DefaultApp, stream_uuid, 0, build_events(1))
      _ = assert_receive_span_named(span_name)

      assert {:error, :wrong_expected_version} =
               EventStore.append_to_stream(DefaultApp, stream_uuid, 0, build_events(1))

      assert span(status: {:status, :error, ":wrong_expected_version"}, attributes: attributes) =
               assert_receive_span_named(span_name)

      assert %{"error.type": ":wrong_expected_version"} = :otel_attributes.map(attributes)
    end
  end

  describe "defensive destination lookup" do
    test "emits a telemetry warning when application lookup fails" do
      warning_handler = attach_warning_handler()
      on_exit(fn -> :telemetry.detach(warning_handler) end)

      stream_uuid = UUID.uuid4()
      application = MissingApplication

      assert_raise RuntimeError, fn ->
        EventStore.append_to_stream(application, stream_uuid, 0, build_events(1))
      end

      assert_receive {:warning, [:commanded, :opentelemetry, :warning], %{count: 1},
                      %{
                        message:
                          "Failed to resolve event store adapter metadata, leaving event store destination unset",
                        application: ^application,
                        error: %RuntimeError{},
                        tracer_id: OTelEventStore
                      }}
    end

    test "emits a telemetry warning when application input is malformed" do
      warning_handler = attach_warning_handler()
      on_exit(fn -> :telemetry.detach(warning_handler) end)

      stream_uuid = UUID.uuid4()
      application = "not-an-application"

      assert_raise FunctionClauseError, fn ->
        EventStore.append_to_stream(application, stream_uuid, 0, build_events(1))
      end

      assert_receive {:warning, [:commanded, :opentelemetry, :warning], %{count: 1},
                      %{
                        message:
                          "Failed to resolve event store adapter metadata, leaving event store destination unset",
                        application: ^application,
                        error: %FunctionClauseError{},
                        tracer_id: OTelEventStore
                      }}
    end

    setup do
      start_supervised!(DefaultApp)

      :ok
    end

    test "keeps the telemetry handler attached when event store config is nil" do
      warning_handler = attach_warning_handler()
      on_exit(fn -> :telemetry.detach(warning_handler) end)

      stream_uuid = UUID.uuid4()

      AppConfig.__put__(DefaultApp, :event_store, nil)

      assert_raise MatchError, fn ->
        EventStore.append_to_stream(DefaultApp, stream_uuid, 0, build_events(1))
      end

      assert span(
               name: "append_to_stream",
               status: {:status, :error, error_message},
               attributes: attributes,
               events: events
             ) = assert_receive_span_named("append_to_stream")

      assert error_message =~ "(MatchError)"

      assert_receive {:warning, [:commanded, :opentelemetry, :warning], %{count: 1},
                      %{
                        message:
                          "Failed to resolve event store adapter metadata, leaving event store destination unset",
                        application: DefaultApp,
                        error: %MatchError{},
                        tracer_id: OTelEventStore
                      }}

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :publish,
               "messaging.operation.name": "append_to_stream",
               "code.function": "append_to_stream",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.stream.uuid": stream_uuid,
               "commanded.expected_version": 0,
               "commanded.event.count": 1,
               "erlang.exception.kind": :error,
               "error.type": "MatchError"
             }

      assert_exception_event(events, "Elixir.MatchError")
      assert_handler_attached(:append_to_stream)
    end

    test "keeps the telemetry handler attached when adapter metadata is not a map" do
      stream_uuid = UUID.uuid4()

      AppConfig.__put__(
        DefaultApp,
        :event_store,
        {Commanded.EventStore.Adapters.InMemory, :not_a_map}
      )

      assert_raise FunctionClauseError, fn ->
        EventStore.append_to_stream(DefaultApp, stream_uuid, 0, build_events(1))
      end

      assert span(
               name: "append_to_stream",
               status: {:status, :error, error_message},
               attributes: attributes
             ) = assert_receive_span_named("append_to_stream")

      assert error_message =~ "(FunctionClauseError)"

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :publish,
               "messaging.operation.name": "append_to_stream",
               "code.function": "append_to_stream",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.stream.uuid": stream_uuid,
               "commanded.expected_version": 0,
               "commanded.event.count": 1,
               "erlang.exception.kind": :error,
               "error.type": "FunctionClauseError",
               "db.system": :in_memory
             }

      assert_handler_attached(:append_to_stream)
    end
  end

  describe "synthetic coverage for internal branches" do
    setup do
      start_supervised!(DefaultApp)

      [destination_name: expected_event_store_destination(DefaultApp)]
    end

    test "stop events set error status when metadata includes error", %{
      destination_name: destination_name
    } do
      stream_uuid = UUID.uuid4()
      span_name = expected_span_name("append_to_stream", destination_name)

      meta =
        build_event_store_append_to_stream_metadata(
          application: DefaultApp,
          stream_uuid: stream_uuid,
          expected_version: 0
        )

      :telemetry.execute([:commanded, :event_store, :append_to_stream, :start], %{}, meta)

      :telemetry.execute(
        [:commanded, :event_store, :append_to_stream, :stop],
        %{duration: 1000},
        Map.put(meta, :error, :stream_not_found)
      )

      assert span(
               name: ^span_name,
               status: {:status, :error, error_message},
               attributes: attributes
             ) = assert_receive_span_named(span_name)

      assert error_message == ":stream_not_found"

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :publish,
               "messaging.operation.name": "append_to_stream",
               "messaging.destination.name": destination_name,
               "code.function": "append_to_stream",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.stream.uuid": stream_uuid,
               "commanded.expected_version": 0,
               "commanded.event.count": 1,
               "error.type": ":stream_not_found",
               "db.system": :in_memory
             }
    end

    test "exception events keep exception type and message attributes", %{
      destination_name: destination_name
    } do
      stream_uuid = UUID.uuid4()
      span_name = expected_span_name("append_to_stream", destination_name)

      meta =
        build_event_store_append_to_stream_metadata(
          application: DefaultApp,
          stream_uuid: stream_uuid,
          expected_version: 0
        )

      :telemetry.execute([:commanded, :event_store, :append_to_stream, :start], %{}, meta)

      :telemetry.execute(
        [:commanded, :event_store, :append_to_stream, :exception],
        %{duration: 100},
        Map.merge(meta, %{
          kind: :error,
          reason: %RuntimeError{message: "failed"},
          stacktrace: []
        })
      )

      assert span(
               name: ^span_name,
               status: {:status, :error, error_message},
               attributes: attributes,
               events: events
             ) = assert_receive_span_named(span_name)

      assert error_message == "** (RuntimeError) failed"

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :publish,
               "messaging.operation.name": "append_to_stream",
               "messaging.destination.name": destination_name,
               "code.function": "append_to_stream",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.stream.uuid": stream_uuid,
               "commanded.expected_version": 0,
               "commanded.event.count": 1,
               "erlang.exception.kind": :error,
               "error.type": "RuntimeError",
               "db.system": :in_memory
             }

      assert_exception_event(events, "Elixir.RuntimeError", "failed")
    end
  end

  describe "exception spans" do
    test "unstarted applications emit exception spans without detaching the handler" do
      stream_uuid = UUID.uuid4()
      span_name = expected_span_name("append_to_stream", nil)

      assert_raise RuntimeError, fn ->
        EventStore.append_to_stream(DefaultApp, stream_uuid, 0, build_events(1))
      end

      assert span(
               name: ^span_name,
               status: {:status, :error, error_message},
               attributes: attributes,
               events: events
             ) = assert_receive_span_named(span_name)

      assert error_message =~ "could not lookup #{inspect(DefaultApp)}"

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :publish,
               "messaging.operation.name": "append_to_stream",
               "code.function": "append_to_stream",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.stream.uuid": stream_uuid,
               "commanded.expected_version": 0,
               "commanded.event.count": 1,
               "erlang.exception.kind": :error,
               "error.type": "RuntimeError"
             }

      assert_exception_event(events, "Elixir.RuntimeError")
      assert_handler_attached(:append_to_stream)
    end
  end

  defp expected_event_store_destination(application) do
    {_adapter, adapter_meta} = CommandedApplication.event_store_adapter(application)
    destination_name = Map.get(adapter_meta, :name) || Map.get(adapter_meta, :event_store)

    to_expected_destination_name(destination_name)
  end

  defp to_expected_destination_name(nil), do: nil
  defp to_expected_destination_name(name) when is_binary(name), do: name
  defp to_expected_destination_name(name) when is_atom(name), do: inspect(name)
  defp to_expected_destination_name(_), do: nil

  defp expected_span_name(action_name, nil), do: action_name
  defp expected_span_name(action_name, destination_name), do: "#{action_name} #{destination_name}"

  defp build_snapshot(source_uuid) do
    AdapterTestData.build_snapshot_data(5, source_uuid: source_uuid, metadata: %{})
  end

  defp build_events(count), do: AdapterTestData.build_opened_events(count)

  defp assert_receive_span_named(name, timeout \\ 1000) do
    deadline = System.monotonic_time(:millisecond) + timeout

    receive_span_named(name, deadline)
  end

  defp receive_span_named(name, deadline) do
    timeout = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {:span, span(name: ^name) = span_record} ->
        span_record

      {:span, _other} ->
        receive_span_named(name, deadline)
    after
      timeout ->
        flunk("Expected span #{inspect(name)}")
    end
  end

  defp assert_exception_event(events, exception_type, exception_message \\ nil) do
    events_list = :otel_events.list(events)
    exception_event = Enum.find(events_list, &(elem(&1, 2) == :exception))

    assert exception_event

    {:event, _timestamp, :exception, attrs_tuple} = exception_event
    {:attributes, _, _, _, attrs_map} = attrs_tuple

    assert attrs_map[:"exception.type"] == exception_type

    if exception_message do
      assert attrs_map[:"exception.message"] == exception_message
    end
  end

  defp assert_handler_attached(event) do
    handlers = :telemetry.list_handlers([:commanded, :event_store, event, :start])

    assert Enum.any?(handlers, &match?(%{id: {OTelEventStore, ^event}}, &1))
  end

  defp detach_handlers do
    for event <- @events,
        suffix <- [:start, :stop, :exception],
        handler <- :telemetry.list_handlers([:commanded, :event_store, event, suffix]) do
      :telemetry.detach(handler.id)
    end
  end

  defp attach_warning_handler do
    handler_id = {__MODULE__, :warning, make_ref()}

    :ok =
      :telemetry.attach(
        handler_id,
        [:commanded, :opentelemetry, :warning],
        &__MODULE__.handle_warning/4,
        self()
      )

    handler_id
  end

  def handle_warning(event, measurements, meta, pid) do
    send(pid, {:warning, event, measurements, meta})
  end
end
