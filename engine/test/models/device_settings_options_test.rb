# frozen_string_literal: true

require "test_helper"

class DeviceSettingsOptionsTest < ActiveSupport::TestCase
  def keys_for(template)
    DeviceSettingsOptions.call(Device.new(display_template: template)).map { |o| o[:key] }
  end

  def test_blank_template_returns_no_options
    assert_empty DeviceSettingsOptions.call(Device.new(display_template: "default"))
  end

  def test_trmnl_options
    assert_equal(
      %w[show_current_day show_temperature_events show_precip_events show_wind_events
        show_weather_alerts show_air_quality_events auto_assign_icons show_dates clothing_forecast
        truncate_event_text larger_text
        hide_current_day_enabled hide_current_day_time],
      keys_for("trmnl")
    )
    show_current_day = DeviceSettingsOptions.call(Device.new(display_template: "trmnl")).find { |o| o[:key] == "show_current_day" }
    assert show_current_day[:default_on]
  end

  def test_three_day_options
    assert_equal(
      %w[only_show_events_with_icons show_temperature_events show_precip_events show_wind_events
        show_weather_alerts show_air_quality_events clothing_forecast show_icons auto_assign_icons show_dates
        hide_current_day_enabled hide_current_day_time],
      keys_for("three_day")
    )
  end

  def test_two_day_options
    assert_equal(
      %w[only_show_events_with_icons show_precip_events show_wind_events show_weather_alerts
        show_air_quality_events clothing_forecast show_icons auto_assign_icons show_dates show_event_times
        two_day_rollover_enabled two_day_rollover_time],
      keys_for("two_day")
    )
    # two_day drops hourly conditions and defaults weather alerts off.
    refute_includes keys_for("two_day"), "show_temperature_events"
    alerts = DeviceSettingsOptions.call(Device.new(display_template: "two_day")).find { |o| o[:key] == "show_weather_alerts" }
    refute alerts[:default_on]
  end

  def test_one_day_options
    assert_equal(
      %w[only_show_events_with_icons show_weather_alerts show_air_quality_events show_icons auto_assign_icons
        show_event_times one_day_rollover_enabled one_day_rollover_time],
      keys_for("one_day")
    )
    # one_day drops the ranged weather events and clothing forecast.
    %w[show_temperature_events show_precip_events show_wind_events clothing_forecast].each do |key|
      refute_includes keys_for("one_day"), key
    end
  end

  def test_sticky_one_day_uses_one_day_options
    assert_equal keys_for("one_day"), keys_for("sticky_one_day")
  end

  def test_reterminal_options
    assert_equal(
      %w[show_current_day only_show_events_with_icons show_temperature_events show_precip_events
        show_wind_events show_weather_alerts show_air_quality_events auto_assign_icons hide_current_day_enabled hide_current_day_time],
      keys_for("reterminal")
    )
    show_current_day = DeviceSettingsOptions.call(Device.new(display_template: "reterminal")).find { |o| o[:key] == "show_current_day" }
    assert show_current_day[:default_on]
  end

  def test_reterminal_landscape_has_clothing_forecast_like_trmnl
    keys = keys_for("reterminal_landscape")
    assert_includes keys, "clothing_forecast"
    assert_includes keys, "only_show_events_with_icons"
    refute_includes keys, "show_current_day"
  end

  COMPOSITION_KEYS = %w[show_ha_status show_ha_top_left show_ha_weather_status show_ha_top_right
    show_ha_now_playing timeline_horizon room_scale_text].freeze

  def test_reterminal_landscape_ends_with_the_screen_composition_group
    options = DeviceSettingsOptions.call(Device.new(display_template: "reterminal_landscape"))
    composition = options.last(COMPOSITION_KEYS.size)

    assert_equal COMPOSITION_KEYS, composition.map { |o| o[:key] }
    assert composition.all? { |o| o[:group] == DeviceSettingsOptions::SCREEN_COMPOSITION_GROUP }
    assert options.first(options.size - COMPOSITION_KEYS.size).none? { |o| o[:group] }
  end

  def test_screen_composition_defaults_match_todays_rendering
    by_key = DeviceSettingsOptions.call(Device.new(display_template: "reterminal_landscape")).index_by { |o| o[:key] }

    assert by_key["show_ha_status"][:default_on]
    refute by_key["show_ha_status"][:depends_on]
    %w[show_ha_top_left show_ha_weather_status show_ha_top_right].each do |key|
      assert by_key[key][:default_on], "expected #{key} to default on"
      assert_equal "show_ha_status", by_key[key][:depends_on]
    end
    # The landscape layout has never shown now playing or room-scale text.
    refute by_key["show_ha_now_playing"][:default_on]
    assert_equal "show_ha_status", by_key["show_ha_now_playing"][:depends_on]
    refute by_key["room_scale_text"][:default_on]

    horizon = by_key["timeline_horizon"]
    assert_equal :select, horizon[:type]
    assert_equal Device::TIMELINE_HORIZON_DEFAULT, horizon[:default]
    assert_equal Device::TIMELINE_HORIZON_DAYS.keys, horizon[:choices].map(&:last)
    assert_equal DeviceSettingsOptions::TIMELINE_HORIZON_DESCRIPTION, horizon[:description]
  end

  def test_screen_composition_is_landscape_only
    %w[reterminal trmnl thirteen mira three_day].each do |template|
      keys = keys_for(template)
      COMPOSITION_KEYS.each { |key| refute_includes keys, key, "#{template} should not offer #{key}" }
    end
  end

  def test_thirteen_options
    assert_equal(
      %w[show_current_day show_temperature_events show_precip_events show_wind_events
        show_weather_alerts show_air_quality_events auto_assign_icons hide_current_day_enabled hide_current_day_time],
      keys_for("thirteen")
    )
  end

  def test_time_inputs_carry_defaults_and_dependencies
    hide_time = DeviceSettingsOptions.call(Device.new(display_template: "trmnl")).find { |o| o[:key] == "hide_current_day_time" }
    assert_equal :time, hide_time[:type]
    assert_equal Device::HIDE_CURRENT_DAY_DEFAULT_TIME, hide_time[:default]
    assert_equal "hide_current_day_enabled", hide_time[:depends_on]
  end

  def test_realtime_templates_include_minutely_precip_toggle
    %w[mira boox_mira].each do |template|
      keys = keys_for(template)
      assert_includes keys, "show_minutely_precip", "expected #{template} to offer show_minutely_precip"
      option = DeviceSettingsOptions.call(Device.new(display_template: template)).find { |o| o[:key] == "show_minutely_precip" }
      assert option[:default_on]
    end
  end

  def test_non_realtime_templates_omit_minutely_precip_toggle
    %w[trmnl reterminal thirteen two_day].each do |template|
      refute_includes keys_for(template), "show_minutely_precip"
    end
  end

  def test_mira_pro_includes_default_on_uv_warning
    device = Device.new(model: "boox_mira_pro", display_template: "default")
    option = DeviceSettingsOptions.call(device).find { |entry| entry[:key] == "show_uv_warning" }

    assert option
    assert option[:default_on]
  end

  def test_other_models_omit_uv_warning
    device = Device.new(model: "boox_mira", display_template: "default")

    refute_includes DeviceSettingsOptions.call(device).map { |entry| entry[:key] }, "show_uv_warning"
  end

  def test_trmnl_text_options_defaults
    options = DeviceSettingsOptions.call(Device.new(display_template: "trmnl"))
    truncate = options.find { |o| o[:key] == "truncate_event_text" }
    larger = options.find { |o| o[:key] == "larger_text" }
    assert truncate[:default_on]
    refute larger[:default_on]
  end

  def test_text_options_are_trmnl_only
    %w[reterminal thirteen two_day one_day sticky_one_day three_day mira].each do |template|
      refute_includes keys_for(template), "truncate_event_text"
      refute_includes keys_for(template), "larger_text"
    end
  end
end
