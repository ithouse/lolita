module Lolita
  class NotORMClassError < ArgumentError; end
  class NoFieldsGivenError < ArgumentError; end
  class SameTabTypeError < ArgumentError; end
  class ReferenceError < ArgumentError; end
  class FieldNameError < NoMethodError; end
  class FieldTypeError < ArgumentError; end
end