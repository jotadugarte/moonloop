# frozen_string_literal: true

# Maps ActiveRecord::RecordInvalid from adopt flows to i18n (no raw model sentences in flash).
module AdoptionInvalidRecordFlash
  extend ActiveSupport::Concern

  private

  def adoption_invalid_alert_for(record)
    if record.errors.details[:name]&.any? { |h| h[:error] == :taken }
      t("adoption.invalid_record.name_taken")
    else
      t("adoption.invalid_record.could_not_save")
    end
  end
end
