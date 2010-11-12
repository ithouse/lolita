module Lolita
  module Adapter
    module Mongoid
      include Lolita::Adapter::AbstractAdapter
      
      def fields
        self.dbi.klass.fields.collect{|name,field|
          field_to_hash(name,field)
        }
      end

      def paginate(options={})
        self.dbi.klass.paginate(options)
      end

      def db
        self.dbi.klass.db
      end

      def db_name
        self.dbi.klass.db.name
      end
      
      def collection
        self.dbi.klass.collection
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

      def primary_field
        {
          :name=>"id",
          :type=>BSON::ObjectId,
          :title=>"ID",
          :options=>{:primary=>true}
        }
      end

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