defmodule Commanded.OpenTelemetry.EventStore.Adapters.EventStoreTest do
  @moduledoc """
  Tests for the EventStore library OpenTelemetry instrumentation.

  Hooks into [:eventstore, operation, suffix] telemetry events emitted
  by the eventstore library itself.
  """

  use Commanded.OpenTelemetryCase, async: false

  alias Commanded.OpenTelemetry.EventStore.Adapters.EventStore, as: OTelEventstoreAdapter

  @events ~w(
    delete_stream
    delete_subscription
    link_to_stream
    paginate_streams
    read_stream_backward
    read_stream_forward
    stream_batch_read
  )a

  setup do
    detach_handlers()
    OTelEventstoreAdapter.setup()

    :ok
  end

  describe "setup/0" do
    test "attaches telemetry handlers for all eventstore operations" do
      detach_handlers()

      OTelEventstoreAdapter.setup()

      for event <- @events do
        for suffix <- [:start, :stop, :exception] do
          handlers = :telemetry.list_handlers([:eventstore, event, suffix])

          assert Enum.any?(
                   handlers,
                   &match?(%{id: {OTelEventstoreAdapter, ^event}}, &1)
                 ),
                 "Expected handler for event [:eventstore, #{event}, #{suffix}]"
        end
      end
    end

    test "calling setup twice raises MatchError (fail fast)" do
      detach_handlers()

      :ok = OTelEventstoreAdapter.setup()

      assert_raise MatchError, fn ->
        OTelEventstoreAdapter.setup()
      end
    end
  end

  describe "link_to_stream" do
    test "creates span with correct attributes" do
      meta =
        emit_start(:link_to_stream, %{
          event_store: TestEventStore,
          stream_uuid: "target-stream",
          expected_version: 0,
          event_count: 2
        })

      emit_stop(:link_to_stream, Map.put(meta, :result, :ok))

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("link_to_stream TestEventStore")

      attrs = :otel_attributes.map(attributes)
      assert attrs[:"messaging.system"] == "eventstore"
      assert attrs[:"messaging.operation.type"] == :publish
      assert attrs[:"commanded.stream.uuid"] == "target-stream"
      assert attrs[:"commanded.event.count"] == 2
    end
  end

  describe "read_stream_forward" do
    test "creates span with correct attributes" do
      meta =
        emit_start(:read_stream_forward, %{
          event_store: TestEventStore,
          stream_uuid: "stream-123",
          count: 100,
          start_version: 0
        })

      emit_stop(:read_stream_forward, Map.put(meta, :result, :ok))

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("read_stream_forward TestEventStore")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "eventstore",
               "messaging.operation.type": :receive,
               "messaging.operation.name": "read_stream_forward",
               "messaging.destination.name": "TestEventStore",
               "code.function": "read_stream_forward",
               "commanded.stream.uuid": "stream-123",
               "eventstore.read.count": 100,
               "eventstore.stream.start_version": 0,
               "db.system": :postgresql
             }
    end
  end

  describe "read_stream_backward" do
    test "creates span with correct attributes" do
      meta =
        emit_start(:read_stream_backward, %{
          event_store: TestEventStore,
          stream_uuid: "stream-123",
          count: 50,
          start_version: -1
        })

      emit_stop(:read_stream_backward, Map.put(meta, :result, :ok))

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("read_stream_backward TestEventStore")

      attrs = :otel_attributes.map(attributes)
      assert attrs[:"messaging.operation.type"] == :receive
      assert attrs[:"eventstore.read.count"] == 50
      assert attrs[:"eventstore.stream.start_version"] == -1
    end
  end

  describe "delete_stream" do
    test "creates span with correct attributes" do
      meta =
        emit_start(:delete_stream, %{
          event_store: TestEventStore,
          stream_uuid: "stream-123",
          expected_version: :stream_exists,
          delete_type: :soft
        })

      emit_stop(:delete_stream, Map.put(meta, :result, :ok))

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("delete_stream TestEventStore")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "eventstore",
               "messaging.operation.name": "delete_stream",
               "messaging.destination.name": "TestEventStore",
               "code.function": "delete_stream",
               "commanded.stream.uuid": "stream-123",
               "commanded.expected_version": :stream_exists,
               "eventstore.stream.delete_type": :soft,
               "db.system": :postgresql
             }
    end
  end

  describe "delete_subscription" do
    test "creates span with correct attributes" do
      meta =
        emit_start(:delete_subscription, %{
          event_store: TestEventStore,
          stream_uuid: "stream-123",
          subscription_name: "my-subscription"
        })

      emit_stop(:delete_subscription, Map.put(meta, :result, :ok))

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("delete_subscription TestEventStore")

      attrs = :otel_attributes.map(attributes)
      refute Map.has_key?(attrs, :"messaging.operation.type")
      assert attrs[:"commanded.subscription.name"] == "my-subscription"
    end
  end

  describe "paginate_streams" do
    test "creates span with correct attributes" do
      meta = emit_start(:paginate_streams, %{event_store: TestEventStore})
      emit_stop(:paginate_streams, Map.put(meta, :result, :ok))

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("paginate_streams TestEventStore")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "eventstore",
               "messaging.operation.name": "paginate_streams",
               "messaging.destination.name": "TestEventStore",
               "code.function": "paginate_streams",
               "db.system": :postgresql
             }
    end
  end

  describe "stream_batch_read" do
    test "creates span with direction and batch attributes" do
      meta =
        emit_start(:stream_batch_read, %{
          event_store: TestEventStore,
          stream_uuid: "stream-123",
          direction: :forward,
          requested_batch_size: 100,
          start_version: 1
        })

      emit_stop(:stream_batch_read, Map.merge(meta, %{result: :ok, event_count: 50}))

      assert span(kind: :client, attributes: attributes) =
               assert_receive_span_named("stream_batch_read TestEventStore")

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "eventstore",
               "messaging.operation.type": :receive,
               "messaging.operation.name": "stream_batch_read",
               "messaging.destination.name": "TestEventStore",
               "code.function": "stream_batch_read",
               "commanded.stream.uuid": "stream-123",
               "commanded.event.count": 50,
               "eventstore.stream.direction": :forward,
               "eventstore.stream.batch_size": 100,
               "eventstore.stream.start_version": 1,
               "db.system": :postgresql
             }
    end
  end

  describe "destination name" do
    test "uses event_store module when name is not present" do
      meta = emit_start(:link_to_stream, %{event_store: MyApp.EventStore, stream_uuid: "s1"})
      emit_stop(:link_to_stream, Map.put(meta, :result, :ok))

      assert span(attributes: attributes) =
               assert_receive_span_named("link_to_stream MyApp.EventStore")

      assert :otel_attributes.map(attributes)[:"messaging.destination.name"] ==
               "MyApp.EventStore"
    end

    test "prefers name over event_store module" do
      meta =
        emit_start(:link_to_stream, %{
          event_store: MyApp.EventStore,
          name: :my_named_store,
          stream_uuid: "s1"
        })

      emit_stop(:link_to_stream, Map.put(meta, :result, :ok))

      assert span(attributes: attributes) =
               assert_receive_span_named("link_to_stream :my_named_store")

      assert :otel_attributes.map(attributes)[:"messaging.destination.name"] == ":my_named_store"
    end

    test "omits destination when neither name nor event_store is present" do
      meta = emit_start(:link_to_stream, %{stream_uuid: "s1"})
      emit_stop(:link_to_stream, Map.put(meta, :result, :ok))

      assert span(name: "link_to_stream", attributes: attributes) =
               assert_receive_span_named("link_to_stream")

      refute Map.has_key?(:otel_attributes.map(attributes), :"messaging.destination.name")
    end
  end

  describe "exception handling" do
    test "sets error status and records exception" do
      meta =
        emit_start(:read_stream_forward, %{
          event_store: TestEventStore,
          stream_uuid: "stream-123"
        })

      emit_exception(:read_stream_forward, meta, %{
        kind: :error,
        reason: %RuntimeError{message: "connection lost"},
        stacktrace: []
      })

      assert span(
               status: {:status, :error, error_message},
               attributes: attributes,
               events: events
             ) = assert_receive_span_named("read_stream_forward TestEventStore")

      assert error_message == "** (RuntimeError) connection lost"

      attrs = :otel_attributes.map(attributes)
      assert attrs[:"erlang.exception.kind"] == :error
      assert attrs[:"error.type"] == "RuntimeError"

      assert_exception_event(events, "Elixir.RuntimeError", "connection lost")
    end
  end

  describe "stop error result" do
    test "no error status when result is :ok" do
      meta = emit_start(:link_to_stream, %{event_store: TestEventStore, stream_uuid: "s1"})
      emit_stop(:link_to_stream, Map.put(meta, :result, :ok))

      assert span(status: status, attributes: attributes) =
               assert_receive_span_named("link_to_stream TestEventStore")

      refute match?({:status, :error, _}, status)
      refute Map.has_key?(:otel_attributes.map(attributes), :"error.type")
    end

    test "sets error status when result is {:error, reason}" do
      meta = emit_start(:link_to_stream, %{event_store: TestEventStore, stream_uuid: "s1"})
      emit_stop(:link_to_stream, Map.put(meta, :result, {:error, :stream_not_found}))

      assert span(
               status: {:status, :error, ":stream_not_found"},
               attributes: attributes
             ) = assert_receive_span_named("link_to_stream TestEventStore")

      assert :otel_attributes.map(attributes)[:"error.type"] == ":stream_not_found"
    end
  end

  defp emit_start(operation, meta) do
    meta = Map.put_new(meta, :telemetry_span_context, make_ref())

    :telemetry.execute(
      [:eventstore, operation, :start],
      %{system_time: System.system_time(), monotonic_time: System.monotonic_time()},
      meta
    )

    meta
  end

  defp emit_stop(operation, meta) do
    :telemetry.execute(
      [:eventstore, operation, :stop],
      %{duration: 1000, monotonic_time: System.monotonic_time()},
      meta
    )
  end

  defp emit_exception(operation, meta, exception_fields) do
    meta = Map.merge(meta, exception_fields)

    :telemetry.execute(
      [:eventstore, operation, :exception],
      %{duration: 100, monotonic_time: System.monotonic_time()},
      meta
    )
  end

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

  defp assert_exception_event(events, exception_type, exception_message) do
    events_list = :otel_events.list(events)
    exception_event = Enum.find(events_list, &(elem(&1, 2) == :exception))

    assert exception_event

    {:event, _timestamp, :exception, attrs_tuple} = exception_event
    {:attributes, _, _, _, attrs_map} = attrs_tuple

    assert attrs_map[:"exception.type"] == exception_type
    assert attrs_map[:"exception.message"] == exception_message
  end

  defp detach_handlers do
    for event <- @events do
      for suffix <- [:start, :stop, :exception] do
        for handler <- :telemetry.list_handlers([:eventstore, event, suffix]) do
          :telemetry.detach(handler.id)
        end
      end
    end
  end
end
