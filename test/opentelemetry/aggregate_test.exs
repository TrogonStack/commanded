defmodule Commanded.OpenTelemetry.AggregateTest do
  use Commanded.OpenTelemetryCase, async: false
  use Commanded.MockEventStoreCase

  alias Commanded.Aggregates.{Aggregate, ExecutionContext}
  alias Commanded.Aggregates.AggregateTelemetrySupport
  alias Commanded.DefaultApp
  alias Commanded.Middleware.Commands.IncrementCount
  alias Commanded.Middleware.Commands.RaiseError
  alias Commanded.MockedApp
  alias Commanded.OpenTelemetry.Aggregate, as: OTelAggregate
  alias Commanded.OpenTelemetry.TestRouter
  alias Commanded.TestSupport.Factory
  alias Commanded.UUID

  alias ExUnit.CaptureLog

  require OpenTelemetry.Tracer, as: Tracer

  setup do
    start_supervised!(DefaultApp)

    detach_handlers()
    detach_event_store_handlers()
    OTelAggregate.setup()

    :ok
  end

  describe "setup/1" do
    test "attaches telemetry handlers for aggregate execute events" do
      detach_handlers()

      OTelAggregate.setup()

      for event <- [
            [:commanded, :aggregate, :execute, :start],
            [:commanded, :aggregate, :execute, :stop],
            [:commanded, :aggregate, :execute, :exception]
          ] do
        handlers = :telemetry.list_handlers(event)

        assert Enum.any?(
                 handlers,
                 &match?(%{id: {OTelAggregate, :execute}}, &1)
               ),
               "Expected handler for event #{inspect(event)}"
      end
    end

    test "calling setup twice raises MatchError (fail fast)" do
      detach_handlers()

      :ok = OTelAggregate.setup()

      handlers = :telemetry.list_handlers([:commanded, :aggregate, :execute, :start])
      assert length(handlers) == 1

      assert_raise MatchError, fn ->
        OTelAggregate.setup()
      end
    end
  end

  describe "attribute completeness" do
    setup do
      detach_handlers()
      OTelAggregate.setup()
      :ok
    end

    test "includes ALL required span attributes" do
      aggregate_uuid = UUID.uuid4()
      causation_id = UUID.uuid4()
      correlation_id = UUID.uuid4()

      meta =
        Factory.build_aggregate_execute_metadata(
          aggregate_uuid: aggregate_uuid,
          aggregate_version: 5,
          causation_id: causation_id,
          correlation_id: correlation_id
        )

      :telemetry.span([:commanded, :aggregate, :execute], meta, fn ->
        {:ok, meta}
      end)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        kind: :consumer,
                        attributes: attributes
                      )},
                     1000

      attrs = :otel_attributes.map(attributes)

      assert attrs == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :process,
               "messaging.operation.name": "execute",
               "messaging.destination.name": "Commanded.TestSupport.TestDomain.Account",
               "messaging.message.id": causation_id,
               "messaging.message.conversation_id": correlation_id,
               "messaging.consumer.group.name": "MockApp",
               "code.function": "execute",
               "code.namespace": "Commanded.TestSupport.TestDomain.Account",
               "commanded.handler.kind": "aggregate",
               "commanded.application": "MockApp",
               "commanded.aggregate.uuid": aggregate_uuid,
               "commanded.aggregate.version": 5,
               "commanded.command": "Commanded.TestSupport.TestDomain.OpenAccount",
               "commanded.correlation_id": correlation_id,
               "commanded.causation_id": causation_id,
               "commanded.registry.adapter": "Commanded.Registration.LocalRegistry",
               "commanded.event.count": 0
             }
    end
  end

  describe "aggregate execute" do
    test "creates span on successful execution" do
      aggregate_uuid = UUID.uuid4()
      causation_id = UUID.uuid4()
      correlation_id = UUID.uuid4()

      command = %IncrementCount{aggregate_uuid: aggregate_uuid}

      assert :ok =
               TestRouter.dispatch(command,
                 application: DefaultApp,
                 command_uuid: causation_id,
                 correlation_id: correlation_id
               )

      assert_receive {:span,
                      span(
                        name: "execute Commanded.Middleware.Commands.CommandHandler",
                        kind: :consumer,
                        status: status,
                        attributes: attributes
                      )},
                     1000

      assert status == :undefined

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :process,
               "messaging.operation.name": "execute",
               "messaging.destination.name": "Commanded.Middleware.Commands.CommandHandler",
               "messaging.message.id": causation_id,
               "messaging.message.conversation_id": correlation_id,
               "messaging.consumer.group.name": "Commanded.DefaultApp",
               "code.function": "handle",
               "code.namespace": "Commanded.Middleware.Commands.CommandHandler",
               "commanded.handler.kind": "aggregate",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.aggregate.uuid": aggregate_uuid,
               "commanded.aggregate.version": 0,
               "commanded.command": "Commanded.Middleware.Commands.IncrementCount",
               "commanded.causation_id": causation_id,
               "commanded.correlation_id": correlation_id,
               "commanded.registry.adapter": "Commanded.Registration.LocalRegistry",
               "commanded.event.count": 1
             }
    end

    test "creates span with error status on exception" do
      command = %RaiseError{aggregate_uuid: UUID.uuid4()}

      CaptureLog.capture_log(fn ->
        assert {:error, %RuntimeError{}} = TestRouter.dispatch(command, application: DefaultApp)
      end)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.Middleware.Commands.CommandHandler",
                        kind: :consumer,
                        status: {:status, :error, _message},
                        events: events
                      )},
                     1000

      events_list = :otel_events.list(events)
      exception_event = Enum.find(events_list, fn event -> elem(event, 2) == :exception end)
      {:event, _timestamp, :exception, attrs_tuple} = exception_event
      {:attributes, _, _, _, attrs_map} = attrs_tuple

      assert attrs_map[:"exception.type"] == "Elixir.RuntimeError"
      assert attrs_map[:"exception.message"] == "failed"
    end

    test "includes event count in stop span" do
      aggregate_uuid = UUID.uuid4()
      causation_id1 = UUID.uuid4()
      correlation_id1 = UUID.uuid4()

      command1 = %IncrementCount{aggregate_uuid: aggregate_uuid, by: 1}

      assert :ok =
               TestRouter.dispatch(command1,
                 application: DefaultApp,
                 command_uuid: causation_id1,
                 correlation_id: correlation_id1
               )

      assert_receive {:span, span(attributes: attributes)}, 1000

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :process,
               "messaging.operation.name": "execute",
               "messaging.destination.name": "Commanded.Middleware.Commands.CommandHandler",
               "messaging.message.id": causation_id1,
               "messaging.message.conversation_id": correlation_id1,
               "messaging.consumer.group.name": "Commanded.DefaultApp",
               "code.function": "handle",
               "code.namespace": "Commanded.Middleware.Commands.CommandHandler",
               "commanded.handler.kind": "aggregate",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.aggregate.uuid": aggregate_uuid,
               "commanded.aggregate.version": 0,
               "commanded.command": "Commanded.Middleware.Commands.IncrementCount",
               "commanded.causation_id": causation_id1,
               "commanded.correlation_id": correlation_id1,
               "commanded.registry.adapter": "Commanded.Registration.LocalRegistry",
               "commanded.event.count": 1
             }

      causation_id2 = UUID.uuid4()
      correlation_id2 = UUID.uuid4()
      command2 = %IncrementCount{aggregate_uuid: aggregate_uuid, by: 5}

      assert :ok =
               TestRouter.dispatch(command2,
                 application: DefaultApp,
                 command_uuid: causation_id2,
                 correlation_id: correlation_id2
               )

      assert_receive {:span, span(attributes: attributes)}, 1000

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :process,
               "messaging.operation.name": "execute",
               "messaging.destination.name": "Commanded.Middleware.Commands.CommandHandler",
               "messaging.message.id": causation_id2,
               "messaging.message.conversation_id": correlation_id2,
               "messaging.consumer.group.name": "Commanded.DefaultApp",
               "code.function": "handle",
               "code.namespace": "Commanded.Middleware.Commands.CommandHandler",
               "commanded.handler.kind": "aggregate",
               "commanded.application": "Commanded.DefaultApp",
               "commanded.aggregate.uuid": aggregate_uuid,
               "commanded.aggregate.version": 1,
               "commanded.command": "Commanded.Middleware.Commands.IncrementCount",
               "commanded.causation_id": causation_id2,
               "commanded.correlation_id": correlation_id2,
               "commanded.registry.adapter": "Commanded.Registration.LocalRegistry",
               "commanded.event.count": 1
             }
    end
  end

  describe "error handling" do
    setup do
      detach_handlers()
      OTelAggregate.setup()
      :ok
    end

    test "sets error status when aggregate returns error in stop" do
      aggregate_uuid = UUID.uuid4()
      causation_id = UUID.uuid4()
      correlation_id = UUID.uuid4()

      meta =
        Factory.build_aggregate_execute_metadata(
          aggregate_uuid: aggregate_uuid,
          causation_id: causation_id,
          correlation_id: correlation_id
        )

      :telemetry.execute([:commanded, :aggregate, :execute, :start], %{}, meta)

      # Commanded emits only the reason atom, not {:error, reason} tuple
      stop_meta = Map.put(meta, :error, :validation_failed)
      :telemetry.execute([:commanded, :aggregate, :execute, :stop], %{duration: 1000}, stop_meta)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        status: {:status, :error, error_message},
                        attributes: span_attrs
                      )},
                     1000

      # Atom errors are formatted via inspect()
      assert error_message == ":validation_failed"

      assert :otel_attributes.map(span_attrs) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :process,
               "messaging.operation.name": "execute",
               "messaging.destination.name": "Commanded.TestSupport.TestDomain.Account",
               "messaging.message.id": causation_id,
               "messaging.message.conversation_id": correlation_id,
               "messaging.consumer.group.name": "MockApp",
               "code.function": "execute",
               "code.namespace": "Commanded.TestSupport.TestDomain.Account",
               "commanded.handler.kind": "aggregate",
               "commanded.application": "MockApp",
               "commanded.aggregate.uuid": aggregate_uuid,
               "commanded.aggregate.version": 0,
               "commanded.command": "Commanded.TestSupport.TestDomain.OpenAccount",
               "commanded.correlation_id": correlation_id,
               "commanded.causation_id": causation_id,
               "commanded.registry.adapter": "Commanded.Registration.LocalRegistry",
               "commanded.event.count": 0,
               "error.type": ":validation_failed"
             }
    end

    test "allows returned aggregate error status to stay unset" do
      detach_handlers()

      OTelAggregate.setup(
        error_status: fn _event_name, _measurements, _meta, _config -> :unset end
      )

      aggregate_uuid = UUID.uuid4()
      causation_id = UUID.uuid4()
      correlation_id = UUID.uuid4()

      meta =
        Factory.build_aggregate_execute_metadata(
          aggregate_uuid: aggregate_uuid,
          causation_id: causation_id,
          correlation_id: correlation_id
        )

      :telemetry.execute([:commanded, :aggregate, :execute, :start], %{}, meta)

      stop_meta = Map.put(meta, :error, :validation_failed)
      :telemetry.execute([:commanded, :aggregate, :execute, :stop], %{duration: 1000}, stop_meta)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        status: status,
                        attributes: span_attrs
                      )},
                     1000

      assert status == {:status, :unset, ""}
      assert :otel_attributes.map(span_attrs)[:"error.type"] == ":validation_failed"
    end

    test "uses the formatted aggregate error message when callback returns error" do
      detach_handlers()

      OTelAggregate.setup(
        error_status: fn _event_name, _measurements, _meta, _config -> :error end
      )

      meta = Factory.build_aggregate_execute_metadata(aggregate_uuid: UUID.uuid4())

      :telemetry.execute([:commanded, :aggregate, :execute, :start], %{}, meta)

      :telemetry.execute(
        [:commanded, :aggregate, :execute, :stop],
        %{duration: 1000},
        Map.put(meta, :error, :validation_failed)
      )

      assert_receive {:span, span(status: {:status, :error, error_message})},
                     1000

      assert error_message == ":validation_failed"
    end

    test "handles ArgumentError exception" do
      # Commanded's rescue blocks always emit kind: :error
      {_event_name, _measurements, meta} =
        Factory.build_telemetry_event(:aggregate_exception,
          reason: %ArgumentError{message: "invalid command argument"}
        )

      context = meta.execution_context

      :telemetry.execute([:commanded, :aggregate, :execute, :start], %{}, meta)
      :telemetry.execute([:commanded, :aggregate, :execute, :exception], %{duration: 100}, meta)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        status: {:status, :error, error_msg},
                        attributes: span_attrs
                      )},
                     1000

      # Exception telemetry uses Exception.format_banner()
      assert error_msg == "** (ArgumentError) invalid command argument"

      assert :otel_attributes.map(span_attrs) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :process,
               "messaging.operation.name": "execute",
               "messaging.destination.name": "Commanded.TestSupport.TestDomain.Account",
               "messaging.message.id": context.causation_id,
               "messaging.message.conversation_id": context.correlation_id,
               "messaging.consumer.group.name": inspect(meta.application),
               "code.function": to_string(context.function),
               "code.namespace": "Commanded.TestSupport.TestDomain.Account",
               "commanded.handler.kind": "aggregate",
               "commanded.application": inspect(meta.application),
               "commanded.aggregate.uuid": meta.aggregate_uuid,
               "commanded.aggregate.version": meta.aggregate_version,
               "commanded.command": "Commanded.TestSupport.TestDomain.OpenAccount",
               "commanded.correlation_id": context.correlation_id,
               "commanded.causation_id": context.causation_id,
               "commanded.registry.adapter": "Commanded.Registration.LocalRegistry",
               "erlang.exception.kind": :error,
               "error.type": "ArgumentError"
             }
    end

    test "handles RuntimeError exception" do
      # Commanded's rescue blocks always emit kind: :error
      {_event_name, _measurements, meta} =
        Factory.build_telemetry_event(:aggregate_exception,
          reason: %RuntimeError{message: "aggregate execution failed"}
        )

      context = meta.execution_context

      :telemetry.execute([:commanded, :aggregate, :execute, :start], %{}, meta)
      :telemetry.execute([:commanded, :aggregate, :execute, :exception], %{duration: 100}, meta)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        status: {:status, :error, error_msg},
                        attributes: span_attrs
                      )},
                     1000

      # Exception telemetry uses Exception.format_banner()
      assert error_msg == "** (RuntimeError) aggregate execution failed"

      assert :otel_attributes.map(span_attrs) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :process,
               "messaging.operation.name": "execute",
               "messaging.destination.name": "Commanded.TestSupport.TestDomain.Account",
               "messaging.message.id": context.causation_id,
               "messaging.message.conversation_id": context.correlation_id,
               "messaging.consumer.group.name": inspect(meta.application),
               "code.function": to_string(context.function),
               "code.namespace": "Commanded.TestSupport.TestDomain.Account",
               "commanded.handler.kind": "aggregate",
               "commanded.application": inspect(meta.application),
               "commanded.aggregate.uuid": meta.aggregate_uuid,
               "commanded.aggregate.version": meta.aggregate_version,
               "commanded.command": "Commanded.TestSupport.TestDomain.OpenAccount",
               "commanded.correlation_id": context.correlation_id,
               "commanded.causation_id": context.causation_id,
               "commanded.registry.adapter": "Commanded.Registration.LocalRegistry",
               "erlang.exception.kind": :error,
               "error.type": "RuntimeError"
             }
    end
  end

  describe "trace context propagation" do
    setup do
      detach_handlers()
      OTelAggregate.setup()
      :ok
    end

    test "propagates traceparent from command metadata" do
      {parent_trace_id, parent_span_id, traceparent} =
        Tracer.with_span "parent.command.dispatch" do
          ctx = Tracer.current_span_ctx()

          {
            :otel_span.trace_id(ctx),
            :otel_span.span_id(ctx),
            encode_traceparent(ctx)
          }
        end

      meta =
        Factory.build_aggregate_execute_metadata(metadata: %{"traceparent" => traceparent})

      :telemetry.span([:commanded, :aggregate, :execute], meta, fn ->
        {:ok, meta}
      end)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        trace_id: child_trace_id,
                        parent_span_id: received_parent_span_id
                      )},
                     1000

      assert child_trace_id == parent_trace_id
      assert received_parent_span_id == parent_span_id
    end

    test "creates independent span when no traceparent in metadata" do
      meta = Factory.build_aggregate_execute_metadata(metadata: %{})

      :telemetry.span([:commanded, :aggregate, :execute], meta, fn ->
        {:ok, meta}
      end)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        parent_span_id: :undefined
                      )},
                     1000
    end

    test "clears stale context when no traceparent" do
      # Simulate stale context left by other instrumentation in the same process
      stale_traceparent =
        Tracer.with_span "stale.context.span" do
          encode_traceparent(Tracer.current_span_ctx())
        end

      stale_headers = [{"traceparent", stale_traceparent}]
      stale_ctx = :otel_propagator_text_map.extract_to(:otel_ctx.new(), stale_headers)
      :otel_ctx.attach(stale_ctx)

      meta = Factory.build_aggregate_execute_metadata(metadata: %{})

      :telemetry.span([:commanded, :aggregate, :execute], meta, fn ->
        {:ok, meta}
      end)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        parent_span_id: parent_id
                      )},
                     1000

      # Must clear stale context, not inherit it
      assert parent_id == :undefined,
             "Expected no parent (fresh trace), but got parent_span_id: #{inspect(parent_id)}. " <>
               "Aggregate spans should clear stale context from the process dictionary."
    end

    test "creates independent span when traceparent is invalid" do
      meta =
        Factory.build_aggregate_execute_metadata(metadata: %{"traceparent" => "invalid-format"})

      :telemetry.span([:commanded, :aggregate, :execute], meta, fn ->
        {:ok, meta}
      end)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        parent_span_id: :undefined
                      )},
                     1000
    end

    test "handles traceparent with tracestate without error" do
      traceparent =
        Tracer.with_span "parent.span" do
          encode_traceparent(Tracer.current_span_ctx())
        end

      meta =
        Factory.build_aggregate_execute_metadata(
          metadata: %{
            "traceparent" => traceparent,
            "tracestate" => "vendor=value123,other=abc"
          }
        )

      :telemetry.span([:commanded, :aggregate, :execute], meta, fn ->
        {:ok, meta}
      end)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        parent_span_id: parent_id
                      )},
                     1000

      refute parent_id == :undefined
    end
  end

  describe "edge cases" do
    setup do
      detach_handlers()
      OTelAggregate.setup()
      :ok
    end

    test "handles empty metadata map" do
      meta = Factory.build_aggregate_execute_metadata(metadata: %{})

      :telemetry.span([:commanded, :aggregate, :execute], meta, fn ->
        {:ok, meta}
      end)

      assert_receive {:span, span(name: "execute Commanded.TestSupport.TestDomain.Account")}, 1000
    end

    test "handles zero events produced" do
      aggregate_uuid = UUID.uuid4()
      causation_id = UUID.uuid4()
      correlation_id = UUID.uuid4()

      meta =
        Factory.build_aggregate_execute_metadata(
          aggregate_uuid: aggregate_uuid,
          causation_id: causation_id,
          correlation_id: correlation_id
        )

      :telemetry.execute([:commanded, :aggregate, :execute, :start], %{}, meta)

      stop_meta = Map.put(meta, :events, [])
      :telemetry.execute([:commanded, :aggregate, :execute, :stop], %{duration: 100}, stop_meta)

      assert_receive {:span,
                      span(
                        name: "execute Commanded.TestSupport.TestDomain.Account",
                        attributes: attributes
                      )},
                     1000

      assert :otel_attributes.map(attributes) == %{
               "messaging.system": "commanded",
               "messaging.operation.type": :process,
               "messaging.operation.name": "execute",
               "messaging.destination.name": "Commanded.TestSupport.TestDomain.Account",
               "messaging.message.id": causation_id,
               "messaging.message.conversation_id": correlation_id,
               "messaging.consumer.group.name": "MockApp",
               "code.function": "execute",
               "code.namespace": "Commanded.TestSupport.TestDomain.Account",
               "commanded.handler.kind": "aggregate",
               "commanded.application": "MockApp",
               "commanded.aggregate.uuid": aggregate_uuid,
               "commanded.aggregate.version": 0,
               "commanded.command": "Commanded.TestSupport.TestDomain.OpenAccount",
               "commanded.correlation_id": correlation_id,
               "commanded.causation_id": causation_id,
               "commanded.registry.adapter": "Commanded.Registration.LocalRegistry",
               "commanded.event.count": 0
             }
    end
  end

  describe "wrong_expected_version span event" do
    test "span has wrong_expected_version event when conflict occurs" do
      aggregate_uuid = UUID.uuid4()

      expect_wrong_expected_version_conflict(aggregate_uuid)

      assert {:ok, _pid} = start_aggregate(aggregate_uuid, application: MockedApp)

      assert {:error, :too_many_attempts} =
               Aggregate.execute(
                 MockedApp,
                 AggregateTelemetrySupport.ExampleAggregate,
                 aggregate_uuid,
                 %ExecutionContext{
                   command:
                     struct!(Commanded.Aggregates.AggregateTelemetrySupport.Commands.Ok,
                       message: "ok"
                     ),
                   function: :execute,
                   handler: AggregateTelemetrySupport.ExampleAggregate,
                   retry_attempts: 0
                 }
               )

      assert_receive {:span,
                      span(
                        name:
                          "execute Commanded.Aggregates.AggregateTelemetrySupport.ExampleAggregate",
                        kind: :consumer,
                        events: events
                      )},
                     1000

      events_list = :otel_events.list(events)

      wrong_version_event =
        Enum.find(events_list, fn event ->
          elem(event, 2) == "commanded.aggregate.wrong_expected_version"
        end)

      assert wrong_version_event != nil,
             "Expected span to contain commanded.aggregate.wrong_expected_version event, got: #{inspect(events_list)}"

      {:event, _timestamp, "commanded.aggregate.wrong_expected_version", attrs_tuple} =
        wrong_version_event

      {:attributes, _, _, _, attrs_map} = attrs_tuple

      assert attrs_map[:"commanded.aggregate.uuid"] == aggregate_uuid
      assert attrs_map[:"commanded.aggregate.version"] == 0
      assert attrs_map[:"commanded.wrong_expected_version.count"] == 1
    end

    test "span has wrong_expected_version event with count when retry succeeds" do
      aggregate_uuid = UUID.uuid4()

      event =
        build_recorded_event(
          aggregate_uuid,
          1,
          struct!(Commanded.Aggregates.AggregateTelemetrySupport.Event, message: "event"),
          event_type: "Elixir.Commanded.Aggregates.AggregateTelemetrySupport.Event"
        )

      expect_wrong_expected_version_retry_succeeds(aggregate_uuid, event)

      assert {:ok, _pid} = start_aggregate(aggregate_uuid, application: MockedApp)

      assert {:ok, 2, _events, _aggregate_state} =
               Aggregate.execute(
                 MockedApp,
                 AggregateTelemetrySupport.ExampleAggregate,
                 aggregate_uuid,
                 %ExecutionContext{
                   command:
                     struct!(Commanded.Aggregates.AggregateTelemetrySupport.Commands.Ok,
                       message: "ok"
                     ),
                   function: :execute,
                   handler: AggregateTelemetrySupport.ExampleAggregate,
                   retry_attempts: 1
                 }
               )

      assert_receive {:span,
                      span(
                        name:
                          "execute Commanded.Aggregates.AggregateTelemetrySupport.ExampleAggregate",
                        kind: :consumer,
                        events: events
                      )},
                     1000

      events_list = :otel_events.list(events)

      wrong_version_event =
        Enum.find(events_list, fn event ->
          elem(event, 2) == "commanded.aggregate.wrong_expected_version"
        end)

      assert wrong_version_event != nil,
             "Expected span to contain commanded.aggregate.wrong_expected_version event, got: #{inspect(events_list)}"

      {:event, _timestamp, "commanded.aggregate.wrong_expected_version", attrs_tuple} =
        wrong_version_event

      {:attributes, _, _, _, attrs_map} = attrs_tuple

      assert attrs_map[:"commanded.wrong_expected_version.count"] == 1
      refute_receive {:span, _}, 200
    end

    test "no wrong_expected_version event when count is 0" do
      aggregate_uuid = UUID.uuid4()

      expect_successful_append_with_empty_stream(aggregate_uuid)

      assert {:ok, _pid} = start_aggregate(aggregate_uuid, application: MockedApp)

      assert {:ok, 1, _events, _aggregate_state} =
               Aggregate.execute(
                 MockedApp,
                 AggregateTelemetrySupport.ExampleAggregate,
                 aggregate_uuid,
                 %ExecutionContext{
                   command:
                     struct!(Commanded.Aggregates.AggregateTelemetrySupport.Commands.Ok,
                       message: "ok"
                     ),
                   function: :execute,
                   handler: AggregateTelemetrySupport.ExampleAggregate
                 }
               )

      assert_receive {:span,
                      span(
                        name:
                          "execute Commanded.Aggregates.AggregateTelemetrySupport.ExampleAggregate",
                        kind: :consumer,
                        events: events
                      )},
                     1000

      events_list = :otel_events.list(events)

      wrong_version_event =
        Enum.find(events_list, fn event ->
          elem(event, 2) == "commanded.aggregate.wrong_expected_version"
        end)

      assert wrong_version_event == nil,
             "Expected no commanded.aggregate.wrong_expected_version event when count is 0, got: #{inspect(events_list)}"
    end
  end

  defp start_aggregate(aggregate_uuid, opts) do
    aggregate = AggregateTelemetrySupport.ExampleAggregate
    app = Keyword.fetch!(opts, :application)
    name = Aggregate.name(app, aggregate, aggregate_uuid)

    Aggregate.start_link([application: app],
      aggregate_module: aggregate,
      aggregate_uuid: aggregate_uuid,
      name: Commanded.Registration.via_tuple(app, name)
    )
  end

  defp encode_traceparent(span_ctx) do
    trace_id = :otel_span.trace_id(span_ctx)
    span_id = :otel_span.span_id(span_ctx)
    trace_flags = span_ctx(span_ctx, :trace_flags)

    hex_trace_id = :io_lib.format("~32.16.0b", [trace_id]) |> IO.iodata_to_binary()
    hex_span_id = :io_lib.format("~16.16.0b", [span_id]) |> IO.iodata_to_binary()
    hex_flags = :io_lib.format("~2.16.0b", [trace_flags]) |> IO.iodata_to_binary()

    "00-#{hex_trace_id}-#{hex_span_id}-#{hex_flags}"
  end

  defp detach_handlers do
    for event <- [
          [:commanded, :aggregate, :execute, :start],
          [:commanded, :aggregate, :execute, :stop],
          [:commanded, :aggregate, :execute, :exception]
        ] do
      for handler <- :telemetry.list_handlers(event) do
        :telemetry.detach(handler.id)
      end
    end
  end

  defp detach_event_store_handlers do
    event_store_events = ~w(
      append_to_stream
      delete_snapshot
      read_snapshot
      record_snapshot
      stream_forward
    )a

    for event <- event_store_events,
        suffix <- [:start, :stop, :exception],
        handler <- :telemetry.list_handlers([:commanded, :event_store, event, suffix]) do
      :telemetry.detach(handler.id)
    end
  end
end
