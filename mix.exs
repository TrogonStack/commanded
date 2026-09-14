defmodule Commanded.Mixfile do
  use Mix.Project

  @version "3.7.1"
  @source_url "https://github.com/TrogonStack/commanded"

  def project do
    [
      name: "Commanded",
      app: :commanded,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      aliases: aliases(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() == :prod,
      dialyzer: dialyzer(),
      source_url: @source_url
    ]
  end

  def cli do
    [
      preferred_envs: [
        setup: :test,
        reset: :test,
        "test.all": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: extra_applications(Mix.env()),
      mod: {Commanded, []}
    ]
  end

  defp extra_applications(:test), do: [:crypto, :logger, :phoenix_pubsub]
  defp extra_applications(_env), do: [:crypto, :logger]

  defp elixirc_paths(env) when env in [:bench, :test],
    do: [
      "lib",
      "test/aggregates/support",
      "test/application/support",
      "test/commands/support",
      "test/event/support",
      "test/event_store/support",
      "test/example_domain",
      "test/middleware/support",
      "test/helpers",
      "test/opentelemetry/support",
      "test/projections/support",
      "test/pubsub/support",
      "test/registration/support",
      "test/subscriptions/support",
      "test/support"
    ]

  defp elixirc_paths(_env), do: ["lib", "test/helpers"]

  defp deps do
    [
      {:backoff, "~> 1.1"},
      {:uniq, "~> 0.6.1"},
      {:nimble_options, "~> 1.0"},

      # Telemetry
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:telemetry_registry, "~> 0.2 or ~> 0.3"},

      # OpenTelemetry (required for distributed tracing)
      {:opentelemetry_api, "~> 1.0"},
      {:opentelemetry_telemetry, "~> 1.0"},
      {:opentelemetry_semantic_conventions, "~> 1.27"},

      # Optional dependencies
      {:jason, "~> 1.4", optional: true},
      {:phoenix_pubsub, "~> 2.1", optional: true},
      {:eventstore, "~> 1.4", optional: true},
      {:ecto, "~> 3.11", optional: true},
      {:ecto_sql, "~> 3.11", optional: true},

      # Build and test tools
      {:benchfella, "~> 0.3", only: :bench},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:local_cluster, "~> 2.1", only: :test, runtime: false},
      {:mix_test_watch, "~> 1.1", only: :dev},
      {:mox, "~> 1.0", only: [:bench, :test]},
      {:opentelemetry, "~> 1.0", only: :test},
      {:opentelemetry_exporter, "~> 1.0", only: :test}
    ]
  end

  defp description do
    """
    Use Commanded to build your own Elixir applications following the CQRS/ES pattern.
    """
  end

  defp docs do
    [
      main: "readme",
      canonical: "http://hexdocs.pm/commanded",
      source_ref: "v#{@version}",
      extra_section: "GUIDES",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras:
        [
          "README.md",
          "CHANGELOG.md",
          LICENSE: [title: "License"]
        ] ++ Path.wildcard("guides/**/*.{cheatmd,md}"),
      groups_for_extras: [
        Explanations: ~r"/explanations/",
        Cheatsheets: ~r"/cheatsheets/",
        "How-To's": ~r"/howtos/"
      ],
      groups_for_modules: [
        Aggregates: [
          Commanded.Aggregate.Multi,
          Commanded.Aggregates.Aggregate,
          Commanded.Aggregates.AggregateStateBuilder,
          Commanded.Aggregates.AggregateLifespan,
          Commanded.Aggregates.DefaultLifespan,
          Commanded.Aggregates.ExecutionContext,
          Commanded.Aggregates.Supervisor
        ],
        Commands: [
          Commanded.Commands.CompositeRouter,
          Commanded.Commands.ExecutionResult,
          Commanded.Commands.Handler,
          Commanded.Commands.Router
        ],
        Events: [
          Commanded.Event.FailureContext,
          Commanded.Event.Handler,
          Commanded.Event.Mapper,
          Commanded.Event.EventId
        ],
        "Event Store": [
          Commanded.EventStore,
          Commanded.EventStore.Adapter,
          Commanded.EventStore.Adapters.InMemory,
          Commanded.EventStore.EventData,
          Commanded.EventStore.RecordedEvent,
          Commanded.EventStore.SnapshotData,
          Commanded.EventStore.TypeProvider
        ],
        "Pub Sub": [
          Commanded.PubSub,
          Commanded.PubSub.Adapter,
          Commanded.PubSub.LocalPubSub,
          Commanded.PubSub.PhoenixPubSub
        ],
        Registry: [
          Commanded.Registration,
          Commanded.Registration.Adapter,
          Commanded.Registration.LocalRegistry,
          Commanded.Registration.GlobalRegistry
        ],
        Serialization: [
          Commanded.Serialization.JsonDecoder,
          Commanded.Serialization.JsonSerializer,
          Commanded.Serialization.ModuleNameTypeProvider
        ],
        Tasks: [
          Mix.Tasks.Commanded.Reset
        ],
        Middleware: [
          Commanded.Middleware,
          Commanded.Middleware.ConsistencyGuarantee,
          Commanded.Middleware.ExtractAggregateIdentity,
          Commanded.Middleware.Logger,
          Commanded.Middleware.Pipeline
        ],
        Projections: [
          Commanded.Projections.Ecto
        ],
        Testing: [
          Commanded.AggregateCase,
          Commanded.Assertions.EventAssertions
        ],
        OpenTelemetry: [
          Commanded.OpenTelemetry,
          Commanded.OpenTelemetry.CommandedAttributes,
          Commanded.Middleware.TraceContextPropagator
        ]
      ],
      nest_modules_by_prefix: [
        Commanded.Aggregate,
        Commanded.Aggregates,
        Commanded.Commands,
        Commanded.Event,
        Commanded.EventStore,
        Commanded.OpenTelemetry,
        Commanded.PubSub,
        Commanded.Projections,
        Commanded.Registration,
        Commanded.Serialization,
        Commanded.Middleware
      ]
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        ".formatter.exs",
        "README*",
        "LICENSE*",
        "CHANGELOG*",
        "test/event_store/support",
        "test/example_domain",
        "test/helpers",
        "test/registration/support",
        "test/support"
      ],
      maintainers: ["Yordis Prieto"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://github.com/TrogonStack/commanded/blob/main/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  defp aliases do
    [
      reset: ["event_store.drop", "ecto.drop", "setup"],
      setup: [
        "event_store.create",
        "event_store.init",
        "ecto.create",
        "ecto.migrate"
      ],
      "test.all": ["test --include distributed --include eventstore_adapter"]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_add_apps: [
        :ex_unit,
        :jason,
        :mix,
        :phoenix_pubsub,
        :ecto,
        :ecto_sql,
        :opentelemetry_api,
        :opentelemetry_telemetry
      ],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/commanded.plt"}
    ]
  end
end
