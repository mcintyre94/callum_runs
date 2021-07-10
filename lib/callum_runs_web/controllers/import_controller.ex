alias NimbleCSV.RFC4180, as: CSV
require Logger

defmodule CallumRunsWeb.ImportController do
  use CallumRunsWeb, :controller

  @doc """
  Parse a timestamp for the start date from the given date range

  Returns `{:ok, timestamp}`.

  ## Examples

      iex> CallumRunsWeb.ImportController.parse_date_range("2021-07-10 09:05:06 - 2021-07-10 10:10:43")
      {:ok, 1625907906}
  """
  def parse_date_range(date_range) do
    start_date =
      String.split(date_range, " - ")
      |> Enum.at(0)
      |> NaiveDateTime.from_iso8601!
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix

    {:ok, start_date}
  end

  @doc """
  Safely parse a number from a string, returning nil if invalid

  ## Examples

      iex> CallumRunsWeb.ImportController.parse_number("")
      nil

      iex> CallumRunsWeb.ImportController.parse_number("abc")
      nil

      iex> CallumRunsWeb.ImportController.parse_number("10")
      10.0

      iex> CallumRunsWeb.ImportController.parse_number("10.5")
      10.5
  """
  def parse_number(""), do: nil

  def parse_number(maybe_number) do
    case Float.parse(maybe_number) do
      :error ->
        Logger.error("Unable to parse as number: #{maybe_number}")
        nil
      {float, _} -> float
    end
  end

  defp log(%{} = event) do
    payload = %{
      api_key: Application.get_env(:callum_runs, CallumRunsWeb.Endpoint)[:graphjson_api_key],
      json: Jason.encode!(event),
      timestamp: event.timestamp,
    }

    # HTTPoison.post!(
    #   "https://www.graphjson.com/api/log",
    #   Jason.encode!(payload),
    #   %{"Content-Type": "application/json"}
    # )

    Logger.info("Logged event to graphjson: #{inspect(event)}")
  end

  def import(conn, %{"csv_data" => csv_data}) do
    project = Application.get_env(:callum_runs, CallumRunsWeb.Endpoint)[:graphjson_project]

    parsed = csv_data
    |> CSV.parse_string
    |> Enum.filter(fn [_date, _kcal, activity_type | _ ] -> activity_type == "Running" end)
    |> Enum.map(fn [date, kcal, activity_type, distance_km, duration_s, elevation_ascended_m, elevation_maximum_m, elevation_minimum_m, heart_rate_a, heart_rate_b, heart_rate_c, heart_rate_d, heart_rate_e, heart_rate_avg, heart_rate_max, mets_average, weather_humidity_pc, weather_temp_c] ->
      {:ok, start_date_timestamp} = parse_date_range(date)
      %{
        timestamp: start_date_timestamp,
        kcal: kcal |> parse_number,
        activity_type: activity_type,
        distance_km: distance_km |> parse_number,
        duration_mins_f: duration_s |> parse_number |> Decimal.from_float |> Decimal.div(60) |> Decimal.round(1) |> Decimal.to_float,
        elevation_ascended_m: elevation_ascended_m |> parse_number,
        elevation_maximum_m: elevation_maximum_m |> parse_number,
        elevation_minimum_m: elevation_minimum_m |> parse_number,
        heart_rate_a: heart_rate_a |> parse_number,
        heart_rate_b: heart_rate_b |> parse_number,
        heart_rate_c: heart_rate_c |> parse_number,
        heart_rate_d: heart_rate_d |> parse_number,
        heart_rate_e: heart_rate_e |> parse_number,
        heart_rate_avg_rounded_i: heart_rate_avg |> parse_number |> Decimal.from_float |> Decimal.round(0) |> Decimal.to_integer,
        heart_rate_max: heart_rate_max |> parse_number,
        mets_average: mets_average |> parse_number,
        weather_humidity_pc: weather_humidity_pc |> parse_number,
        weather_temp_c: weather_temp_c |> parse_number,
        project: project,
      }
    end)

    for event <- parsed, do: log(event)

    conn
    |> put_status(:ok)
    |> json(parsed)
  end
end
