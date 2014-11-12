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
          @association.foreign_key
        end

        def through?
          false
        end

        def through
          nil
        end

        def native_macro
          @association.macro
        end

        def macro
          convertator = {
            :has_many => :many, :belongs_to => :one, :has_one => :one,
            :has_and_belongs_to_many => :many_to_many, :embeds_one => :one, :embeds_many => :many
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

        def method_missing(method,*args,&block)
          @field.send(method,*args,&block)
        end

        def primary?
          !!self.options[:primary] || @field.type.to_s =~ /ObjectId/
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

      include Lolita::Adapter::CommonHelper

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

      def search(query, options = {})
        unless query.blank?
          content_fields = @dbi.fields.map{|field|
            if field.type!="string" || field.name.match(/^_/)
              nil
            else
              field.name.to_sym
            end
          }.compact
          if options[:fields] && options[:fields].any?
            content_fields = content_fields & options[:fields]
          end
          content_fields = content_fields.slice(0..3)

          where_hash = {}
          content_fields.each do |field|
            where_hash[field] = /#{Regexp.escape(query.to_s)}/
          end
          klass.where(where_hash)
        else
          klass.where(nil)
        end
      end

      #FIXME
      def map_reduce_search(content_fields,query)
        keys = "[" + @dbi.fields.map{|f|
          f.primary? || f.name.to_s.match(/^_/)  ? nil : "'#{f.name}'"
        }.compact.join(",").to_s + "]"
        content_keys = "[" + content_fields.map{|f| "'#{f.name}'"}.join(",").to_s + "]"
        result_obj = @dbi.fields.map{|f|
          f.name.to_s.match(/^_/) ? nil : "'#{f.name}': false"
        }.compact.join(",")
        result_obj = "{#{result_obj}}"
        map = %^
          function(){
            var doc = #{result_obj};
            var do_emit = false;
            for(var k in #{content_keys}){
              var c_val = this[k];
              if(c_val && c_val.match(/#{Regexp.escape(query)}/i)){
                do_emit = true;
                break;
              };
            };
            if(true){
              #{keys}.forEach(function(k){
                doc[k] = this.name;
              })
              emit(this.id,doc);
            };
          };
        ^
        reduce = %^
          function(key,values){

            return values[values.length-1];
          };
        ^
        self.collection.map_reduce(map,reduce, {:out => "custom_mr", :query => {}})
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

      def nested_attributes_options
        self.klass.relations
      end

      def order_method
        :order_by
      end
    end
  end
end
