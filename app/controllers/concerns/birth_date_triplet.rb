# Parses user[birth_year], user[birth_month], user[birth_day] into a Date or status symbols.
module BirthDateTriplet
  extend ActiveSupport::Concern

  private

  # @return [Date] calendar-valid date
  # @return :incomplete if any component blank
  # @return :invalid if combination is not a real calendar day
  def birth_date_from_triplet(year, month, day)
    y, m, d = [ year, month, day ].map { |v| v.presence&.to_s }
    return :incomplete if [ y, m, d ].any?(&:blank?)

    yi, mi, di = y.to_i, m.to_i, d.to_i
    return :invalid unless Date.valid_date?(yi, mi, di)

    Date.new(yi, mi, di)
  end
end
