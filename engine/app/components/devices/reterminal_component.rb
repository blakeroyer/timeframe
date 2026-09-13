# frozen_string_literal: true

class Devices::ReterminalComponent < ViewComponent::Base
  # Root font size for the 1872x1404-class panels. ROOM_SCALE is the landscape
  # composition option for displays read from across the room; the timeline
  # switches to a flexible width in that mode so its columns still fit.
  FONT_SIZE = "38px"
  ROOM_SCALE_FONT_SIZE = "47.5px"

  def initialize(view_object:, room_scale: false, now_playing: false)
    @view_object = view_object
    @room_scale = room_scale
    @now_playing = now_playing
  end

  def font_size
    @room_scale ? ROOM_SCALE_FONT_SIZE : FONT_SIZE
  end
end
