import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"


  config :callum_runs, CallumRunsWeb.Endpoint,
    server: true,
    url: [host: "#{app_name}.fly.dev", port: 80],
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      # IMPORTANT: support IPv6 addresses
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: secret_key_base
end

graphjson_api_key = System.get_env("GRAPHJSON_API_KEY") ||
  raise """
  environment variable GRAPHJSON_API_KEY is missing.
  This can be obtained from the graphjson.com dashboard
  """

graphjson_project = System.get_env("GRAPHJSON_PROJECT") ||
  raise """
  environment variable GRAPHJSON_PROJECT is missing.
  This should be eg. callum_runs_dev
  """

private_api_key = System.get_env("PRIVATE_API_KEY") ||
  raise """
  environment variable PRIVATE_API_KEY is missing.
  You can generate one by calling: mix phx.gen.secret
  """

config :callum_runs, CallumRunsWeb.Endpoint,
  graphjson_api_key: graphjson_api_key,
  graphjson_project: graphjson_project,
  private_api_key: private_api_key
