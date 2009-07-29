module ITHouse
  module Filters
  module AdvancedFilter
    class FilterField < ActiveRecord::Base
      set_table_name "advanced_filter_fields"
      belongs_to :filter
      serialize  :values
    end
  end
  end
end
