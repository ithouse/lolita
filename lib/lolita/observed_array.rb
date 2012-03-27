module Lolita
  # This module overwrite Array methods that change Array to change element that is added to Array.
# Class that include this module must have collection_variable method that return collection
# variable that hold all records.
# Also build_element method must have with element and &block as arguments
# Build element method should contain actions that modify element or if you do not want to
# change given element, than return it.
# ====Example
#     class MyCollection
#      ...
#      def build_element(element)
#        element=element.to_s if element.is_a?(Symbol)
#        element
#      end
#     end
#
#     my_collection=MyCollection.new
#     my_collection.push(:element)
#     my_collection.last #=> element
#     my_collection.last.class #=> String
#     
# ====Example
#     class MyClass
#       include Lolita::ObservedArray
#       private
#         def collection_variable
#           @collection_variable
#         end
#         def build_element(element,&block)
#           ...
#         end
#     end
  module ObservedArray

    def method_missing(method,*args,&block)
      generate_collection_elements! if self.respond_to?(:generate_collection_elements!)
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

    #To support enumerable functions as each, collect etc.
    def each
      collection_variable.each{|collection_element| yield collection_element}
    end

    private

    def collection_variable
      raise "You should implement collection_variable method in your class. See ObservedArray for implementation."
    end
    
    def build_element(element,&block)
      raise "You should implement collection_variable method in your class.See ObsservedArray for implementation."
    end
  end
end