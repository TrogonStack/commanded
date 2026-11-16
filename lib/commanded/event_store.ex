defmodule Commanded.EventStore do
  @moduledoc """
  Use the event store configured for a Commanded application.

  ### Telemetry Events

  Adds telemetry events for the following functions. Events are emitted in the form

  `[:commanded, :event_store, event]` with their spannable postfixes (`start`, `stop`, `exception`)

    * ack_event/3
    * adapter/2
    * append_to_stream/4
    * delete_snapshot/2
    * delete_subscription/3
    * read_snapshot/2
    * record_snapshot/2
    * stream_forward/2
    * stream_forward/3
    * stream_forward/4
    * subscribe/2
    * subscribe_to/5
    * subscribe_to/6
    * unsubscribe/2

  """
  alias Commanded.Application

  @type application :: Application.t()
  @type config :: Keyword.t()

  @doc """
  Append one or more events to a stream atomically.
  """
  def append_to_stream(application, stream_uuid, expected_version, events, opts \\ []) do
    meta = %{
      application: application,
      stream_uuid: stream_uuid,
      expected_version: expected_version,
      event_count: length(events)
    }

    span(:append_to_stream, meta, fn ->
      {adapter, adapter_meta} = Application.event_store_adapter(application)

      if function_exported?(adapter, :append_to_stream, 5) do
        adapter.append_to_stream(adapter_meta, stream_uuid, expected_version, events, opts)
      else
        adapter.append_to_stream(
          adapter_meta,
          stream_uuid,
          expected_version,
          events
        )
      end
    end)
  end

  @doc """
  Streams events from the given stream, in the order in which they were originally written.

  Telemetry `[:commanded, :event_store, :stream_forward, :stop]` (and matching OpenTelemetry
  spans) fire when enumeration finishes for adapters that return **lazy streams**,
  so duration reflects read-from-store work. If the adapter returns a **plain list**,
  `:stop` runs when `stream_forward` returns, as before.

  For `{:error, _}` results, `:stop` still runs immediately after the failed call.

  Adapter resolution and `stream_forward` are covered by the same span: if either raises,
  `[:commanded, :event_store, :stream_forward, :exception]` is emitted (after `:start`)
  with `kind`, `reason`, and `stacktrace` metadata, matching `:telemetry.span/3` behaviour.

  Exceptions raised during **enumeration** of a lazy stream (i.e. inside `Enum.to_list/1`
  or similar) are **not** wrapped by this telemetry — they are the caller's responsibility.
  """
  def stream_forward(application, stream_uuid, start_version \\ 0, read_batch_size \\ 1_000) do
    base_meta = %{
      application: application,
      stream_uuid: stream_uuid,
      start_version: start_version,
      read_batch_size: read_batch_size
    }

    start_monotonic = :erlang.monotonic_time()
    system_time = :erlang.system_time()
    meta = Map.put(base_meta, :telemetry_span_context, make_ref())

    :telemetry.execute(
      [:commanded, :event_store, :stream_forward, :start],
      %{monotonic_time: start_monotonic, system_time: system_time},
      meta
    )

    try do
      {adapter, adapter_meta} = Application.event_store_adapter(application)

      case adapter.stream_forward(
             adapter_meta,
             stream_uuid,
             start_version,
             read_batch_size
           ) do
        {:error, reason} = error ->
          stream_forward_stop(start_monotonic, Map.put(meta, :error, reason))
          error

        stream when is_list(stream) ->
          stream_forward_stop(start_monotonic, meta)
          stream

        stream ->
          wrap_stream_forward_telemetry(stream, meta, start_monotonic)
      end
    catch
      kind, reason ->
        stream_forward_exception(start_monotonic, meta, kind, reason, __STACKTRACE__)
        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  @doc """
  Create a transient subscription to a single event stream.

  The event store will publish any events appended to the given stream to the
  `subscriber` process as an `{:events, events}` message.

  The subscriber does not need to acknowledge receipt of the events.
  """
  def subscribe(application, stream_uuid) do
    span(:subscribe, %{application: application, stream_uuid: stream_uuid}, fn ->
      {adapter, adapter_meta} = Application.event_store_adapter(application)

      adapter.subscribe(adapter_meta, stream_uuid)
    end)
  end

  @doc """
  Create a persistent subscription to an event stream.

  To subscribe to all events appended to any stream use `:all` as the stream
  when subscribing.

  The event store will remember the subscribers last acknowledged event.
  Restarting the named subscription will resume from the next event following
  the last seen.

  Once subscribed, the subscriber process should be sent a
  `{:subscribed, subscription}` message to allow it to defer initialisation
  until the subscription has started.

  The subscriber process will be sent all events persisted to the stream. It
  will receive a `{:events, events}` message for each batch of events persisted
  for a single aggregate.

  The subscriber must ack each received, and successfully processed event, using
  `Commanded.EventStore.ack_event/3`.

  ## Examples

  Subscribe to all streams:

      {:ok, subscription} =
        Commanded.EventStore.subscribe_to(MyApp, :all, "Example", self(), :current)

  Subscribe to a single stream:

      {:ok, subscription} =
        Commanded.EventStore.subscribe_to(MyApp, "stream1", "Example", self(), :origin)

  """
  def subscribe_to(
        application,
        stream_uuid,
        subscription_name,
        subscriber,
        start_from,
        opts \\ []
      ) do
    meta = %{
      application: application,
      stream_uuid: stream_uuid,
      subscription_name: subscription_name,
      subscriber: subscriber,
      start_from: start_from
    }

    span(:subscribe_to, meta, fn ->
      {adapter, adapter_meta} = Application.event_store_adapter(application)

      if function_exported?(adapter, :subscribe_to, 6) do
        adapter.subscribe_to(
          adapter_meta,
          stream_uuid,
          subscription_name,
          subscriber,
          start_from,
          opts
        )
      else
        adapter.subscribe_to(
          adapter_meta,
          stream_uuid,
          subscription_name,
          subscriber,
          start_from
        )
      end
    end)
  end

  @doc """
  Acknowledge receipt and successful processing of the given event received from
  a subscription to an event stream.
  """
  def ack_event(application, subscription, event) do
    meta = %{application: application, subscription: subscription, event: event}

    span(:ack_event, meta, fn ->
      {adapter, adapter_meta} = Application.event_store_adapter(application)

      adapter.ack_event(adapter_meta, subscription, event)
    end)
  end

  @doc """
  Unsubscribe an existing subscriber from event notifications.

  This will not delete the subscription.

  ## Example

      :ok = Commanded.EventStore.unsubscribe(MyApp, subscription)

  """
  def unsubscribe(application, subscription) do
    span(:unsubscribe, %{application: application, subscription: subscription}, fn ->
      {adapter, adapter_meta} = Application.event_store_adapter(application)

      adapter.unsubscribe(adapter_meta, subscription)
    end)
  end

  @doc """
  Delete an existing subscription.

  ## Example

      :ok = Commanded.EventStore.delete_subscription(MyApp, :all, "Example")

  """
  def delete_subscription(application, subscribe_to, handler_name) do
    meta = %{application: application, subscribe_to: subscribe_to, handler_name: handler_name}

    span(:delete_subscription, meta, fn ->
      {adapter, adapter_meta} = Application.event_store_adapter(application)

      adapter.delete_subscription(adapter_meta, subscribe_to, handler_name)
    end)
  end

  @doc """
  Read a snapshot, if available, for a given source.
  """
  def read_snapshot(application, source_uuid) do
    {adapter, adapter_meta} = Application.event_store_adapter(application)

    span(:read_snapshot, %{application: application, source_uuid: source_uuid}, fn ->
      adapter.read_snapshot(adapter_meta, source_uuid)
    end)
  end

  @doc """
  Record a snapshot of the data and metadata for a given source
  """
  def record_snapshot(application, snapshot) do
    {adapter, adapter_meta} = Application.event_store_adapter(application)

    span(:record_snapshot, %{application: application, snapshot: snapshot}, fn ->
      adapter.record_snapshot(adapter_meta, snapshot)
    end)
  end

  @doc """
  Delete a previously recorded snapshot for a given source
  """
  def delete_snapshot(application, source_uuid) do
    {adapter, adapter_meta} = Application.event_store_adapter(application)

    span(:delete_snapshot, %{application: application, source_uuid: source_uuid}, fn ->
      adapter.delete_snapshot(adapter_meta, source_uuid)
    end)
  end

  @doc """
  Get the configured event store adapter for the given application.
  """
  @spec adapter(application, config) :: {module, config}
  def adapter(application, config)

  def adapter(application, nil) do
    raise ArgumentError, "missing :event_store config for application " <> inspect(application)
  end

  def adapter(application, config) do
    {adapter, config} = Keyword.pop(config, :adapter)

    unless Code.ensure_loaded?(adapter) do
      raise ArgumentError,
            "event store adapter " <>
              inspect(adapter) <>
              " used by application " <>
              inspect(application) <>
              " was not compiled, ensure it is correct and it is included as a project dependency"
    end

    {adapter, config}
  end

  # TODO convert to macro
  defp span(event, meta, func) do
    :telemetry.span([:commanded, :event_store, event], meta, fn ->
      case func.() do
        {:error, reason} = result -> {result, Map.put(meta, :error, reason)}
        result -> {result, meta}
      end
    end)
  end

  defp stream_forward_stop(start_monotonic, meta) do
    stop_monotonic = :erlang.monotonic_time()

    :telemetry.execute(
      [:commanded, :event_store, :stream_forward, :stop],
      %{
        duration: stop_monotonic - start_monotonic,
        monotonic_time: stop_monotonic,
        system_time: :erlang.system_time()
      },
      meta
    )
  end

  defp stream_forward_exception(start_monotonic, meta, kind, reason, stacktrace) do
    stop_monotonic = :erlang.monotonic_time()

    :telemetry.execute(
      [:commanded, :event_store, :stream_forward, :exception],
      %{
        duration: stop_monotonic - start_monotonic,
        monotonic_time: stop_monotonic,
        system_time: :erlang.system_time()
      },
      Map.merge(meta, %{kind: kind, reason: reason, stacktrace: stacktrace})
    )
  end

  # Deferred :stop only; :start was already emitted by stream_forward/4.
  defp wrap_stream_forward_telemetry(stream, meta, start_monotonic) do
    Stream.transform(
      stream,
      fn -> nil end,
      fn elem, acc -> {[elem], acc} end,
      fn _acc ->
        stream_forward_stop(start_monotonic, meta)
      end
    )
  end
end
