# frozen_string_literal: true

require "digest"
require "json"

module Menus
  class ContentFingerprint
    def self.for_menu(menu)
      entries = menu.menu_entries.to_a.sort_by { |e| [ e.weekday, e.meal_type.to_s, e.id || 0 ] }
      payload = entries.map do |e|
        [ e.weekday, e.meal_type.to_s, e.freeform_text.to_s, e.recipe_id ]
      end
      Digest::SHA256.hexdigest(JSON.generate(payload))
    end
  end
end
