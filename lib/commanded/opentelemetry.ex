defmodule Commanded.OpenTelemetry do
  @moduledoc """
  OpenTelemetry integration for Commanded.

  Provides automatic distributed tracing of Commanded operations using OpenTelemetry.

  ## Usage

  Call `setup/0` in your application's `start/2` callback:

      defmodule MyApp.Application do
        use Application

        def start(_type, _args) do
          Commanded.OpenTelemetry.setup()

          children = [MyApp.CommandedApp]
          Supervisor.start_link(children, strategy: :one_for_one)
        end
      end

  ## Trace Context Propagation

  Add the middleware to your command router to propagate trace context to event handlers:

      defmodule MyApp.Router do
        use Commanded.Commands.Router

        middleware Commanded.Middleware.TraceContextPropagator

        # ... your command routes
      end

  ## Types

  See `t:span_relationship/0` for available span relationship modes.
  """

  alias Commanded.OpenTelemetry.Aggregate
  alias Commanded.OpenTelemetry.AggregatePopulate
  alias Commanded.OpenTelemetry.AggregateSnapshot
  alias Commanded.OpenTelemetry.Application, as: OTelApplication
  alias Commanded.OpenTelemetry.EventHandler
  alias Commanded.OpenTelemetry.EventStore

  @typedoc """
  Determines how event handler spans relate to command dispatch spans.

  * `:link` - Create span links to the original command dispatch (default).
    Best for event-driven architectures where events are processed independently.
  * `:child` - Attach event handler spans as children of the command span.
    Best when you want a single trace tree for the entire command lifecycle.
  * `:none` - No span propagation between commands and event handlers.
    Best when events should start fresh traces.
  """
  @type span_relationship :: :link | :child | :none

  @typedoc """
  Callback used to decide the OpenTelemetry span status for returned `:stop` errors.

  The callback is only invoked when Commanded emits stop metadata containing `:error`.
  Exception telemetry continues to use OpenTelemetry exception semantics directly.
  """
  @type error_status_callback ::
          (event_name :: [atom()],
           measurements :: map(),
           metadata :: map(),
           config :: keyword() ->
             OpenTelemetry.status_code() | nil)

  @error_status_options [
    error_status: [
      type: {:fun, 4},
      type_doc: "`t:error_status_callback/0`",
      doc:
        "Override the span status for returned `:stop` errors. Return `nil` to leave the status unset."
    ]
  ]

  @nimble_schema NimbleOptions.new!(
                   aggregate: [
                     type:
                       {:or,
                        [
                          {:in, [:disabled]},
                          keyword_list: @error_status_options
                        ]},
                     default: [],
                     doc: "Aggregate tracing configuration. Use `:disabled` to disable."
                   ],
                   aggregate_populate: [
                     type: {:in, [:disabled, []]},
                     default: [],
                     doc: "Aggregate populate tracing configuration. Use `:disabled` to disable."
                   ],
                   aggregate_snapshot: [
                     type: {:in, [:disabled, []]},
                     default: [],
                     doc: "Aggregate snapshot tracing configuration. Use `:disabled` to disable."
                   ],
                   application: [
                     type:
                       {:or,
                        [
                          {:in, [:disabled]},
                          keyword_list: @error_status_options
                        ]},
                     default: [],
                     doc:
                       "Application dispatch tracing configuration. Use `:disabled` to disable."
                   ],
                   event_handler: [
                     type:
                       {:or,
                        [
                          {:in, [:disabled]},
                          keyword_list: [
                            span_relationship: [
                              type: {:in, [:link, :child, :none]},
                              type_doc: "`t:span_relationship/0`",
                              default: :link
                            ]
                          ]
                        ]},
                     default: [],
                     doc: "Event handler tracing configuration. Use `:disabled` to disable."
                   ],
                   event_store: [
                     type:
                       {:or,
                        [
                          {:in, [:disabled]},
                          keyword_list: [
                            adapter: [
                              type: {:in, [:enabled, :disabled]},
                              default: :disabled,
                              doc:
                                "Hook into the telemetry events emitted by the event store adapter. Use `:enabled` to enable."
                            ]
                          ]
                        ]},
                     default: [],
                     doc: "Event store tracing configuration. Use `:disabled` to disable."
                   ]
                 )

  @doc """
  Set up OpenTelemetry tracing for Commanded.

  Attaches telemetry handlers to Commanded events and creates OpenTelemetry spans.

  ## Options

  #{NimbleOptions.docs(@nimble_schema)}

  ## Examples

      # Default setup (enables all tracing)
      Commanded.OpenTelemetry.setup()

      # Disable aggregate tracing
      Commanded.OpenTelemetry.setup(aggregate: :disabled)

      # Disable application dispatch tracing
      Commanded.OpenTelemetry.setup(application: :disabled)

      # Disable event handler tracing
      Commanded.OpenTelemetry.setup(event_handler: :disabled)

      # Leave returned domain errors unset for dispatch spans
      Commanded.OpenTelemetry.setup(
        application: [
          error_status: fn
            _event_name, _measurements, %{error: :validation_failed}, _config -> :unset
            _event_name, _measurements, _meta, _config -> :error
          end
        ]
      )

      # Disable aggregate populate tracing
      Commanded.OpenTelemetry.setup(aggregate_populate: :disabled)

      # Disable aggregate snapshot tracing
      Commanded.OpenTelemetry.setup(aggregate_snapshot: :disabled)

      # Disable event store tracing
      Commanded.OpenTelemetry.setup(event_store: :disabled)

      # Enable event store adapter tracing (hooks into adapter-level telemetry)
      Commanded.OpenTelemetry.setup(event_store: [adapter: :enabled])

      # Use parent-child relationships for event handlers
      Commanded.OpenTelemetry.setup(event_handler: [span_relationship: :child])

  """
  @spec setup(keyword()) :: :ok
  def setup(opts \\ []) do
    opts = NimbleOptions.validate!(opts, @nimble_schema)

    case opts[:aggregate] do
      :disabled -> :ok
      config -> Aggregate.setup(config)
    end

    case opts[:aggregate_populate] do
      :disabled -> :ok
      _config -> AggregatePopulate.setup()
    end

    case opts[:aggregate_snapshot] do
      :disabled -> :ok
      _config -> AggregateSnapshot.setup()
    end

    case opts[:application] do
      :disabled -> :ok
      config -> OTelApplication.setup(config)
    end

    case opts[:event_handler] do
      :disabled -> :ok
      config -> EventHandler.setup(config)
    end

    case opts[:event_store] do
      :disabled -> :ok
      config -> EventStore.setup(config)
    end

    :ok
  end
end
