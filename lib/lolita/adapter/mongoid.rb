module Lolita
  module Adapter
    class Mongoid
      include Lolita::Adapter::AbstractAdapter

      attr_reader :dbi, :klass
      def initialize(dbi)
        @dbi=dbi
        @klass=dbi.klass
      end

      def associations
        klass.associations
      end

      def associations_class_names
        names=[]
        associations.each{|name,association|
          names<<association.class_name
        }
        names
      end

      def reflect_on_association(name)
        klass.reflect_on_association(name)
      end

      def association_macro(association)
        macro=association.association.macro
        case macro
        when :references_many
          :many
        when :referenced_in
          :one
        when :embeds_one
          :one
        when :embeds_many
          :many
        when :references_one
          :one
        end
      end

      def fields
        @fields||=self.klass.fields.collect{|name,field|
          field_to_hash(name,field)
        }
        @fields
      end

      def paginate(options={})
        self.klass.paginate(options)
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

      private

      def field_to_hash(name,field)
        {
          :name=>name,
          :type=>field.type.to_s,
          :title=>name.to_s.humanize,
          :options=>field.options.merge({
            :primary=>name.to_s=="_id"
          })
        }
      end
    end
  end
end