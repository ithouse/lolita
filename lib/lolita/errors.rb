module Lolita
  class NotORMClassError < ArgumentError; end
  class NoFieldsGivenError < ArgumentError; end
  class SameTabTypeError < ArgumentError; end
  class ReferenceError < ArgumentError; end
  class FieldNameError < NoMethodError; end
  class FieldTypeError < ArgumentError; end
  class ModuleNotFound < ArgumentError; end
  class NotFound < ArgumentError; end
  class TabNotFoundError < NameError; end
  class FieldNotFoundError < NameError; end
  class AssociationError < ArgumentError; end
  class HookNotFound < ArgumentError;end
end