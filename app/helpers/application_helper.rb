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
  def attachable_image_tag(attachment, resize_to_limit:, variant_name: nil, **image_options)
    opts = { loading: "lazy" }.merge(image_options)
    image_tag attachable_image_source(attachment, resize_to_limit, variant_name), **opts
  end

  def dish_image_tag(dish, resize_to_limit:, **image_options)
    attachment = dish.image
    return if attachment.blank? || !attachment.attached?
    return unless persistable_active_storage_attachment?(attachment)

    return placeholder_dish_image_tag(dish, **image_options) if dish_placeholder_svg?(dish)

    attachable_image_tag attachment, resize_to_limit: resize_to_limit, **image_options
  end

  def menu_slot_preview_image_tag(preview, meal_type)
    return if preview.blank?

    alt = t("menus.slots.preview_alt", meal: t("menus.meal_types.#{meal_type}"))
    data = { test: "menu-slot-preview" }

    return menu_slot_preview_uploaded_image_tag(preview, alt, data) if preview.display == :uploaded

    menu_slot_preview_fallback_image_tag(preview, alt, data)
  end

  private

  def attachable_image_source(attachment, resize_to_limit, variant_name)
    return attachment if attachment_svg?(attachment)
    return attachment unless attachment.variable? && ImageVariants::Available.call

    attachment.variant(attachable_image_variant_options(variant_name, resize_to_limit))
  end

  def attachable_image_variant_options(variant_name, resize_to_limit)
    return ImageVariants::VariantOptions.for(variant_name).merge(resize_to_limit: resize_to_limit) if variant_name.present?

    { format: :webp, resize_to_limit: resize_to_limit }
  end

  def persistable_active_storage_attachment?(attachment)
    active_storage_attachment = attachment&.attachment
    return false if active_storage_attachment.blank?

    active_storage_attachment.persisted?
  end

  def menu_slot_preview_uploaded_image_tag(preview, alt, data)
    attachable_image_tag(preview.uploaded_image, **menu_slot_preview_uploaded_image_options(alt, data))
  end

  def menu_slot_preview_fallback_image_tag(preview, alt, data)
    image_tag(preview.fallback_asset_path, **menu_slot_preview_fallback_image_options(alt, data))
  end

  def menu_slot_preview_uploaded_image_options(alt, data)
    { variant_name: :thumb, resize_to_limit: ImageVariants::ResizeToLimit.for(:thumb), alt: alt, class: "menu-grid__slot-preview-img", data: data }
  end

  def menu_slot_preview_fallback_image_options(alt, data)
    { alt: alt, class: "menu-grid__slot-preview-img menu-grid__slot-preview-img--fallback", data: data.merge(preview_kind: "fallback") }
  end

  def attachment_svg?(attachment)
    attachment&.blob&.content_type == "image/svg+xml"
  end

  def dish_placeholder_svg?(dish)
    blob = dish.image&.blob
    return false if blob.blank?
    return false unless blob.content_type == "image/svg+xml"

    blob.filename.to_s.start_with?("fallback_")
  end

  def placeholder_dish_image_tag(dish, **image_options)
    opts = { loading: "lazy" }.merge(image_options)
    image_tag "menus/fallback_#{dish.meal_type}.svg", **opts
  end
end
