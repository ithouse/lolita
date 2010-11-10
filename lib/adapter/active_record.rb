
module Lolita
  module Adapter
    module ActiveRecord
      include Lolita::Adapter::AbstractAdapter
      def fields
        self.dbi.klass.columns.collect{|column|
          field_to_hash(column)
        }
      end

      def paginate(opt={})
        options=opt.dup
        options[:limit]=options[:per_page]
        options[:offset]=(options[:page]-1)*options[:per_page]
        options.delete(:per_page)
        options.delete(:page)
        self.dbi.klass.find(:all,opt)
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