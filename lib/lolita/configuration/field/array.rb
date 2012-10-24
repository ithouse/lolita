module Lolita
  module Configuration
    module Field
      # Fields with Array is used to 
      # * create select for belongs_to association or 
      # * has_and_belongs_to_many field for selecting all associated objects or
      # * for polymorphic belongs_to associations
      # ==Polymorphic builder (:polymorphic)
      # Create two select boxes one of all related classes and second with related records for that class.
      # Related classes can have <em>polymorphic_select_name</em> instance method, that is used to populate second
      # select with visible values by default it calles <em>text_method</em>. It will fallback first content column. Class should respond to one
      # of these. 
      class Array < Lolita::Configuration::Field::Base
        include Lolita::Hooks
        MAX_RECORD_COUNT = 100
        
        add_hook :after_association_loaded

        lolita_accessor :text_method,:value_method,:association,:include_blank
        lolita_accessor :related_classes

        def initialize dbi,name,*args, &block
          @include_blank=true
          super
          self.find_dbi_field unless self.dbi_field
          
          @association ||= self.dbi_field ? self.dbi_field.association : detect_association
          self.run(:after_association_loaded)
          self.builder = detect_builder unless @builder
          self.name = recognize_real_name
        end

        # For details see Lolita::Configuration::Search
        def search *args, &block
          if (args && args.any?) || block_given?
            self.after_association_loaded do
              @search = create_search(*args,&block)
            end
          end
          @search
        end

        def create_search *args, &block
          Lolita::Configuration::Search.new(Lolita::DBI::Base.create(@association.klass),*args,&block)
        end

        def values=(value=nil)
          @values=value
        end

        # Use this with block if values are dynamicly collected.
        def values value=nil, &block
          @values=value || block if value || block_given?
          @values
        end

        # Collect values for array type field.
        # Uses <code>text_method</code> for content. By default it search for
        # first _String_ type field in DB. Uses <code>value_method</code> for value,
        # by default it it is <code>id</code>.
        def association_values(record = nil) #TODO test
          @association_values=if values
            values
          elsif search
            search.run("")
          elsif @association && @association.polymorphic?
            polymorphic_association_values(record)
          elsif @association
            klass=@association.klass
            options_array(collect_records_for(klass))
          else
            []
          end
          @association_values
        end

        # Collect values for polymorphic association, you may pass 
        # * <tt>:klass</tt> - class that's records are used
        # * <tt>:record</tt> - record class that has polymorphic association. It is used to call to detect related object class.
        def polymorphic_association_values(options={})
          options ||= {}
          options[:klass] ||= options[:record] && options[:record].send(self.name) ? options[:record].send(self.name).class : nil
          if options[:klass]
            options_array(collect_records_for(options[:klass]))
          else
            []
          end
        end

        def options_array(collection)
          klass = collection.last ? collection.last.class : nil
          collection.map{|r|
            [r.send(current_text_method(klass)),r.send(current_value_method)]
          }
        end

        def current_text_method(klass)
          @text_method || default_text_method(klass)
        end

        def current_value_method
          @value_method || :id
        end

        # used in views for shorter accessing to values
        def view_values(view)
          record = view.send(:current_form).object
          values = association_values(record)
          if values.respond_to?(:call)
            values.call(view)
          else
            association_values(record)
          end
        end

        def detect_builder
          if @association
            if @association.polymorphic?
              "polymorphic"
            elsif @association.macro == :many_to_many
              "autocomplete"
            else
              "select"
            end
          else
            "select"
          end
        end

        def detect_association
          unless @association
            dbi.associations[self.name.to_sym]
          else
            @association
          end
        end

        def polymorphic_classes
          if @related_classes
            @related_classes.map do |klass|
              [klass.constantize.lolita_model_name.human, klass.to_s]
            end
          else
            []
          end
        end

        def recognize_real_name
          if @association && !@association.polymorphic? && @association.macro == :one
            @real_name = self.name
            self.name = @association.key
          else
            @name
          end
        end

        private

        def default_text_method(klass)
          assoc_dbi=Lolita::DBI::Base.create(klass) rescue nil
          if assoc_dbi
            field = assoc_dbi.fields.detect{|f| f.name.to_s == "title"}
            field ||= assoc_dbi.fields.detect{|f| f.name.to_s == "name"}
            field ||= assoc_dbi.fields.detect{|f| f.type.to_s=="string"}
            if field
              field.name
            else
              raise Lolita::FieldTypeError, %^
              Can't find any content field in #{assoc_dbi.klass}.
              Use text_method in #{klass} to set one.
              ^
            end
          else
            warn("Not a ORM class (#{klass.inspect})")
          end
        end

        def collect_records_for(klass)
          if klass.count > MAX_RECORD_COUNT
            raise ArgumentError.new("#{@dbi.klass} field #{@name} association has too many records(#{klass.count})")
          else
            klass.all
          end
        end
      end
    end
  end
end
