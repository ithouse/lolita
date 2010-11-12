module Lolita
  module Adapter
    module ActiveRecord
      include Lolita::Adapter::AbstractAdapter
      def fields
        self.dbi.klass.columns.collect{|column|
          field_to_hash(column)
        }.reject{|column|
          column[:options][:primary]
        }
      end

      def paginate(opt={})
        options=opt.dup
        options[:limit]=options[:per_page]
        options[:offset]=(options[:page]-1)*options[:per_page]
        options.delete(:per_page)
        options.delete(:page)
        self.dbi.klass.find(:all,options)
      end

      def db
        self.dbi.klass.connection
      end

      def db_name
        db.current_database
      end

      def collection
        self.dbi.klass #FIXME not realy same as in mongoid
      end

      def collection_name
        self.dbi.klass.table_name
      end

      def collections
        self.dbi.klass #FIXME not  realy same as in mongoid
      end

      def collection_names
        self.klass.connection.select_all("show tables from #{db_name}").map{|r| r.values.first}
      end

      private

      def field_to_hash(column)
        {
          :name=>column.name,
          :type=>column.type.to_s.camelize.constantize,
          :title=>column.name.to_s.humanize,
          :options=>{
            :primary=>column.primary
          }
        }
      end
    end
  end
end