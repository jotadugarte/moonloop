# frozen_string_literal: true

module Menus
  class AdoptFromPublicCatalog
    class Error < StandardError
      attr_reader :key

      def initialize(key)
        @key = key
        super()
      end
    end

    def self.call(adopter:, source:, chosen_name:)
      raise Error.new(:not_public) unless source.publicly_shareable?
      raise Error.new(:cannot_adopt_own) if source.user_id == adopter.id
      if adopter.menus.where(source_menu_id: source.id).exists?
        raise Error.new(:already_adopted)
      end

      name = chosen_name.to_s.strip
      raise Error.new(:name_blank) if name.blank?

      fp = ContentFingerprint.for_menu(source)

      ApplicationRecord.transaction do
        recipe_map = {}
        source.menu_entries.where.not(recipe_id: nil).distinct.pluck(:recipe_id).compact.each do |rid|
          src_recipe = Recipe.find(rid)
          recipe_map[rid] = DuplicateRecipeForAdopter.call(source_recipe: src_recipe, adopter: adopter).id
        end

        copy = Menu.new(
          user: adopter,
          name: name,
          source_menu_id: source.id,
          source_sync_fingerprint: fp,
          adoption_catalog_origin_id: source.id,
          publicly_shareable: false
        )
        CopyMenuEntriesFromSource.call(target_menu: copy, source_menu: source, recipe_map: recipe_map)
        copy.save!
        Catalog::IncrementTemplateAdoptionMetrics.call(source)
        copy
      end
    end
  end
end
