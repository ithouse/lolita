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
        attr_reader :association

        def initialize(assoc_object)
          @association = assoc_object
        end

        def method_missing(method, *args, &block)
          @association.send(method,*args,&block)
        end

        def key
          @association.key
        end

        def macro
          convertator = {
            :references_many => :many, :references_one => :one, :referenced_in => :one, 
            :references_and_referenced_in_many => :many, :embeds_one => :one, :embeds_many => :many
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
            @associations[name.to_sym] = Association.new(association)
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
          Association.new(orm_association)
        end
      end

      # Each field from ORM is changed to this class instance.
      class Field
        attr_reader :field, :name,:options, :type
        def initialize(column,adapter)
          @field = column
          raise ArgumentError, "Cannot initialize adapter field for nil" unless @field
          @adapter = adapter
          set_attributes
        end

        def association
          @association ||= @adapter.associations.detect{|name,association|
            association.key.to_s == @name.to_s
          }
        end

        def method_missing(method,*args,&block)
          @field.send(method,*args,&block)
        end

        def primary?
          !!self.options[:primary]
        end

        private

        def set_attributes
          @name = @field.name
          @type = @field.type.to_s.underscore
          @options = @field.options.merge({
            :primary => @field.name.to_s == "_id",
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
        collection.name
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
