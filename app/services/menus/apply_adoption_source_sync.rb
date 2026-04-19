# frozen_string_literal: true

module Menus
  class ApplyAdoptionSourceSync
    class Error < StandardError
      attr_reader :key

      def initialize(key)
        @key = key
        super()
      end
    end

    def self.call(copy:, expected_origin_fingerprint: nil)
      raise Error.new(:not_adopted_copy) if copy.adoption_catalog_origin_id.blank?

      source = copy.source_menu
      if source.nil? || !source.publicly_shareable?
        raise Error.new(:source_unavailable)
      end

      current_fp = ContentFingerprint.for_menu(source)
      if expected_origin_fingerprint.present? && expected_origin_fingerprint != current_fp
        raise Error.new(:origin_changed_retry)
      end

      if copy.source_sync_fingerprint == current_fp
        return copy
      end

      ApplicationRecord.transaction do
        copy.reload
        source.reload
        copy.menu_entries.destroy_all
        recipe_map = {}
        source.menu_entries.where.not(recipe_id: nil).distinct.pluck(:recipe_id).compact.each do |rid|
          src_recipe = Recipe.find(rid)
          recipe_map[rid] = DuplicateRecipeForAdopter.call(source_recipe: src_recipe, adopter: copy.user).id
        end
        CopyMenuEntriesFromSource.call(target_menu: copy.reload, source_menu: source, recipe_map: recipe_map)
        copy.source_sync_fingerprint = current_fp
        copy.save!
      end
      copy.reload
    end
  end
end
