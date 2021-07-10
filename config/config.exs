# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :callum_runs, CallumRunsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "z+a3QmiUePj7NYJgQpIZtLz8bH9oSsbfk/5VP4vGjeAPRxEwtu9p8S2H4fOONIx6",
  render_errors: [view: CallumRunsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: CallumRuns.PubSub,
  live_view: [signing_salt: "AeeUVzIC"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
