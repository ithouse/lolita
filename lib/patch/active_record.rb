module ::ActiveRecord
  class Errors
    @@default_error_messages = {
      :inclusion => :"ActiveRecord.errors.inclusion",
      :exclusion => :"ActiveRecord.errors.exclusion",
      :invalid => :"ActiveRecord.errors.invalid",
      :confirmation => :"ActiveRecord.errors.confirmation",
      :accepted  => :"ActiveRecord.errors.accepted",
      :empty => :"ActiveRecord.errors.empty",
      :blank => :"ActiveRecord.errors.blank",
      :too_long => :"ActiveRecord.errors.too_long",
      :too_short => :"ActiveRecord.errors.too_short",
      :wrong_length => :"ActiveRecord.errors.wrong_length",
      :taken => :"ActiveRecord.errors.taken",
      :not_a_number => :"ActiveRecord.errors.not_a_number",
      :greater_than => :"ActiveRecord.errors.greater_than",
      :greater_than_or_equal_to => :"ActiveRecord.errors.greater_than_or_equal_to",
      :equal_to => :"ActiveRecord.errors.equal_to",
      :less_than => :"ActiveRecord.errors.less_than",
      :less_than_or_equal_to => :"ActiveRecord.errors.less_than_or_equal_to",
      :odd => :"ActiveRecord.errors.odd",
      :even => :"ActiveRecord.errors.even"
    }
  end
end