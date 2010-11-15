module Lolita
  module Adapter
    module Mongoid
      include Lolita::Adapter::AbstractAdapter
      
      def fields
        self.klass.fields.collect{|name,field|
          field_to_hash(name,field)
        }
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
          :type=>field.type,
          :title=>name.to_s.humanize,
          :options=>{
            :primary=>name.to_s=="_id"
          }
        }
      end
    end
  end
end