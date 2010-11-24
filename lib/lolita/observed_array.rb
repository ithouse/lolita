# This module overwrite Array methods that change Array to change element that is added to Array.
# Class that include this module must have collection_variable method that return collection
# variable that hold all records.
# Also build_element method must have with element and &block as arguments
# ====Example
#     class MyClass
#       private
#         def collection_variable
#           @collection_variable
#         end
#         def build_element(element,&block)
#           ...
#         end
#     end
module Lolita
  module ObservedArray

    def method_missing(method,*args,&block)
      collection_variable.__send__(method,*args,&block)
    end
    
    def push(value)
      value=build_element(value)
      collection_variable.push(value)
    end

    def insert(value)
      value=build_element(value)
      collection_variable.insert(value)
    end

    def <<(value)
      value=build_element(value)
      collection_variable<<value
    end

    def []=(value,index)
      value=build_element(value)
      collection_variable[index]=value
    end
    private

    def collection_variable
      raise "You should implement this method in your class."
    end
    def build_element(element,&block)
      raise "You should implement this method in your class."
    end
  end
end