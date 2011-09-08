module Lolita
  module Adapter
    class Mongoid

      include Lolita::Adapter::AbstractAdapter
      
      attr_reader :dbi, :klass
      def initialize(dbi)
        @dbi=dbi
        @klass=dbi.klass
      end

      # Association adapter
      class Association
        attr_reader :association,:adapter

        def initialize(assoc_object,adapter)
          @association = assoc_object
          @adapter = adapter
        end

        def method_missing(method, *args, &block)
          @association.send(method,*args,&block)
        end

        def key
          @association.key
        end

        def native_macro
          @association.macro
        end

        def macro
          convertator = {
            :references_many => :many, :references_one => :one, :referenced_in => :one, 
            :references_and_referenced_in_many => :many_to_many, :embeds_one => :one, :embeds_many => :many
          }
          convertator[@association.macro]
        end
      end


      # Return all class associations
      def associations
        # is caching ok?
        unless @associations
          @associations = {}
          klass.relations.each{|name,association|
            @associations[name.to_sym] = Association.new(association,self)
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
          unless @association.nil?
            possible_association = @adapter.associations.detect{|name,association|
              [association.key.to_s].include?(@name.to_s)
            }
            @association = possible_association.last if possible_association
          else
            @association = false
          end
          @association
        end

        def method_missing(method,*args,&block)
          @field.send(method,*args,&block)
        end

        def primary?
          !!self.options[:primary]
        end

        private

        def type_cast(type)
          if type.to_s=="Object" || type.to_s.split("::").last == "Object"
            "string" 
          elsif type.to_s.match(/::/) 
            type.to_s.split("::").last
          else
            type.to_s.underscore
          end
        end

        def set_attributes
          @name = @field.name
          @type = type_cast(@field.type)
          @options = @field.options.merge({
            :primary => @field.type.to_s == "BSON::ObjectId",
            :native_type => @field.type.to_s
          })
        end

      end # end of field

      def fields
        @fields||=self.klass.fields.collect{|name,field|
          Field.new(field,self)
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
        self.klass.unscoped.where(:_id => id).first
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
          raise ArgumentError, "Didn't generate any scope from #{options} page:{page} per:#{per}" unless scope
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
        self.klass.db
      end

      def db_name
        self.klass.db.name
      end

      def collection
        self.klass.collection
      end

      def collection_name
        self.klass.collection_name
      end

      def collection_name=(value)
        self.klass.collection_name = value
      end

      def collections
        db.collections
      end

      def collection_names
        db.collection_names
      end

    end
  end
end
