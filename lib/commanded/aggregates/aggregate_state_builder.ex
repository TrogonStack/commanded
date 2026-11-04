defmodule Commanded.Aggregates.AggregateStateBuilder do
  use TelemetryRegistry
  alias Commanded.Aggregates.Aggregate
  alias Commanded.EventStore
  alias Commanded.EventStore.RecordedEvent
  alias Commanded.EventStore.SnapshotData
  alias Commanded.Snapshotting
  alias Commanded.Telemetry

  telemetry_event(%{
    event: [:commanded, :aggregate, :load, :start],
    description:
      "Emitted when an aggregate begins loading from the event store (stream_forward + consumption)",
    measurements: "%{system_time: integer()}",
    metadata: """
    %{application: Commanded.Application.t(),
      aggregate_module: module(),
      aggregate_uuid: String.t(),
      aggregate_state: struct(),
      aggregate_version: non_neg_integer()}
    """
  })

  telemetry_event(%{
    event: [:commanded, :aggregate, :load, :stop],
    description: "Emitted when an aggregate completes loading from the event store",
    measurements: "%{duration: non_neg_integer(), count: non_neg_integer()}",
    metadata: """
    %{application: Commanded.Application.t(),
      aggregate_module: module(),
      aggregate_uuid: String.t(),
      aggregate_state: struct(),
      aggregate_version: non_neg_integer(),
      snapshot_used: boolean(),
      snapshot_source_version: non_neg_integer() | nil}
    """
  })

  telemetry_event(%{
    event: [:commanded, :aggregate, :populate, :start],
    description: "Emitted when an aggregate begins applying events to rebuild state",
    measurements: "%{system_time: integer()}",
    metadata: """
    %{application: Commanded.Application.t(),
      aggregate_module: module(),
      aggregate_uuid: String.t(),
      aggregate_state: struct(),
      aggregate_version: non_neg_integer()}
    """
  })

  telemetry_event(%{
    event: [:commanded, :aggregate, :populate, :stop],
    description: "Emitted when an aggregate completes applying events to rebuild state",
    measurements: "%{duration: non_neg_integer(), count: non_neg_integer()}",
    metadata: """
    %{application: Commanded.Application.t(),
      aggregate_module: module(),
      aggregate_uuid: String.t(),
      aggregate_state: struct(),
      aggregate_version: non_neg_integer()}
    """
  })

  @moduledoc """
  Builds an aggregate's state by loading its snapshot and/or events from the
  event store.

  ## Telemetry

  #{telemetry_docs()}

  """

  @read_event_batch_size 1_000

  @doc """
  Populate the aggregate's state from a snapshot, if present, and it's events.

  Attempt to fetch a snapshot for the aggregate to use as its initial state.
  If the snapshot exists, fetch any subsequent events to rebuild its state.
  Otherwise start with the aggregate struct and stream all existing events for
  the aggregate from the event store to rebuild its state from those events.
  """
  def populate(%Aggregate{} = state, metadata \\ %{}) do
    %Aggregate{aggregate_module: aggregate_module, snapshotting: snapshotting} = state

    {aggregate, snapshot_used, snapshot_source_version} =
      case Snapshotting.read_snapshot(snapshotting) do
        {:ok, %SnapshotData{source_version: source_version, data: data}} ->
          agg = %Aggregate{
            state
            | aggregate_version: source_version,
              aggregate_state: data,
              snapshotting: %{snapshotting | snapshot_version: source_version}
          }

          {agg, true, source_version}

        {:error, _error} ->
          agg = %Aggregate{
            state
            | aggregate_version: 0,
              aggregate_state: struct(aggregate_module)
          }

          {agg, false, nil}
      end

    rebuild_from_events(aggregate,
      snapshot_used: snapshot_used,
      snapshot_source_version: snapshot_source_version,
      metadata: metadata
    )
  end

  @doc """
  Load events from the event store, in batches, to rebuild the aggregate state.

  ## Options

  * `:snapshot_used` - whether a snapshot was used as initial state (default: `false`)
  * `:snapshot_source_version` - version of the snapshot, if used (default: `nil`)
  """
  def rebuild_from_events(%Aggregate{} = state, opts \\ []) do
    snapshot_used = Keyword.get(opts, :snapshot_used, false)
    snapshot_source_version = Keyword.get(opts, :snapshot_source_version)
    metadata = Keyword.get(opts, :metadata, %{})

    load_prefix = [:commanded, :aggregate, :load]
    meta = telemetry_metadata(state, metadata)
    load_start = Telemetry.start(load_prefix, meta)

    %Aggregate{
      application: application,
      aggregate_uuid: aggregate_uuid,
      aggregate_version: aggregate_version
    } = state

    result =
      case EventStore.stream_forward(
             application,
             aggregate_uuid,
             aggregate_version + 1,
             @read_event_batch_size
           ) do
        {:error, :stream_not_found} ->
          Telemetry.stop(
            load_prefix,
            load_start,
            load_stop_metadata(state, snapshot_used, snapshot_source_version),
            %{count: 0}
          )

          {state, 0}

        event_stream ->
          {state, count} = rebuild_from_event_stream(event_stream, state)

          Telemetry.stop(
            load_prefix,
            load_start,
            load_stop_metadata(state, snapshot_used, snapshot_source_version),
            %{count: count}
          )

          {state, count}
      end

    {state, _count} = result
    state
  end

  # Rebuild aggregate state from a `Stream` of its events.
  defp rebuild_from_event_stream(event_stream, %Aggregate{} = state) do
    telemetry_prefix = [:commanded, :aggregate, :populate]
    start_time = Telemetry.start(telemetry_prefix, telemetry_metadata(state))

    {state, count} =
      Enum.reduce(event_stream, {state, 0}, fn event, {state, count} ->
        %RecordedEvent{data: data, stream_version: stream_version} = event
        %Aggregate{aggregate_module: aggregate_module, aggregate_state: aggregate_state} = state

        state = %{
          state
          | aggregate_version: stream_version,
            aggregate_state: aggregate_module.apply(aggregate_state, data)
        }

        {state, count + 1}
      end)

    Telemetry.stop(telemetry_prefix, start_time, telemetry_metadata(state), %{count: count})

    {state, count}
  end

  defp load_stop_metadata(aggregate, snapshot_used, snapshot_source_version) do
    telemetry_metadata(aggregate)
    |> Map.merge(%{
      snapshot_used: snapshot_used,
      snapshot_source_version: snapshot_source_version
    })
  end

  defp telemetry_metadata(%Aggregate{} = state, metadata \\ %{}) do
    %Aggregate{
      application: application,
      aggregate_module: aggregate_module,
      aggregate_uuid: aggregate_uuid,
      aggregate_state: aggregate_state,
      aggregate_version: aggregate_version
    } = state

    %{
      application: application,
      aggregate_module: aggregate_module,
      aggregate_uuid: aggregate_uuid,
      aggregate_state: aggregate_state,
      aggregate_version: aggregate_version,
      metadata: metadata
    }
  end
end
