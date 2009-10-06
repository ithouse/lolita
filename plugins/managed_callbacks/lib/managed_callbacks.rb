# SIA ITHouse
# Artūrs Meisters

module Lolita
  module ManagedCallbacks

    def self.included(base)
      base.extend(ControllerClassMethods)
      base.class_eval do
        include ControllerInstanceMethods
      end
    end
    
    MANAGED_CALLBACKS=%w(
        before_create before_open before_update before_list before_destroy
        before_save before_edit before_new before_show after_new after_update after_save
        after_create after_edit after_destroy after_list after_open after_show on_save_error
    )
    def self.create_managed_callback_methods
      MANAGED_CALLBACKS.collect{|cb|
        %!
        def managed_#{cb}(*args)
          add_managed_callback("#{cb}".to_sym,args)
        end

        !
      }.join("")
    end
    eval(%^
      module ControllerClassMethods
        attr_accessor :managed_callbacks
        #{self.create_managed_callback_methods()}
        private

        def add_managed_callback(method,args)
          if self.ancestors.include?(Managed)
            self.managed_callbacks||={}
            self.managed_callbacks[method]||=[]
            self.managed_callbacks[method]+=args
          else
            raise "Must be child class of Managed!"
          end
        end
      end
      ^)
    module ControllerInstanceMethods

      def exacute_managed_callbacks(callback,klass=self.class)
        unless klass==Managed
          exacute_managed_callbacks(callback,klass.superclass)
        end
        if klass==self.class
          if callback.to_s.match(/_new|_edit/)
            exacute_managed_callbacks(callback.to_s.gsub(/_new|_edit/,"_open"),klass)
          elsif callback.to_s.match(/_create|_update/)
            exacute_managed_callbacks(callback.to_s.gsub(/_create|_update/,"_save"),klass)
          end
        end
        if klass.managed_callbacks && klass.managed_callbacks[callback.to_sym]
          klass.managed_callbacks[callback.to_sym].each{|method|
            self.send(method)
          }
        end
      end
    end
  end
end