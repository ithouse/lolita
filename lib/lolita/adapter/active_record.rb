module Lolita
  module Adapter
    class ActiveRecord

      include Lolita::Adapter::AbstractAdapter

      attr_reader :dbi, :klass
      def initialize(dbi)
        @dbi=dbi
        @klass=dbi.klass
      end

      # Association adapter
      class Association
        attr_reader :association, :adapter

        def initialize(assoc_object,adapter)
          @association = assoc_object
          @adapter = adapter
        end

        def method_missing(method, *args, &block)
          @association.send(method,*args,&block)
        end

        def key # maybe this isn't neccessery any more
          if @association.macro == :has_and_belongs_to_many || through?
            association_key
          else
            @association.foreign_key
          end
        end

        def association_key
          @association.association_foreign_key
        end

        def foreign_key
          @association.foreign_key
        end

        def through
          @association.options[:through]
        end

        def through?
          @association.options.has_key?(:through)
        end

        def polymorphic?
          @association.options[:polymorphic]
        end

        def native_macro
          @association.macro
        end

        def macro
          convertator = {
            :has_many => :many, :has_one => :one, :belongs_to => :one,
            :has_and_belongs_to_many => :many_to_many
          }
          convertator[@association.macro]
        end
      end

      # Return all class associations
      def associations
        # is caching ok?
        unless @associations
          @associations = {}
          klass.reflections.each{|name,association|
            @associations[name] = Association.new(association,self)
          }
        end
        @associations
      end

      # Each field from ORM is changed to this class instance.
      class Field
        include Lolita::Adapter::FieldHelper

        attr_reader :field, :name, :options, :type, :adapter
        def initialize(column,adapter)
          @field = column
          raise ArgumentError, "Cannot initialize adapter field for nil" unless @field
          @adapter = adapter
          set_attributes
        end

        def association
          if @association.nil?
            possible_association = @adapter.associations.detect{|name,association|
              [association.key.to_s].include?(@name.to_s)
            }
            @association = if possible_association
              possible_association.last
            else
              false
            end
          end
          @association
        end

        def key
          @association.foreign_association_key
        end

        def method_missing(method,*args,&block)
          @field.send(method,*args,&block)
        end

        def primary?
          !!self.options[:primary]
        end

        def self.types
          {
            'decimal' => 'big_decimal',
            'datetime' => 'date_time',
            'text' => 'string'
          }
        end

        private

        def set_attributes
          @name = @field.name
          @type = type_cast(@field.type)
          @options = {
            :primary => @field.primary,
            :native_type => @field.type.to_s
          }
        end

        def type_cast type_name
          type = self.class.types[type_name.to_s] || type_name.to_s
          if self.association
            type = "array"
          end
          type
        end
      end # end of field

      include Lolita::Adapter::CommonHelper

      def fields
        @fields||=self.klass.columns.collect{|column|
          Field.new(column,self)
        }
        @fields
      end

      def field_by_name(name)
        self.fields.detect{|field|
          field.name.to_s == name.to_s
        }
      end

      def field_by_association(name)
        possible_association = self.associations.detect{|assoc_name,association|
          name.to_s == assoc_name.to_s
        }
        if possible_association
          self.field_by_name(possible_association.last.key)
        end
      end

      def search(query, options = {})
        #TODO raise error or warn when there are lot of records and no index on field
        unless query.blank?
          resources = self.klass.arel_table
          content_fields = @dbi.fields.map{|field| field.type!="string" ? nil : field.name.to_sym}.compact
          if options[:fields] && options[:fields].any?
            content_fields = content_fields & options[:fields]
          end
          scope = nil
          content_fields.each_with_index do |field,index|
            new_scope = resources[field].matches("%#{query}%")
            unless index == 0
              scope = scope.or(new_scope)
            else
              scope = new_scope
            end
          end
          self.klass.where(scope)
        else
          self.klass.where(nil)
        end
      end

      def db
        self.klass.connection
      end

      def db_name
        db.current_database
      end

      def collection
        self.klass #FIXME not realy same as in mongoid
      end

      def collection_name
        self.klass.table_name
      end

      def collection_name=(value)
        self.klass.table_name = value
      end

      def collections
        self.klass #FIXME not  realy same as in mongoid
      end

      def collection_names
        self.klass.connection.select_all("show tables from #{db_name}").map{|r| r.values.first}
      end

      def nested_attributes_options
        self.klass.nested_attributes_options
      end

      def order_method
        :order
      end
    end
  end
end
