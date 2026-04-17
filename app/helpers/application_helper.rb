module ApplicationHelper
  def menu_slot_preview_image_tag(preview, meal_type)
    return if preview.blank?

    alt = t("menus.slots.preview_alt", meal: t("menus.meal_types.#{meal_type}"))
    data = { test: "menu-slot-preview" }

    if preview.display == :uploaded
      image_tag preview.uploaded_image.variant(resize_to_limit: [ 160, 160 ]),
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
