alias CallumRunsWeb.Graphjson.Event

defmodule ZoneEvent do
  @derive Jason.Encoder
  @enforce_keys [:timestamp, :project, :zone, :value]
  defstruct [:timestamp, :project, :zone, :value]

  defp convert_zone_value(nil), do: 0
  defp convert_zone_value(value) do
    value * 100 |> Decimal.from_float |> Decimal.round(1) |> Decimal.to_float
  end

  def from_event(
    %Event{
      timestamp: timestamp,
      heart_rate_a: heart_rate_a,
      heart_rate_b: heart_rate_b,
      heart_rate_c: heart_rate_c,
      heart_rate_d: heart_rate_d,
      heart_rate_e: heart_rate_e
    },
    zone_project
  ), do: [
    %ZoneEvent{
      timestamp: timestamp,
      project: zone_project,
      zone: "Easy (A)",
      value: convert_zone_value(heart_rate_a)
    },
    %ZoneEvent{
      timestamp: timestamp,
      project: zone_project,
      zone: "Fat Burn (B)",
      value: convert_zone_value(heart_rate_b)
    },
    %ZoneEvent{
      timestamp: timestamp,
      project: zone_project,
      zone: "Build Fitness (C)",
      value: convert_zone_value(heart_rate_c)
    },
    %ZoneEvent{
      timestamp: timestamp,
      project: zone_project,
      zone: "Training (D)",
      value: convert_zone_value(heart_rate_d)
    },
    %ZoneEvent{
      timestamp: timestamp,
      project: zone_project,
      zone: "Extreme (E)",
      value: convert_zone_value(heart_rate_e)
    }
  ]
end
