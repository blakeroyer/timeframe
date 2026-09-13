# frozen_string_literal: true

require "test_helper"

class StatusBarComponentTest < ActiveSupport::TestCase
  test "merges indicators that share an icon and rotation into one group" do
    html = render_status_bar(
      top_left: [
        {icon: "lock", rotation: nil, label: "Front"},
        {icon: "lock", rotation: nil, label: "Back"}
      ]
    )

    assert_includes html, "Front, Back"
    assert_equal 1, html.scan("mdi-lock").size
  end

  test "keeps indicators with different rotations separate" do
    html = render_status_bar(
      top_left: [
        {icon: "lock", rotation: nil, label: "Front"},
        {icon: "lock", rotation: 90, label: "Back"}
      ]
    )

    assert_includes html, "Front"
    assert_includes html, "Back"
    refute_includes html, "Front, Back"
  end

  test "shows charge level when plugged in and fully charged" do
    html = render_status_bar(
      battery: {icon: "battery", level: 100, low: false, charging: true}
    )

    assert_includes html, "Charging 100%"
    assert_includes html, "mdi-battery"
  end

  test "leaves now playing out unless the layout opts in" do
    html = render_status_bar(top_left: [{icon: "lock", label: "Front"}], now_playing: {artist: "Tycho", track: "A Walk"})

    assert_includes html, "Front"
    refute_includes html, "Tycho"
    refute_includes html, "mdi-music"
  end

  test "renders now playing as artist and track when opted in" do
    html = render_status_bar(now_playing: {artist: "Tycho", track: "A Walk"}, render_now_playing: true)

    assert_includes html, "mdi-music"
    assert_includes html, "Tycho · A Walk"
  end

  test "renders now playing with only a track when the artist is missing" do
    html = render_status_bar(now_playing: {artist: nil, track: "Morning Show"}, render_now_playing: true)

    assert_includes html, "Morning Show"
    refute_includes html, "·"
  end

  test "renders nothing when opted in to now playing but nothing is playing" do
    assert_equal "", render_status_bar(now_playing: {}, render_now_playing: true).strip
    assert_equal "", render_status_bar(now_playing: nil, render_now_playing: true).strip
  end

  private

  def render_status_bar(top_left: [], top_right: [], weather_status: [], battery: nil, now_playing: nil, render_now_playing: false)
    ApplicationController.render(
      Devices::StatusBarComponent.new(
        view_object: {
          top_left: top_left,
          top_right: top_right,
          weather_status: weather_status,
          battery: battery,
          now_playing: now_playing
        },
        now_playing: render_now_playing
      ),
      layout: false
    )
  end
end
