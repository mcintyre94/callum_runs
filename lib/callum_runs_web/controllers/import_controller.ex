defmodule CallumRunsWeb.ImportController do
  use CallumRunsWeb, :controller

  def import(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{})
  end
end
