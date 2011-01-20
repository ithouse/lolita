module Lolita
  module Adapter
    class ActiveRecord
      include Lolita::Adapter::AbstractAdapter
      
      attr_reader :dbi, :klass
      def initialize(dbi)
        @dbi=dbi
        @klass=dbi.klass
      end

      def associations
        klass.reflections
      end

      # Same as in mongoid
      def associations_klass_names
        names=[]
        associations.each{|name,association|
          names << association.class_name
        }
        names
      end

      def reflect_on_association(name)
        klass.reflect_on_association(name)
      end

      def association_macro(association)
        type=association.macro
        case type
        when :has_many
          :many
        when :has_one
          :one
        when :belongs_to
          :one
        when :has_and_belongs_to_many
          :many
        end
      end

      def association_class_name(association)
        association.class_name
      end

      def fields
        @fields||=self.klass.columns.collect{|column|
          field_to_hash(column)
        }.reject{|column|
          column[:options][:primary]
        }
        @fields
      end

      def paginate(opt={})
        self.klass.paginate(opt)
#        options=opt.dup
#        options[:limit]=options[:per_page]
#        options[:offset]=(options[:page]-1)*options[:per_page]
#        options.delete(:per_page)
#        options.delete(:page)
#        self.klass.find(:all,options)
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

      def collections
        self.klass #FIXME not  realy same as in mongoid
      end

      def collection_names
        self.klass.connection.select_all("show tables from #{db_name}").map{|r| r.values.first}
      end

      private

      def field_to_hash(column)
        {
          :name=>column.name,
          :type=>column.type.to_s,
          :title=>column.name.to_s.humanize,
          :options=>{
            :primary=>column.primary
          }
        }
      end
    end
  end
end