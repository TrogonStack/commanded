defmodule Commanded.OpenTelemetry.CommandedAttributes do
  @moduledoc """
  OpenTelemetry span attribute names for Commanded.

  This module provides constant attribute names following OpenTelemetry semantic
  conventions for Commanded-specific span attributes.

  ## Naming Conventions

  All attributes `MUST` follow the OpenTelemetry Semantic Conventions naming guidelines:

  - Prefix with `commanded.` to avoid conflicts with standard OTel attributes.
  - Use `snake_case` for attribute names.
  - Use `_count` suffix for counter attributes (e.g., `commanded.event.count`).
  - Use dot notation for namespacing (e.g., `commanded.stream.version`).
  - To extend a SemConv namespace, use `commanded.<namespace>.*` (e.g., `commanded.messaging.*`).

  ## Latency vs Lag

  In messaging systems (Kafka, Pulsar, NATS, RabbitMQ), **"lag"** universally refers
  to **offset-based distance** — how many messages the consumer is behind the head of
  the stream. It is a count, not a duration.

  This library follows that convention:

  - **"latency"** = a time-based duration (e.g., `commanded.handler.processing_latency`
    measures elapsed milliseconds from event creation to handler processing).
  - **"lag"** = reserved for offset-based distance (e.g., a future
    `commanded.subscription.lag` would measure how many events a subscription is
    behind the stream head).

  ## Event Handler Span Attributes

  | Attribute | Type | Description |
  |---|---|---|
  | `commanded.application` | string | The Commanded application module |
  | `commanded.handler.name` | string | The handler module name |
  | `commanded.handler.kind` | string | Type of handler (`event_handler`) |
  | `commanded.stream.id` | string | The event's stream identifier |
  | `commanded.stream.version` | integer | The event's stream version |
  | `commanded.correlation_id` | string | Correlation ID for tracing causality |
  | `commanded.causation_id` | string | Causation ID for tracing causality |
  | `commanded.handler.processing_latency` | integer | Milliseconds from event creation to handler processing (delivery latency) |

  Batch event handler spans additionally include:

  | Attribute | Type | Description |
  |---|---|---|
  | `commanded.event.count` | integer | Number of events in the batch |
  | `commanded.batch.first_event_id` | string | Event ID of the first event in the batch |
  | `commanded.batch.last_event_id` | string | Event ID of the last event in the batch |

  ## Example

      iex> Commanded.OpenTelemetry.CommandedAttributes.commanded_event()
      :"commanded.event"

  """

  @doc """
  Type of handler (command_handler, aggregate, event_handler).
  """
  @spec commanded_handler_kind() :: :"commanded.handler.kind"
  def commanded_handler_kind, do: :"commanded.handler.kind"

  @doc """
  The Commanded application module name.
  """
  @spec commanded_application() :: :"commanded.application"
  def commanded_application, do: :"commanded.application"

  @doc """
  The aggregate's unique identifier.
  """
  @spec commanded_aggregate_uuid() :: :"commanded.aggregate.uuid"
  def commanded_aggregate_uuid, do: :"commanded.aggregate.uuid"

  @doc """
  The aggregate's current version number.
  """
  @spec commanded_aggregate_version() :: :"commanded.aggregate.version"
  def commanded_aggregate_version, do: :"commanded.aggregate.version"

  @doc """
  The command struct name being dispatched.
  """
  @spec commanded_command() :: :"commanded.command"
  def commanded_command, do: :"commanded.command"

  @doc """
  The correlation ID for tracing related operations.
  """
  @spec commanded_correlation_id() :: :"commanded.correlation_id"
  def commanded_correlation_id, do: :"commanded.correlation_id"

  @doc """
  The causation ID linking cause and effect.
  """
  @spec commanded_causation_id() :: :"commanded.causation_id"
  def commanded_causation_id, do: :"commanded.causation_id"

  @doc """
  The event struct name being processed.
  """
  @spec commanded_event() :: :"commanded.event"
  def commanded_event, do: :"commanded.event"

  @doc """
  The event's global sequence number.
  """
  @spec commanded_event_number() :: :"commanded.event.number"
  def commanded_event_number, do: :"commanded.event.number"

  @doc """
  Number of events in a batch or produced by a command.
  """
  @spec commanded_event_count() :: :"commanded.event.count"
  def commanded_event_count, do: :"commanded.event.count"

  @doc """
  The event handler's registered name.
  """
  @spec commanded_handler_name() :: :"commanded.handler.name"
  def commanded_handler_name, do: :"commanded.handler.name"

  @doc """
  The stream identifier (e.g., aggregate type + uuid).
  """
  @spec commanded_stream_id() :: :"commanded.stream.id"
  def commanded_stream_id, do: :"commanded.stream.id"

  @doc """
  The stream's unique identifier.
  """
  @spec commanded_stream_uuid() :: :"commanded.stream.uuid"
  def commanded_stream_uuid, do: :"commanded.stream.uuid"

  @doc """
  The event's position within its stream.
  """
  @spec commanded_stream_version() :: :"commanded.stream.version"
  def commanded_stream_version, do: :"commanded.stream.version"

  @doc """
  Expected version for optimistic concurrency control.
  """
  @spec commanded_expected_version() :: :"commanded.expected_version"
  def commanded_expected_version, do: :"commanded.expected_version"

  @doc """
  Source UUID for projections.
  """
  @spec commanded_source_uuid() :: :"commanded.source.uuid"
  def commanded_source_uuid, do: :"commanded.source.uuid"

  @doc """
  Starting position for subscriptions (:origin, :current, or event number).
  """
  @spec commanded_start_from() :: :"commanded.start_from"
  def commanded_start_from, do: :"commanded.start_from"

  @doc """
  The subscription name for event handlers.
  """
  @spec commanded_subscription_name() :: :"commanded.subscription.name"
  def commanded_subscription_name, do: :"commanded.subscription.name"

  @doc """
  The first event ID in a batch.
  """
  @spec commanded_batch_first_event_id() :: :"commanded.batch.first_event_id"
  def commanded_batch_first_event_id, do: :"commanded.batch.first_event_id"

  @doc """
  The last event ID in a batch.
  """
  @spec commanded_batch_last_event_id() :: :"commanded.batch.last_event_id"
  def commanded_batch_last_event_id, do: :"commanded.batch.last_event_id"

  @doc """
  Whether a snapshot was used during aggregate populate.
  """
  @spec commanded_snapshot_used() :: :"commanded.snapshot.used"
  def commanded_snapshot_used, do: :"commanded.snapshot.used"

  @doc """
  The version the snapshot was taken at.
  """
  @spec commanded_snapshot_source_version() :: :"commanded.snapshot.source_version"
  def commanded_snapshot_source_version, do: :"commanded.snapshot.source_version"

  @doc """
  The configured snapshot_every value (events between snapshots).
  """
  @spec commanded_snapshot_every() :: :"commanded.snapshot.every"
  def commanded_snapshot_every, do: :"commanded.snapshot.every"

  @doc """
  The configured snapshot module version.
  """
  @spec commanded_snapshot_module_version() :: :"commanded.snapshot.module_version"
  def commanded_snapshot_module_version, do: :"commanded.snapshot.module_version"

  @doc """
  Number of wrong_expected_version conflicts during a single command execution.
  """
  @spec commanded_wrong_expected_version_count() :: :"commanded.wrong_expected_version.count"
  def commanded_wrong_expected_version_count, do: :"commanded.wrong_expected_version.count"

  @doc """
  Elapsed milliseconds from event creation to handler processing (delivery latency).

  Measures the age of the event at processing time: `now - event.created_at`. This
  reflects how long the event waited in the store before the handler picked it up,
  which is a signal of subscription health and backpressure.

  For batch handlers, reflects the oldest event in the batch (worst-case latency).

  This is distinct from `messaging.process.duration` (how long the handler took to
  execute) and from offset-based "lag" (how many events behind the stream head). See
  the module-level "Latency vs Lag" section for naming rationale.
  """
  @spec commanded_handler_processing_latency() :: :"commanded.handler.processing_latency"
  def commanded_handler_processing_latency, do: :"commanded.handler.processing_latency"

  @doc """
  The process registry adapter module (e.g. Commanded.Registration.GlobalRegistry).
  """
  @spec commanded_registry_adapter() :: :"commanded.registry.adapter"
  def commanded_registry_adapter, do: :"commanded.registry.adapter"

  @doc """
  The version number to start reading a stream from.
  """
  @spec commanded_stream_start_version() :: :"commanded.stream.start_version"
  def commanded_stream_start_version, do: :"commanded.stream.start_version"

  @doc """
  The batch size used when reading events from a stream.
  """
  @spec commanded_stream_batch_size() :: :"commanded.stream.batch_size"
  def commanded_stream_batch_size, do: :"commanded.stream.batch_size"

  @doc """
  Number of events read from a stream.
  """
  @spec eventstore_read_count() :: :"eventstore.read.count"
  def eventstore_read_count, do: :"eventstore.read.count"

  @doc """
  The version number to start reading a stream from (EventStore adapter).
  """
  @spec eventstore_stream_start_version() :: :"eventstore.stream.start_version"
  def eventstore_stream_start_version, do: :"eventstore.stream.start_version"

  @doc """
  The direction of a stream read (:forward or :backward).
  """
  @spec eventstore_stream_direction() :: :"eventstore.stream.direction"
  def eventstore_stream_direction, do: :"eventstore.stream.direction"

  @doc """
  The batch size used when reading events from a stream (EventStore adapter).
  """
  @spec eventstore_stream_batch_size() :: :"eventstore.stream.batch_size"
  def eventstore_stream_batch_size, do: :"eventstore.stream.batch_size"

  @doc """
  The type of stream deletion (soft or hard).
  """
  @spec eventstore_stream_delete_type() :: :"eventstore.stream.delete_type"
  def eventstore_stream_delete_type, do: :"eventstore.stream.delete_type"
end
