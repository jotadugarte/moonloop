module ApplicationHelper
  def exercise_routine_weekday_options_for_select
    I18n.t("date.day_names").each_with_index.map { |name, i| [ name, i ] }
  end

  def exercise_routine_form_errors?(routine)
    return true if routine.errors.any?
    return true if routine.catalog_listing_facet&.errors&.any?

    routine.exercise_routine_lines.any? { |line| line.errors.any? }
  end

  # ARIA for server-rendered validation summaries (WCAG: role="alert" on list + per-field invalid/describedby).
  def aria_for_field(model, attr, error_summary_id)
    return {} if model.errors[attr].blank?

    { invalid: true, describedby: error_summary_id }
  end

  # Raster images get a resized variant; SVG and other non-variable types use the original blob.
  # Default +loading: lazy+ keeps the menu grid cheap; pass +loading: "eager"+ for above-the-fold heroes.
  def attachable_image_tag(attachment, resize_to_limit:, **image_options)
    opts = { loading: "lazy" }.merge(image_options)
    image_tag attachable_image_source(attachment, resize_to_limit), **opts
  end

  def recipe_image_tag(recipe, resize_to_limit:, **image_options)
    attachment = recipe.image
    return if attachment.blank? || !attachment.attached?

    return placeholder_recipe_image_tag(recipe, **image_options) if recipe_placeholder_svg?(recipe)

    attachable_image_tag attachment, resize_to_limit: resize_to_limit, **image_options
  end

  def menu_slot_preview_image_tag(preview, meal_type)
    return if preview.blank?

    alt = t("menus.slots.preview_alt", meal: t("menus.meal_types.#{meal_type}"))
    data = { test: "menu-slot-preview" }

    if preview.display == :uploaded
      attachable_image_tag preview.uploaded_image,
        resize_to_limit: [ 160, 160 ],
        alt: alt,
        class: "menu-grid__slot-preview-img",
        data: data
    else
      image_tag preview.fallback_asset_path,
        alt: alt,
        class: "menu-grid__slot-preview-img menu-grid__slot-preview-img--fallback",
        data: data.merge(preview_kind: "fallback")
    end
  end

  private

  def attachable_image_source(attachment, resize_to_limit)
    return attachment if attachment_svg?(attachment)
    return attachment unless attachment.variable? && ImageVariants::Available.call

    attachment.variant(resize_to_limit: resize_to_limit)
  end

  def attachment_svg?(attachment)
    attachment&.blob&.content_type == "image/svg+xml"
  end

  def recipe_placeholder_svg?(recipe)
    blob = recipe.image&.blob
    return false if blob.blank?
    return false unless blob.content_type == "image/svg+xml"

    blob.filename.to_s.start_with?("fallback_")
  end

  def placeholder_recipe_image_tag(recipe, **image_options)
    opts = { loading: "lazy" }.merge(image_options)
    image_tag "menus/fallback_#{recipe.meal_type}.svg", **opts
  end
end
