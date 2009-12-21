module Lolita
  module Filters
    module AdvancedFilter
      class Filter < ActiveRecord::Base
        set_table_name "advanced_filters"
        has_many  :filter_fields, :foreign_key=>"advanced_filter_id",:dependent=>:destroy
      end
    end
  end
end
