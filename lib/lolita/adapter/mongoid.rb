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
        klass.relations
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
        macro=association.macro
        case macro
        when :references_many
          :many
        when :references_and_referenced_in_many
          :many
        when :referenced_in
          :one
        when :references_one
          :one
        when :embeds_one
          :one
        when :embeds_many
          :many
        end
      end

      def association_class_name(association)
        association.class_name
      end

      def fields
        @fields||=self.klass.fields.collect{|name,field|
          name[0] == '_' ? nil : field_to_hash(name,field)
        }.compact
        @fields
      end

      def find_by_id(id)
        self.klass.unscoped.where(:_id=>id).first
      end

      def find *args
        self.klass.unscoped.find(*args)
      end

      def paginate(options={})
        self.klass.paginate(options)
      end

      def filter(opt={})
        conditions = {}
        unless opt.empty?
          opt.each_pair do |k,v|
            field = klass.fields.detect{|name,f| name == k.to_s}
            if field
              conditions[k] = v
            elsif association = associations[k.to_s]
              case association_macro(association)
              when :many
                conditions[:"#{klass.reflect_on_association(k).key}".in] = [v]
              when :one
                conditions[klass.reflect_on_association(k).foreign_key] = v
              end
            end
          end
          return self.klass.unscoped.where(conditions)
        end
        self
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