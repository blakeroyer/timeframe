# frozen_string_literal: true

class Devices::TimelineComponent < ViewComponent::Base
  # The periodic (timed events) column is a fixed 30rem so every layout keeps
  # its established proportions. flexible_width lets it fill the remaining row
  # instead, which the room-scale reTerminal/TRMNL X landscape needs because
  # the fixed columns no longer fit the panel at the larger root font size.
  def initialize(view_object:, flexible_width: false)
    @view_object = view_object
    @flexible_width = flexible_width
  end

  def periodic_column_style
    @flexible_width ? "flex: 1 1 auto; min-width: 0;" : "width: 30rem;"
  end
end
