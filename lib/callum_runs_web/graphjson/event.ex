defmodule CallumRunsWeb.Graphjson.Event do
  @derive Jason.Encoder
  defstruct timestamp: nil, kcal: nil, activity_type: nil, distance_km: nil, duration_mins_f: nil, elevation_ascended_m: nil,
  elevation_maximum_m: nil, elevation_minimum_m: nil, heart_rate_a: nil, heart_rate_b: nil, heart_rate_c: nil, heart_rate_d: nil,
  heart_rate_e: nil, heart_rate_avg_rounded_i: nil, heart_rate_max: nil, mets_average: nil, weather_humidity_pc: nil, weather_temp_c: nil,
  project: nil
end
