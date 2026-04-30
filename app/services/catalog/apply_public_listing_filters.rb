# frozen_string_literal: true

module Catalog
  # Applies REQ-CAT-001 discovery filters to a catalog listable relation (Menu / ExerciseRoutine / Phase / Plan).
  class ApplyPublicListingFilters
    MAX_Q_CHARS = 255

    def self.call(scope, params)
      new(scope, params).call
    end

    def initialize(scope, params)
      @scope = scope
      @params = params || {}
    end

    def call
      clauses = []
      add_goal_clause(clauses)
      add_difficulty_clause(clauses)
      add_tag_clauses(clauses)
      add_duration_clauses(clauses)
      return @scope if clauses.empty?

      clauses.reduce(@scope.joins(:catalog_listing_facet)) do |rel, (sql, *binds)|
        rel.where(sql, *binds)
      end
    end

    private

    def add_goal_clause(clauses)
      q = @params[:q].to_s.strip
      return if q.blank? || q.length > MAX_Q_CHARS

      pat = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
      clauses << [ "LOWER(catalog_listing_facets.goal_phrase) LIKE LOWER(?)", pat ]
    end

    def add_difficulty_clause(clauses)
      d = @params[:difficulty].to_s.strip.downcase
      return unless ListingFacet::DIFFICULTY_LEVELS.include?(d)

      clauses << [ "catalog_listing_facets.difficulty_level = ?", d ]
    end

    def add_tag_clauses(clauses)
      tokens = normalized_tag_tokens
      return if tokens.empty?

      tokens.each do |tag|
        next unless tag.match?(ListingFacet::TAG_SLUG_PATTERN)

        needle = "%,#{tag},%"
        sql = "',' || COALESCE(catalog_listing_facets.normalized_tags, '') || ',' LIKE ?"
        clauses << [ sql, needle ]
      end
    end

    def normalized_tag_tokens
      raw = @params[:tags]
      list =
        case raw
        when Array then raw.flat_map { |t| t.to_s.split(/[\s,]+/) }
        else raw.to_s.split(/[\s,]+/)
        end
      list.map { |t| t.to_s.strip.downcase }.reject(&:blank?).uniq.take(ListingFacet::MAX_TAGS)
    end

    def add_duration_clauses(clauses)
      min_b = parse_week_bound(:min_weeks)
      max_b = parse_week_bound(:max_weeks)
      return if min_b.nil? && max_b.nil?

      eff_max = "COALESCE(catalog_listing_facets.duration_weeks_max, catalog_listing_facets.duration_weeks_min)"
      eff_min = "COALESCE(catalog_listing_facets.duration_weeks_min, catalog_listing_facets.duration_weeks_max)"
      clauses << [ "#{eff_max} >= ?", min_b ] if min_b
      clauses << [ "#{eff_min} <= ?", max_b ] if max_b
    end

    def parse_week_bound(key)
      raw = @params[key]
      return nil if raw.blank?

      s = raw.to_s.strip
      return nil unless s.match?(/\A\d+\z/)

      i = s.to_i
      return nil if i < 1

      i
    end
  end
end
