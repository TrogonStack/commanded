defmodule Commanded.OpenTelemetry.EventStore.Adapters.EventStore do
  @moduledoc false

  alias Commanded.OpenTelemetry.CommandedAttributes
  alias Commanded.OpenTelemetry.Helpers
  alias OpenTelemetry.SemConv.ErrorAttributes
  alias OpenTelemetry.SemConv.Incubating.CodeAttributes
  alias OpenTelemetry.SemConv.Incubating.DBAttributes
  alias OpenTelemetry.SemConv.Incubating.MessagingAttributes
  alias OpenTelemetry.Span


  @tracer_id __MODULE__

  @events ~w(
    delete_stream
    delete_subscription
    link_to_stream
    paginate_streams
    read_stream_backward
    read_stream_forward
    stream_batch_read
  )a

  def setup do
    for event <- @events do
      :ok =
        :telemetry.attach_many(
          {__MODULE__, event},
          [
            [:eventstore, event, :start],
            [:eventstore, event, :stop],
            [:eventstore, event, :exception]
          ],
          &__MODULE__.handle_telemetry_event/4,
          %{}
        )
    end

    :ok
  end

  def handle_telemetry_event(
        [:eventstore, action, :start],
        _measurements,
        meta,
        _config
      ) do
    operation_type = operation_type_for(action)
    action_name = to_string(action)
    destination_name = event_store_destination_name(meta)

    conn_config = resolve_connection_config(meta)

    attributes =
      [
        {MessagingAttributes.messaging_system(), "eventstore"},
        {MessagingAttributes.messaging_operation_name(), action_name},
        {CodeAttributes.code_function(), action_name},
        {DBAttributes.db_system(), :postgresql}
      ]
      |> Helpers.maybe_add_connection_attributes(conn_config)
      |> Helpers.maybe_add_operation_type(operation_type)
      |> Helpers.maybe_add_destination_name(destination_name)
      |> Helpers.maybe_add_stream_uuid(meta[:stream_uuid])
      |> Helpers.maybe_add_expected_version(meta[:expected_version])
      |> Helpers.maybe_add_event_count(meta[:event_count])
      |> Helpers.maybe_add_subscription_name(meta[:subscription_name])
      |> Helpers.maybe_add_source_uuid(meta[:source_uuid])
      |> maybe_add_count(meta[:count])
      |> maybe_add_start_version(meta[:start_version])
      |> maybe_add_direction(meta[:direction])
      |> maybe_add_batch_size(meta[:requested_batch_size])
      |> maybe_add_delete_type(meta[:delete_type])

    span_name =
      case destination_name do
        nil -> action_name
        name -> "#{action_name} #{name}"
      end

    OpentelemetryTelemetry.start_telemetry_span(
      @tracer_id,
      span_name,
      meta,
      %{
        kind: :client,
        attributes: attributes
      }
    )
  end

  def handle_telemetry_event(
        [:eventstore, _action, :stop],
        _measurements,
        meta,
        _config
      ) do
    ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)

    maybe_set_stop_event_count(ctx, meta)

    case meta[:result] do
      {:error, reason} ->
        Span.set_attribute(
          ctx,
          ErrorAttributes.error_type(),
          Helpers.to_error_type(reason, @tracer_id)
        )

        Span.set_status(ctx, OpenTelemetry.status(:error, Helpers.format_error(reason)))

      _ ->
        :ok
    end

    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  def handle_telemetry_event(
        [:eventstore, _action, :exception],
        _measurements,
        %{kind: kind, reason: reason, stacktrace: stacktrace} = meta,
        _config
      ) do
    ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)

    Span.set_attribute(ctx, :"erlang.exception.kind", kind)

    exception = Exception.normalize(kind, reason, stacktrace)

    Span.set_attribute(
      ctx,
      ErrorAttributes.error_type(),
      Helpers.to_error_type(exception, @tracer_id)
    )

    Span.record_exception(ctx, exception, stacktrace)

    Span.set_status(
      ctx,
      OpenTelemetry.status(:error, Exception.format_banner(kind, reason, stacktrace))
    )

    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  defp operation_type_for(:link_to_stream), do: :publish
  defp operation_type_for(:read_stream_forward), do: :receive
  defp operation_type_for(:read_stream_backward), do: :receive
  defp operation_type_for(:stream_batch_read), do: :receive
  defp operation_type_for(:delete_stream), do: nil
  defp operation_type_for(:delete_subscription), do: nil
  defp operation_type_for(:paginate_streams), do: nil
  defp operation_type_for(_), do: nil

  defp event_store_destination_name(meta) do
    name = meta[:name] || meta[:event_store]
    Helpers.to_destination_name(name)
  end

  defp resolve_connection_config(meta) do
    name = meta[:name] || meta[:event_store]

    EventStore.Config.lookup(name)
  rescue
    _ -> []
  end

  defp maybe_add_count(attrs, nil), do: attrs

  defp maybe_add_count(attrs, count),
    do: [{CommandedAttributes.eventstore_read_count(), count} | attrs]

  defp maybe_add_start_version(attrs, nil), do: attrs

  defp maybe_add_start_version(attrs, version),
    do: [{CommandedAttributes.eventstore_stream_start_version(), version} | attrs]

  defp maybe_add_direction(attrs, nil), do: attrs

  defp maybe_add_direction(attrs, direction),
    do: [{CommandedAttributes.eventstore_stream_direction(), direction} | attrs]

  defp maybe_add_batch_size(attrs, nil), do: attrs

  defp maybe_add_batch_size(attrs, size),
    do: [{CommandedAttributes.eventstore_stream_batch_size(), size} | attrs]

  defp maybe_add_delete_type(attrs, nil), do: attrs

  defp maybe_add_delete_type(attrs, type),
    do: [{CommandedAttributes.eventstore_stream_delete_type(), type} | attrs]

  # stream_batch_read includes event_count only in stop metadata
  defp maybe_set_stop_event_count(ctx, %{event_count: count}) when is_integer(count) do
    Span.set_attribute(ctx, CommandedAttributes.commanded_event_count(), count)
  end

  defp maybe_set_stop_event_count(_ctx, _meta), do: :ok
end
