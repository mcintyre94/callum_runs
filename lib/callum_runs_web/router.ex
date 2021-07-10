defmodule CallumRunsWeb.Router do
  use CallumRunsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  @spec verify_api_key(Plug.Conn.t(), any) :: Plug.Conn.t()
  def verify_api_key(conn, _opts) do
    api_key = Application.get_env(:callum_runs, CallumRunsWeb.Endpoint)[:private_api_key]
    request_api_key = Plug.Conn.get_req_header(conn, "api-key")
    if request_api_key == [api_key] do
      conn
    else
      conn |> put_status(:unauthorized) |> text("Missing or incorrect api-key")
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :verify_api_key
  end

  scope "/", CallumRunsWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", CallumRunsWeb do
    pipe_through :api

    post "/import", ImportController, :import
  end

  # Other scopes may use custom stacks.
  # scope "/api", CallumRunsWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CallumRunsWeb.Telemetry
    end
  end
end
