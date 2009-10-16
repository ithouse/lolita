module Lolita #:nodoc:
  module FactoryPatch
    # With this patch you can use models with namespaces, like Admin::User
    #
    #    Factory.define :"admin/user" do
    #    end
    #
    
    def self.included(base)
      base.class_eval{
        include InstanceMethods
      }
      base.alias_method_chain :class_for, :lolita
    end
    module InstanceMethods
      def class_for_with_lolita (class_or_to_s)
        if class_or_to_s.respond_to?(:to_sym)
          names = variable_name_to_class_name(class_or_to_s).split('::')
          names.shift if names.empty? || names.first.empty?
          constant = Object
          names.each do |name|
            constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
          end
          constant
        else
          class_or_to_s
        end
      end
    end

  end
end
Factory.send(:include,Lolita::FactoryPatch)