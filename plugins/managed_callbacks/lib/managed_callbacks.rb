# coding: utf-8
# SIA Lolita
# Artūrs Meisters

module Lolita
  # With managed callbacks you can modify the object and related objects before and after different events.
  # Usage - put this function call in your controller (should be extended form Managed):
  
  # Handle #Managed events and execute all methods that are specified in _controller_ and its _superclasses_.
  # To register callback in _controller_ that ancestors must include #Managed class.
  # All callbacks are exacuted from #Managed down to current _controller_.
  # Available +callbacks+ are
  # * <tt>:before_create</tt> - Also :before_open is called
  # * <tt>:before_open</tt> - Execute on :before_new and :before_edit
  # * <tt>:before_update</tt> - Also :before_save is called
  # * <tt>:before_list</tt>
  # * <tt>:before_destroy</tt>
  # * <tt>:before_save</tt> - Execute on :before_create and :before_update
  # * <tt>:before_edit</tt> - Also :before_open is called
  # * <tt>:before_new</tt> - Also :before_open is called
  # * <tt>:before_show</tt>
  # * <tt>:after_new</tt> - Also :after_open is called
  # * <tt>:after_update</tt> - Also :after_save is called
  # * <tt>:after_save</tt> - Execute on :after_create and :after_update
  # * <tt>:after_create</tt> - Also :after_save is called
  # * <tt>:after_edit</tt> - Also :after_open is called
  # * <tt>:after_destroy</tt>
  # * <tt>:after_list</tt>
  # * <tt>:after_open</tt> - Execute on :after_edit and :after_new
  # * <tt>:after_show</tt>
  # * <tt>:on_save_error</tt>
  # * <tt>:on_show_error</tt>
  # * <tt>:on_create_error</tt>
  #
  # ====Examples:
  #   class BlogController < Managed
  #     managed_after_save :send_registration_email, :add_default_roles
  #     managed_on_save_errors :copy_errors_to_main_object
  #   end
  # 
  module ManagedCallbacks

    def self.included(base) # :nodoc:
      base.extend(ControllerClassMethods)
      base.class_eval do
        include ControllerInstanceMethods
      end
    end
    
    MANAGED_CALLBACKS=%w(
        before_create before_open before_update before_list before_destroy
        before_save before_edit before_new before_show after_new after_update after_save
        after_create after_edit after_destroy after_list after_open after_show on_save_error
        on_show_error on_create_error
    )

    # Define all methods by creating _ControllerClassMethods_ module.
    # All class methods for registering _callbacks_ is called <b>managed_{callback name}</b>
    # These methods can be called form any _controller_, but it raise error if that _controller_
    # is not _subclass_ of #Managed
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

      # Execute all methods for given _callback_ and _klass_ (default current _controller_ class).
      # Recursively execute all callbacks from #Managed to _self_ class.
      # When callback method return *false* (not *nil*) then execution of other methods will stop
      # Private methods can be called as well.
      # Error will be raised if _self_ is not _subclass_ of #Managed
      def exacute_managed_callbacks(callback,klass=self.class) #FIXME wrong english
        raise "Must be subclass of Managed" unless klass.ancestors.include?(Managed)
        unless klass==Managed
          result=exacute_managed_callbacks(callback,klass.superclass)
        end
        if klass==self.class
          if callback.to_s.match(/_new|_edit/)
            result=exacute_managed_callbacks(callback.to_s.gsub(/_new|_edit/,"_open"),klass)
          elsif callback.to_s.match(/_create|_update/)
            result=exacute_managed_callbacks(callback.to_s.gsub(/_create|_update/,"_save"),klass)
          end
        end
        if !result.is_a?(FalseClass) && klass.managed_callbacks && klass.managed_callbacks[callback.to_sym]
          klass.managed_callbacks[callback.to_sym].each{|method|
            result=self.send(method)
            return result if result.is_a?(FalseClass)
          }
          return result
        end
      end
    end
  end
end