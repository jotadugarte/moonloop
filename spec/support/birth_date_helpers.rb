module BirthDateHelpers
  # Default app locale is :es; month names come from I18n "date.month_names".
  def select_user_birth_date(page, year:, month:, day:)
    names = I18n.t("date.month_names")
    raise ArgumentError, "month must be 1..12" unless (1..12).cover?(month)

    page.select day.to_s, from: I18n.t("shared.birth_date_fields.day_label")
    page.select names[month].to_s, from: I18n.t("shared.birth_date_fields.month_label")
    page.select year.to_s, from: I18n.t("shared.birth_date_fields.year_label")
  end

  def clear_user_birth_date(page)
    page.select I18n.t("shared.birth_date_fields.day_prompt"), from: I18n.t("shared.birth_date_fields.day_label")
    page.select I18n.t("shared.birth_date_fields.month_prompt"), from: I18n.t("shared.birth_date_fields.month_label")
    page.select I18n.t("shared.birth_date_fields.year_prompt"), from: I18n.t("shared.birth_date_fields.year_label")
  end
end

RSpec.configure do |config|
  config.include BirthDateHelpers, type: :system
end
