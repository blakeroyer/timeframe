# frozen_string_literal: true

# Landscape variant of the reTerminal timeline. The content is identical to the
# portrait ReterminalComponent; the display is rendered at swapped (landscape)
# dimensions so the wider canvas gives the timeline its full horizontal width.
#
# This is the first template with "Screen composition" controls
# (DeviceSettingsOptions#composition_options). Both rendering choices below are
# off unless the device's configuration turns them on, so portrait devices and
# unconfigured landscape devices render exactly as before.
class Devices::ReterminalLandscapeComponent < ViewComponent::Base
  def initialize(view_object:)
    @view_object = view_object
  end

  def room_scale?
    @view_object.dig(:configuration, "room_scale_text") == "true"
  end

  def now_playing?
    @view_object.dig(:configuration, "show_ha_now_playing") == "true"
  end
end
