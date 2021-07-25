alias CallumRunsWeb.Graphjson.Event

defmodule CallumRunsWeb.Graphjson.ZoneEventTest do
  use ExUnit.Case

  test "convert an event to expected zone events" do
    event = %Event{
      timestamp: 123456789,
      heart_rate_a: 0.123,
      heart_rate_b: 0.234,
      heart_rate_c: 0.345,
      heart_rate_d: 0.456,
      heart_rate_e: 0.567
    }

    zone_project = "zone_project"

    expected = [
      %ZoneEvent{
        timestamp: 123456789,
        project: zone_project,
        zone: "Easy (A)",
        value: 12.3
      },
      %ZoneEvent{
        timestamp: 123456789,
        project: zone_project,
        zone: "Fat Burn (B)",
        value: 23.4
      },
      %ZoneEvent{
        timestamp: 123456789,
        project: zone_project,
        zone: "Build Fitness (C)",
        value: 34.5
      },
      %ZoneEvent{
        timestamp: 123456789,
        project: zone_project,
        zone: "Training (D)",
        value: 45.6
      },
      %ZoneEvent{
        timestamp: 123456789,
        project: zone_project,
        zone: "Extreme (E)",
        value: 56.7
      }
    ]

    assert ZoneEvent.from_event(event, zone_project) == expected
  end
end
