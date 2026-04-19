# frozen_string_literal: true

module Menus
  class AdoptionSyncStatus
    Status = Struct.new(:key, :origin_fingerprint, keyword_init: true)

    def self.for_menu(menu)
      return Status.new(key: :none) unless menu.adoption_catalog_origin_id.present?

      if menu.source_menu_id.blank?
        return Status.new(key: :unavailable)
      end

      source = menu.source_menu
      if source.nil?
        return Status.new(key: :unavailable)
      end

      unless source.publicly_shareable?
        return Status.new(key: :unavailable)
      end

      fp = ContentFingerprint.for_menu(source)
      if menu.source_sync_fingerprint == fp
        Status.new(key: :synced, origin_fingerprint: fp)
      else
        Status.new(key: :pending, origin_fingerprint: fp)
      end
    end
  end
end
