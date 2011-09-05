module Lolita
  # Any Lolita::Configuration class that should return visual information about itself
  # can include Builder::Base, that provide default methods for _controllers_ to use.
  # * #build method is used to render component for class instance.
  # * #build_options is method that return specific options for builder, to pass to component,
  #   such as :color,:postition etc.
  # * #builder is setter/getter method for Lolita::Configuration, that accept Hash or Array or single
  #   String or Symbol for buider.
  #
  # Usage in your model
  # You can change behaviour of any of configuraton elements, to do so you should specify what 
  # builder you want to use.
  #    lolita do
  #      list do
  #        column do
  #          name :my_column
  #          builder :name => "my_columns",:state => :display, :if=>{:state => :display}
  #        end
  #      end
  #    end
  # This expample show, how to replace :display component of column by your own :display.
  # <i>:if</i> is determine, that column use builder provided to component render, but when state is <i>:display</i>
  # then it will be replaced with this on. There are elements, that only have one <i>:display</i> state, than it's
  # not necessary to provide <i>:if</i> or <i>:unless</i> state.
  module Builder

    class Custom

      class << self
        def create(element, *args)
          possible_builder = extract_args(*args)
          if possible_builder.is_a?(Hash)
            Lolita::Builder::Custom.new(element, possible_builder)
          else
            possible_builder
          end
        end

        def extract_args(*args)
          if args && args.any?
            options = args.extract_options! || {}
            if args[0] && args[0].is_a?(self)
              args[0]
            elsif args[0].is_a?(String) || args[0].is_a?(Symbol)
              options[:name] = args[0]
              if args[1]
                options[:state] = args[1]
              end
              options
            elsif options
              options
            else
               raise ArgumentError, "Don't know how to make builder from #{options}."
            end
          else
            return {}
          end
        end
      end

      attr_accessor :options,:build_attributes

      def initialize(element, attributes_as_hash)
        @element = element
        @options = {}
        @build_attributes = {}
        @conditions = {}
        set_attributes(attributes_as_hash)
        set_default_attribute_values
      end

      def with(*values)
        new_values = self.class.extract_args(*values)
        if new_values.is_a?(Hash)
          @build_attributes = new_values
        else
          raise ArgumentError, "Can't build with other builder, use build on that builder!"
        end
        self
      end

      def build
    
        path = if conditions?
          switch_path do |name,state|
            if conditions_met?
              [fixed_name(name).to_sym,state.to_sym]
            else
              [self.name, self.state]
            end
          end
        else
          [self.name,self.state]
        end
        result = path + [merged_options]
        return result
      end

      def name
        result = if build_attributes[:name].to_s.size > 0
          fixed_name(build_attributes[:name])
        else
          fixed_name(@name,build_attributes[:name])
        end
        result.to_sym
      end

      def state
        result = if build_attributes[:state] && build_attributes[:state].to_s.size > 0
          build_attributes[:state]
        else
          @state
        end
        result.to_sym
      end

      private

      def switch_path
        old_name = @name
        old_state = @state
        @name = nil
        @state = default_state
        result = yield old_name,old_state
        @name = old_name
        @state = old_state
        result 
      end

      def conditions?
        @conditions.any?
      end

      def conditions_met?
        @conditions_met = if conditions?
          if @conditions[:if]
            compare(@conditions[:if],true)
          elsif @conditions[:unless]
            compare(@conditions[:unless],false)
          end
        end
        @conditions_met
      end

      def compare(pattern,predicate)
        result = true
        pattern.each do |key,value|
          result &&= ((value.to_sym == self.send(key)) == predicate)
        end
        result
      end

      def fixed_name(name_to_fix, first_part = nil)
        unless name_to_fix.to_s[0] == "/"
          "/#{first_part.to_s.size > 0 ? first_part : default_name}/#{name_to_fix}".gsub(/\/{2,}/,"/").gsub(/\/$/,"")
        else
          name_to_fix
        end
      end

      def default_name
        @element.builder_default_name
      end

      def default_state
        @element.builder_default_state
      end

      def attributes
        [:name,:state]
      end

      def conditions
        [:if,:unless]
      end

      def merged_options
        result = {}
        (@build_attributes || {}).merge(@options).each do |key,value|
          unless attributes.include?(key.to_sym)
            result[key.to_sym] = value
          end
        end
        result
      end

      def set_attributes(attributes_as_hash)
        attributes_as_hash.each do |attr_name, value|
          if attributes.include?(attr_name.to_sym)
            instance_variable_set(:"@#{attr_name}",value)
          elsif conditions.include?(attr_name.to_sym)
            @conditions[attr_name.to_sym] = value
          else
            @options[attr_name.to_sym] = value
          end
        end
      end

      def set_default_attribute_values
        @state ||= default_state
      end

    end
    
    def builder *args
      if args && args.any?
        set_builder(*args)
      else
        @builder||=set_builder(nil)
        @builder
      end
    end

    def builder=(*args)
      set_builder(*args)
    end

    def build *values
      result = builder.with(*values).build
      result[result.size-1].merge!(default_options)
      result
    end

    def default_options
      {builder_local_variable_name => self}
    end

    def builder_default_name
      self.class.to_s.split("::").map(&:underscore).join("/").to_sym
    end

    alias :builder_name :builder_default_name

    def builder_default_state
      :display
    end

    alias :default_build_state :builder_default_state

    private

    def set_builder *args
      @builder=Lolita::Builder::Custom.create(self,*args)
    end

    def builder_local_variable_name 
      self.class.to_s.split("::").last.underscore.to_sym
    end
  end
end