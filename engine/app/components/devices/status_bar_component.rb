# frozen_string_literal: true

class Devices::StatusBarComponent < ViewComponent::Base
  # now_playing: whether to render the now-playing feed in the bar. Opt-in per
  # layout (see Device#now_playing_enabled?); the composition templates pass
  # true when their "Now playing" switch is on.
  def initialize(view_object:, now_playing: false)
    @view_object = view_object
    @now_playing = now_playing
  end

  def render?
    @view_object[:top_left].any? || @view_object[:top_right].any? || @view_object[:weather_status].any? ||
      @view_object[:battery].present? || now_playing_text.present?
  end

  # Merges items sharing the same icon (and rotation) into one group, joining
  # their labels with ", " while preserving first-seen order. Exposed as a class
  # method so templates that render the status indicators outside this component
  # (e.g. the Mira layout) get the same grouping behavior.
  def self.consolidate(items)
    items.each_with_object([]) do |item, groups|
      group = groups.find { |g| g[:icon] == item[:icon] && g[:rotation] == item[:rotation] }
      label = item[:label].to_s
      if group
        group[:labels] << label if label.present?
      else
        groups << {icon: item[:icon], rotation: item[:rotation], labels: (label.present? ? [label] : [])}
      end
    end
  end

  # Consolidated top-left indicators (top_left + weather_status). Grouping
  # merges items that share an icon (and rotation) so "LOCK Front, LOCK Back"
  # renders as a single "LOCK Front, Back".
  def left_groups
    self.class.consolidate(@view_object[:top_left] + @view_object[:weather_status])
  end

  # Consolidated top-right indicators.
  def right_groups
    self.class.consolidate(@view_object[:top_right])
  end

  # "Artist · Track" for the now-playing feed, or nil when the feed is not
  # rendered by this layout or nothing is playing.
  def now_playing_text
    return nil unless @now_playing

    playing = @view_object[:now_playing]
    return nil if playing.blank?

    [playing[:artist], playing[:track]].compact_blank.join(" · ")
  end
end
