# Fork Differences from Upstream

This document tracks all changes made in the `TrogonStack/commanded` fork compared to the upstream `commanded/commanded` repository.

## Overview

This fork maintains an independent release cycle to introduce new features and improvements with thorough testing before considering contributions back to the original project.

**Upstream Repository:** [github.com/commanded/commanded](https://github.com/commanded/commanded)
**Fork Repository:** [github.com/TrogonStack/commanded](https://github.com/TrogonStack/commanded)

---

## Breaking Changes ❌

### **Removed Deprecated Ecto Projections "do end" Block Syntax**

**Changes:**
- Removed deprecated `project(event, do: block)` macro variant
- Removed deprecated `project(event, metadata, do: block)` macro variant
- Only function-based syntax is now supported: `project(event, fn multi -> ... end)`

### **Removed ProcessManager Support**
[PR #24](https://github.com/TrogonStack/commanded/pull/24)

**Changes:**
- Removed all ProcessManager modules and tests
- Removed ProcessManager documentation
- Removed ProcessManager configuration
- Updated documentation to remove ProcessManager references

**Reason:** The saga pattern can be achieved using event handlers with read models and aggregates, eliminating the need for the additional ProcessManager abstraction.

### **Removed Upcasting Support**
[PR #26](https://github.com/TrogonStack/commanded/pull/26)

**Changes:**
- Removed `Commanded.Event.Upcast` and `Commanded.Event.Upcaster` modules
- Removed upcasting from event handlers and aggregates
- Removed upcasting documentation

**Reason:** Event schema transformations can be handled explicitly in event handlers and aggregates using pattern matching, eliminating the need for a global upcasting component.

### **EnrichedMetadata Struct**
[PR #11](https://github.com/TrogonStack/commanded/pull/11)

**Changes:**
- Replaced plain map metadata with `Commanded.EventStore.EnrichedMetadata` struct
- Updated event handlers to use struct

**Breaking:** Event handler callbacks now receive `%EnrichedMetadata{}` instead of a plain map.

## Features Added ✨

### **Dispatcher Failure Boundary Normalization**
[PR #98](https://github.com/TrogonStack/commanded/pull/98)

**Changes:**
- Moved aggregate execution exit normalization into `Commanded.Aggregates.Aggregate.execute/5`
- Removed the dispatcher task wrapper used only for `GenServer.call/3` failure isolation
- Made command timeouts deterministic as `{:error, :aggregate_execution_timeout}`
- Preserved abnormal aggregate exit reasons as `{:error, :aggregate_execution_failed, reason}` at the aggregate execution boundary
- Kept public dispatch failures as `{:error, :aggregate_execution_failed}` while preserving `reason` internally for middleware and logging

**Benefits:**
- Keeps failure normalization in one place instead of splitting it across aggregate and dispatcher layers
- Preserves dispatcher safety guarantees without extra runtime infrastructure
- Gives middleware and logs better diagnostic context for abnormal aggregate exits without widening the public dispatch API

### **UUIDv7 Support**
[PR #22](https://github.com/TrogonStack/commanded/pull/22)

**Changes:**
- Added UUIDv7 generation support for command and event IDs
- Modified command router to use `UUID.uuid7/0` by default

### **Configurable UUID Provider**

**Changes:**
- Integrated `Uniq.UUID` library for UUID generation
- Made UUID provider configurable
- Simplified UUID module by delegating to Uniq

### **Aggregate Telemetry for Version Conflicts**
[PR #8](https://github.com/TrogonStack/commanded/pull/8)

**Changes:**
- Added telemetry events for wrong expected version errors in aggregates
- Enhanced monitoring capabilities for version conflicts

### **Custom Event ID Support**
[PR #2](https://github.com/TrogonStack/commanded/pull/2)

**Changes:**
- Added `Commanded.Event.EventId` protocol
- Ability to set custom event IDs from event structs
- Support for deterministic event IDs

### **EventStore Adapter**
[PR #1](https://github.com/TrogonStack/commanded/pull/1)

**Changes:**
- Bundled `Commanded.EventStore.Adapters.EventStore` directly into Commanded
- Eliminates need for separate `commanded_eventstore_adapter` package dependency

### **Ecto Projections Integration**

**Changes:**
- Integrated `Commanded.Projections.Ecto` directly into Commanded
- Added Ecto and Ecto SQL as optional dependencies
- Eliminates need for separate `:commanded_ecto_projections` package dependency
- Uses nested config format: `config :commanded, Commanded.Projections.Ecto`

**Migration from commanded_ecto_projections:**
- Update dependency to `{:commanded, "~> 2.1"}` with `{:ecto, "~> 3.11"}`
- Update config from `config :commanded_ecto_projections, repo: MyApp.Repo` to `config :commanded, Commanded.Projections.Ecto, repo: MyApp.Repo`
- No code changes required - API remains the same

### **Timezone-Aware Timestamps for Projections**

**Changes:**
- `projection_versions` table now uses `timestamp with time zone` for `inserted_at` and `updated_at` columns
- ProjectionVersion schema updated to use `:utc_datetime_usec` instead of `:naive_datetime_usec`
- Added migration helper modules for both new and existing installations

**Benefits:**
- Ensures timestamp values are stored with timezone information
- Better consistency across different database configurations
- Prevents timezone-related issues when working with distributed systems

**For new installations (greenfield):**
```elixir
defmodule MyApp.Repo.Migrations.CreateProjectionVersionsTable do
  alias Commanded.Projections.Ecto.Migrations.V01CreateProjectionVersionsTable

  use Ecto.Migration

  def up do
    V01CreateProjectionVersionsTable.up()
  end

  def down do
    V01CreateProjectionVersionsTable.down()
  end
end
```

**For existing installations (upgrade):**
```elixir
defmodule MyApp.Repo.Migrations.UpgradeProjectionVersionsTimestamps do
  alias Commanded.Projections.Ecto.Migrations.V02UpgradeTimestampsToTimezone

  use Ecto.Migration

  def up do
    V02UpgradeTimestampsToTimezone.up()
  end

  def down do
    V02UpgradeTimestampsToTimezone.down()
  end
end
```

### **W3C Trace Context Propagation Middleware**
[PR #38](https://github.com/TrogonStack/commanded/pull/38)

**Changes:**
- Added `Commanded.Middleware.TraceContextPropagator` middleware for propagating OpenTelemetry trace context
- Captures current span context and stores it in event metadata using W3C Trace Context standard
- Added `opentelemetry_api` as optional dependency

**Usage:**
```elixir
defmodule MyApp.Router do
  use Commanded.Commands.Router

  middleware Commanded.Middleware.TraceContextPropagator

  # ... your command routes
end
```

**Benefits:**
- Enables distributed tracing correlation between command dispatch and event handlers
- Uses standard W3C `traceparent` and `tracestate` headers stored in event metadata
- Event handlers can extract trace context to create span links or parent-child relationships
- Non-invasive - only adds metadata when a span is active

### **W3C Baggage Propagation Middleware**
[PR #108](https://github.com/TrogonStack/commanded/pull/108)

**Changes:**
- Added `Commanded.Middleware.BaggagePropagator` middleware for propagating OpenTelemetry baggage
- Captures the current baggage and stores it in event metadata using the W3C Baggage standard
- Consumer-side helpers updated to rebuild baggage into the extracted OpenTelemetry context, including the baggage-only case (no `traceparent`)

**Usage:**
```elixir
defmodule MyApp.Router do
  use Commanded.Commands.Router

  middleware Commanded.Middleware.TraceContextPropagator
  middleware Commanded.Middleware.BaggagePropagator

  # ... your command routes
end
```

**Benefits:**
- Propagates user-defined name/value pairs (e.g. `tenant_id`, `user_id`) from command dispatch to event handlers
- Independent of trace context — W3C Baggage and W3C Trace Context are separate specifications, so each is opt-in via its own middleware
- Router-level declaration makes baggage propagation visible at the call site, since baggage entries persist in event metadata for the lifetime of the stream

### **Aggregate Identity Protocol**
[PR #43](https://github.com/TrogonStack/commanded/pull/43)

**Changes:**
- Added `Commanded.Aggregate.Identity` protocol for converting aggregate identities to stream ID strings
- Protocol uses `@fallback_to_any true` with default implementation delegating to `String.Chars`
- Updated `ExtractAggregateIdentity` middleware to use the new protocol

**Usage:**
```elixir
defmodule AccountNumber do
  defstruct [:branch, :account_number]

  defimpl Commanded.Aggregate.Identity do
    def to_stream_id(%AccountNumber{branch: branch, account_number: account_number}),
      do: branch <> ":" <> account_number
  end
end
```

**Benefits:**
- Provides a dedicated protocol for aggregate identity conversion with clear semantics
- Backwards compatible - falls back to `String.Chars` for existing implementations
- Avoids conflict with `String.Chars` which is a general-purpose protocol used for many purposes (logging, display, string interpolation, etc.) where the desired format may differ from the stream ID format

**Rationale:**

The `String.Chars` protocol is commonly implemented for various purposes unrelated to aggregate identity. For example, you might use it to format a value for API responses:

```elixir
# String.Chars for API response formatting
defimpl String.Chars, for: AccountNumber do
  def to_string(%AccountNumber{branch: branch, account_number: account_number}),
    do: "#{branch}/#{account_number}"
end

# But need a different format for stream IDs in storage
defimpl Commanded.Aggregate.Identity, for: AccountNumber do
  def to_stream_id(%AccountNumber{branch: branch, account_number: account_number}),
    do: "#{branch}:#{account_number}"
end
```

With a dedicated protocol, the API response format and the event store stream ID format are properly separated and can evolve independently.

### **OpenTelemetry Integration**
PRs: [#37](https://github.com/TrogonStack/commanded/pull/37), [#41](https://github.com/TrogonStack/commanded/pull/41), [#45](https://github.com/TrogonStack/commanded/pull/45), [#46](https://github.com/TrogonStack/commanded/pull/46), [#47](https://github.com/TrogonStack/commanded/pull/47), [#58](https://github.com/TrogonStack/commanded/pull/58), [#60](https://github.com/TrogonStack/commanded/pull/60), [#61](https://github.com/TrogonStack/commanded/pull/61), [#90](https://github.com/TrogonStack/commanded/pull/90)

**Changes:**
- Added `Commanded.OpenTelemetry` module for distributed tracing
- Creates spans for event handlers (PR #41), EventStore operations (PR #37), aggregate execution (PR #45), application dispatch (PR #46), aggregate load (PR #58), aggregate populate (PR #47), aggregate snapshots (PR #60), wrong_expected_version span event (PR #61), and aggregate load trace context propagation (PR #90)
- Added `opentelemetry_api`, `opentelemetry_telemetry`, and `opentelemetry_semantic_conventions` as required dependencies

**Usage:**
```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    Commanded.OpenTelemetry.setup()

    children = [MyApp.CommandedApp]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

**Benefits:**
- Visualize event handler execution in your tracing backend
- Correlate event processing with command dispatch using span links
- Configurable span relationships (`:link`, `:child`, `:none`)

### **Aggregate Load Telemetry**

[PR #58](https://github.com/TrogonStack/commanded/pull/58)

**Changes:**
- Added `[:commanded, :aggregate, :load]` telemetry for full event store load (stream_forward + consumption)
- Load spans fire for both new aggregates (`stream_not_found`, `count: 0`) and existing aggregates
- Populate spans remain unchanged: only fire when applying events to rebuild state
- Trace hierarchy: `commanded.aggregate.load` (parent) → `commanded.aggregate.populate` (child, when events exist)

**Benefits:**
- Measure event store read latency as a whole, including the "not found" case
- Separate load (event store I/O) from populate (state rebuild) in traces

### **OpenTelemetry Aggregate Snapshots**
[PR #60](https://github.com/TrogonStack/commanded/pull/60)

**Changes:**
- Added OTel spans for aggregate snapshot operations (`commanded.aggregate.snapshot`)
- Spans fire when taking snapshots during aggregate execution

### **OpenTelemetry wrong_expected_version Span Event**
[PR #61](https://github.com/TrogonStack/commanded/pull/61)

**Changes:**
- Track `wrong_expected_version_count` in aggregate struct and `:stop` telemetry metadata
- OTel execute span records `commanded.aggregate.wrong_expected_version` event when count > 0
- Enables alerting on optimistic concurrency conflicts via telemetry

### **Aggregate Load Trace Context Propagation**
[PR #90](https://github.com/TrogonStack/commanded/pull/90)

**Changes:**
- Propagate the dispatch caller's W3C trace context (`traceparent`/`tracestate`) through aggregate startup so that `load` and `populate` spans become children of the dispatch trace instead of orphaned root spans

### **Event Handler Processing Latency Telemetry**
[PR #66](https://github.com/TrogonStack/commanded/pull/66)

**Changes:**
- Added `processing_latency_ms` measurement to `[:commanded, :event, :handle, :stop]` and `[:commanded, :event, :batch, :stop]` telemetry events
- `processing_latency_ms` is the elapsed milliseconds between `RecordedEvent.created_at` and handler completion — how long it took the system to fully process the event from creation to done
- For batch handlers, reflects the oldest event in the batch (worst-case processing latency)

**Benefits:**
- All event handlers (projectors, sagas, notification handlers) get processing latency visibility for free
- Enables SLA dashboards and alerting without any application-level code
