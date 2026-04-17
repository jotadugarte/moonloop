module ApplicationHelper
  # Raster images get a resized variant; SVG and other non-variable types use the original blob.
  # Default +loading: lazy+ keeps the menu grid cheap; pass +loading: "eager"+ for above-the-fold heroes.
  def attachable_image_tag(attachment, resize_to_limit:, **image_options)
    image_options = { loading: "lazy" }.merge(image_options)

    source =
      if attachment.variable?
        attachment.variant(resize_to_limit: resize_to_limit)
      else
        attachment
      end
    image_tag source, **image_options
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
end
