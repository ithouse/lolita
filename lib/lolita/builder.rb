module Lolita
  # Any Lolita::Configuration class that should return visual information about itself
  # can include Builder::Base, that provide default methods for _controllers_ to use.
  # * #build method is used to render component for class instance.
  # * #build_options is method that return specific options for builder, to pass to component,
  #   such as :color,:postition etc.
  # * #builder is setter/getter method for Lolita::Configuration, that accept Hash or Array or single
  #   String or Symbol for buider.
  #
  module Builder
    lolita_accessor :builder

    # Build response. Render component for current class with given options.
    def build(*args)
      args||=[]
      options=args.extract_options!
      builder_options=self.builder_options || {}
      options=(options || {}).merge(builder_options)
      builder_values=self.get_builder(args[0],args[1])
      return builder_values[:name],builder_values[:state],options
    end

    # Default options for class. This method should be overwritten.
    def builder_options
      {builder_local_variable_name=>self}
    end

    # Set or get builder for class.
    # _Value_ can be
    # * <tt>Hash</tt> where key <code>:name</code> is component name and <code>:state</code> is component state
    # * <tt>Array or two args</tt> - first is used as _name_ and second as _state_.
    # * <tt>String or Symbol (one arg)</tt> - is used as _name_.
    # Default _name_ is Lolita::Configuration class name (example <code>:list</code>) and
    # default state is <code>:display</code>
    def get_builder(*value)
      if value && !value.empty?
        set_builder(*value)
      elsif @builder
        set_builder(@builder)
      else
        unless @builder
          @builder=default_builder
        end
        @builder
      end
    end

    # Return default builder information.
    def default_builder
      {:name=>"/#{builder_name}",:state=>default_build_state}
    end
    
    private

    def set_builder value
      if value.is_a?(Hash)
        @builder=value
      elsif value.is_a?(Array)
        @builder={:name=>fix_name(value[0]),:state=>value[1] || default_build_state}
      else
        @builder={:name=>fix_name(value),:state=>default_build_state}
      end
    end
    
    def fix_name value
      if value.to_s[0] == '/'
        value
      else
        "/#{builder_name}/#{value}"
      end
    end

    def default_build_state
      :display
    end
    
    def builder_name
      self.class.to_s.split("::").map(&:underscore).join("/").to_sym
    end
    
    def builder_local_variable_name 
      self.class.to_s.split("::").last.underscore.to_sym
    end
  end
end