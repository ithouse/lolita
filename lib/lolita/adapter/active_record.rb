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

        def key
          @association.association_foreign_key
        end

        def polymorphic?
          @association.options[:polymorphic]
        end

        def macro
          convertator = {:has_many => :many, :has_one => :one, :belongs_to => :one, :has_and_belongs_to_many => :many}
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

      # Return all association class names
      def associations_class_names
        self.associations.map{|name,association|
          association.class_name
        }
      end

      # Detect if class reflect on association by name
      def reflect_on_association(name)
        if orm_association = klass.reflect_on_association(name)
          Association.new(orm_association,self)
        end
      end

      # Each field from ORM is changed to this class instance.
      class Field
        include Lolita::Adapter::FieldHelper

        attr_reader :field, :name,:options, :type, :adapter
        def initialize(column,adapter)
          @field = column
          raise ArgumentError, "Cannot initialize adapter field for nil" unless @field
          @adapter = adapter
          set_attributes
        end

        def association
          unless @association
            possible_association = @adapter.associations.detect{|name,association|
              [association.key.to_s].include?(@name.to_s)
            }
            @association = possible_association.last if possible_association
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

      def find_by_id(id)
        self.klass.unscoped.find_by_id(id)
      end

      # This method is used to paginate, main reason is for list and for index action. 
      # Method accepts three arguments
      # <tt>page</tt> - page that should be shown (integer)
      # <tt>per</tt> - how many records there should be in page
      # <tt>options</tt> - Hash with optional information. 
      # By default, Lolita::Configuration::List passes request, with current request information.
      # Also it passes <i>:pagination_method</i> that is used to detect if there is special method(-s) in model
      # that should be used for creating page.
      def paginate(page,per,options ={})
        scope = nil
        if options[:pagination_method]
          if options[:pagination_method].respond_to?(:each)
            options[:pagination_method].each do |method_name|
              options[:previous_scope] = scope
              if new_scope = pagination_scope_from_klass(method_name,page,per,options)
                scope = scope ? scope.merge(new_scope) : new_scope
              end
            end
          else
            scope = pagination_scope_from_klass(options[:pagination_method],page,per,options)
          end
          scope
        else
          klass.unscoped.page(page).per(per)
        end
      end

      def pagination_scope_from_klass(method_name,page,per,options)
        if klass.respond_to?(method_name)
          klass.send(method_name,page,per,options)
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

    end
  end
end
