# frozen_string_literal: true

module Catalog
  # Optional discovery metadata for a catalog listable (REQ-CAT-001); at most one row per listable.
  class ListingFacet < ApplicationRecord
    self.table_name = "catalog_listing_facets"

    LISTABLE_TYPES = %w[Menu ExerciseRoutine PhaseProgram Phase].freeze
    DIFFICULTY_LEVELS = %w[beginner intermediate advanced].freeze
    MAX_TAGS = 10
    MAX_TAG_SLUG_LENGTH = 32
    TAG_SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/.freeze

    belongs_to :listable, polymorphic: true

    validates :listable_type, inclusion: { in: LISTABLE_TYPES }
    validates :listable_id, uniqueness: { scope: :listable_type }
    validates :goal_phrase, length: { maximum: 255 }, allow_blank: true
    validates :difficulty_level, inclusion: { in: DIFFICULTY_LEVELS }, allow_nil: true
    validate :normalized_tags_must_be_valid
    validate :duration_week_range_must_be_coherent

    before_validation :strip_goal_phrase
    before_validation :coerce_blank_difficulty_to_nil
    before_validation :normalize_tag_slugs

    def self.difficulty_select_options
      [ [ I18n.t("catalog_listing_facet.difficulty_blank"), "" ] ] +
        DIFFICULTY_LEVELS.map { |level| [ I18n.t("catalog_listing_facet.difficulties.#{level}"), level ] }
    end

    private

    def strip_goal_phrase
      self.goal_phrase = goal_phrase.to_s.strip.presence
    end

    def coerce_blank_difficulty_to_nil
      self.difficulty_level = nil if difficulty_level.blank?
    end

    def normalize_tag_slugs
      raw = normalized_tags.to_s
      return self.normalized_tags = nil if raw.blank?

      slugs = raw.split(",").map { |s| s.strip.downcase.presence }.compact.uniq
      self.normalized_tags = slugs.join(",")
    end

    def normalized_tags_must_be_valid
      return if normalized_tags.blank?

      slugs = normalized_tags.split(",")
      if slugs.size > MAX_TAGS
        errors.add(:normalized_tags, "must have at most #{MAX_TAGS} tags")
        return
      end

      slugs.each do |slug|
        if slug.length > MAX_TAG_SLUG_LENGTH
          errors.add(:normalized_tags, "each tag may be at most #{MAX_TAG_SLUG_LENGTH} characters")
          return
        end
        unless TAG_SLUG_PATTERN.match?(slug)
          errors.add(:normalized_tags, "must be comma-separated slugs (lowercase letters, digits, hyphens)")
          return
        end
      end
    end

    def duration_week_range_must_be_coherent
      min_w = duration_weeks_min
      max_w = duration_weeks_max
      return if min_w.nil? && max_w.nil?

      if min_w.present? && min_w < 1
        errors.add(:duration_weeks_min, :greater_than_or_equal_to, count: 1)
      end
      if max_w.present? && max_w < 1
        errors.add(:duration_weeks_max, :greater_than_or_equal_to, count: 1)
      end
      return if errors.any?

      return if min_w.blank? || max_w.blank?

      errors.add(:duration_weeks_max, :greater_than_or_equal_to, count: min_w) if max_w < min_w
    end
  end
end
