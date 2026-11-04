defmodule Commanded.OpenTelemetryCase do
  @moduledoc """
  ExUnit case template for tests that need to assert on OpenTelemetry spans.

  Use `async: false` since this modifies global OpenTelemetry state.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Commanded.OpenTelemetryCase

      require Record

      for {name, spec} <- Record.extract_all(from_lib: "opentelemetry/include/otel_span.hrl") do
        Record.defrecord(name, spec)
      end

      for {name, spec} <-
            Record.extract_all(from_lib: "opentelemetry_api/include/opentelemetry.hrl") do
        Record.defrecord(name, spec)
      end
    end
  end

  setup do
    :application.stop(:opentelemetry)
    :application.set_env(:opentelemetry, :tracer, :otel_tracer_default)
    :application.set_env(:opentelemetry, :traces_exporter, :none)

    :application.set_env(:opentelemetry, :processors, [
      {:otel_batch_processor, %{scheduled_delay_ms: 1}}
    ])

    :application.start(:opentelemetry)
    :otel_batch_processor.set_exporter(:otel_exporter_pid, self())

    on_exit(fn ->
      commanded_events = [
        [:commanded, :event, :handle, :start],
        [:commanded, :event, :handle, :stop],
        [:commanded, :event, :handle, :exception],
        [:commanded, :event, :batch, :start],
        [:commanded, :event, :batch, :stop],
        [:commanded, :event, :batch, :exception],
        [:commanded, :aggregate, :execute, :start],
        [:commanded, :aggregate, :execute, :stop],
        [:commanded, :aggregate, :execute, :exception],
        [:commanded, :aggregate, :load, :start],
        [:commanded, :aggregate, :load, :stop],
        [:commanded, :aggregate, :populate, :start],
        [:commanded, :aggregate, :populate, :stop],
        [:commanded, :aggregate, :snapshot, :start],
        [:commanded, :aggregate, :snapshot, :stop],
        [:commanded, :aggregate, :snapshot, :exception],
        [:commanded, :application, :dispatch, :start],
        [:commanded, :application, :dispatch, :stop],
        [:commanded, :application, :dispatch, :exception]
      ]

      eventstore_operations =
        ~w(append_to_stream delete_snapshot delete_stream delete_subscription link_to_stream paginate_streams read_snapshot read_stream_backward read_stream_forward record_snapshot stream_batch_read subscribe_to_stream)a

      eventstore_events =
        for op <- eventstore_operations, suffix <- [:start, :stop, :exception] do
          [:eventstore, op, suffix]
        end

      for event <- commanded_events ++ eventstore_events,
          handler <- :telemetry.list_handlers(event) do
        :telemetry.detach(handler.id)
      end
    end)

    :ok
  end
end
