# frozen_string_literal: true

require "test_helper"

class ReterminalLandscapeComponentTest < ActiveSupport::TestCase
  test "renders the timeline content for the landscape layout" do
    html = render_landscape(
      periodic: [
        {summary: "Standup", time_html: "9a", icon_class: "calendar"}
      ]
    )

    assert_includes html, "Standup"
    assert_includes html, "Monday"
  end

  test "renders the current day header" do
    html = render_landscape(configuration: {"show_current_day" => "true"})
    assert_includes html, "Monday"
  end

  test "renders at the standard size with fixed timeline columns by default" do
    html = render_landscape(now_playing: {artist: "Tycho", track: "A Walk"})

    assert_includes html, "font-size: #{Devices::ReterminalComponent::FONT_SIZE};"
    assert_includes html, "width: 30rem;"
    refute_includes html, "flex: 1 1 0%"
    # Now playing is present in the content but the layout has not opted in.
    refute_includes html, "Tycho"
  end

  test "room-scale text enlarges the root font and lets the timeline fill the width" do
    html = render_landscape(configuration: {"room_scale_text" => "true"})

    assert_includes html, "font-size: #{Devices::ReterminalComponent::ROOM_SCALE_FONT_SIZE};"
    assert_includes html, "flex: 1 1 0%; min-width: 0;"
    refute_includes html, "width: 30rem;"
  end

  test "shows now playing in the status bar when the switch is on" do
    html = render_landscape(
      configuration: {"show_ha_now_playing" => "true"},
      now_playing: {artist: "Tycho", track: "A Walk"}
    )

    assert_includes html, "mdi-music"
    assert_includes html, "Tycho · A Walk"
  end

  private

  def render_landscape(current_time: Time.zone.local(2026, 5, 25, 8, 0, 0), periodic: [], configuration: {}, now_playing: nil)
    ApplicationController.render(
      Devices::ReterminalLandscapeComponent.new(
        view_object: {
          current_time: current_time,
          current_temperature: "70°",
          configuration: configuration,
          top_left: [],
          top_right: [],
          weather_status: [],
          now_playing: now_playing,
          day_groups: [
            {
              date: Date.new(2026, 5, 25),
              day_name: "Monday",
              show_daily: false,
              daily: [],
              periodic: periodic
            }
          ],
          timestamp: "8:00 AM",
          attribution: ""
        }
      ),
      layout: false
    )
  end
end
