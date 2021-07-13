alias NimbleCSV.RFC4180, as: CSV
alias CallumRunsWeb.Graphjson.Event
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

  defp log(%{} = event, graphjson_api_key) do
    payload = %{
      api_key: graphjson_api_key,
      json: Jason.encode!(event),
      timestamp: event.timestamp,
    }

    HTTPoison.post!(
      "https://www.graphjson.com/api/log",
      Jason.encode!(payload),
      %{"Content-Type": "application/json"}
    )

    Logger.info("Logged event to graphjson: #{inspect(event)}")
  end

  defp get_existing_timestamps(graphjson_api_key, project) do
    payload = %{
      api_key: graphjson_api_key,
      IANA_time_zone: "Europe/London",
      graph_type: "Samples",
      start: "1 day ago",
      end: "now",
      filters: [["project","=",project]],
    }

    result = HTTPoison.post!(
      "https://www.graphjson.com/api/visualize/data",
      Jason.encode!(payload),
      %{"Content-Type": "application/json"}
    )

    # Body is JSON with a "result" key containing {"event", "timestamp"} objects
    result.body
    |> Jason.decode!
    |> Map.get("result")
    |> Enum.map(&(&1["timestamp"]))
  end

  def import(conn, %{"csv_data" => csv_data}) do
    project = Application.get_env(:callum_runs, CallumRunsWeb.Endpoint)[:graphjson_project]
    graphjson_api_key = Application.get_env(:callum_runs, CallumRunsWeb.Endpoint)[:graphjson_api_key]

    # Get existing timestamps of events in graphjson today
    existing_timestamps = get_existing_timestamps(graphjson_api_key, project)

    parsed = csv_data
    |> CSV.parse_string
    |> Enum.filter(fn [_date, _kcal, activity_type | _ ] -> activity_type == "Running" end)
    # Note: There may be [weather_humidity_pct, weather_temp_c] columns at the end but these seem to be missing on running workouts(!)
    # They're excluded from the match because when there's only a running workout we need this to still match
    |> Enum.map(fn [date, kcal, activity_type, distance_km, duration_s, elevation_ascended_m, elevation_maximum_m, elevation_minimum_m, heart_rate_a, heart_rate_b, heart_rate_c, heart_rate_d, heart_rate_e, heart_rate_avg, heart_rate_max, mets_average | _] ->
      {:ok, start_date_timestamp} = parse_date_range(date)
      duration_mins = duration_s |> parse_number |> Decimal.from_float |> Decimal.div(60)
      distance_km = distance_km |> parse_number |> Decimal.from_float
      pace_mins_per_km = Decimal.div(duration_mins, distance_km) |> Decimal.round(2) |> Decimal.to_float

      %Event{
        project: project,
        timestamp: start_date_timestamp,
        kcal: kcal |> parse_number,
        activity_type: activity_type,
        distance_km: distance_km |> Decimal.to_float,
        duration_mins_f: duration_mins |> Decimal.round(1) |> Decimal.to_float,
        pace_mins_per_km: pace_mins_per_km,
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
        mets_average: mets_average |> parse_number
      }
    end)
    |> Enum.filter(&(&1.activity_type == "Running"))
    |> Enum.filter(&(!Enum.member?(existing_timestamps, &1.timestamp)))

    for event <- parsed, do: log(event, graphjson_api_key)

    conn
    |> put_status(:ok)
    |> text("#{Enum.count(parsed)} events logged")
  end
end
