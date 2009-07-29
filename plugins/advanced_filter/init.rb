# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'advanced_filter'
require 'advanced_filter_helper'
require 'models/advanced_filter'
require 'models/advanced_filter_field'
require 'models/custom_filter'
ActiveRecord::Base.send(:include, ITHouse::Filters::AdvancedFilter)
ActionController::Base.send(:include, ITHouse::Filters::AdvancedFilterController)
ActionView::Base.send(:include, ITHouse::Filters::AdvancedFilterHelper)
#ActionView::Base.send :include, SymetrieCom::Acts::BetterNestedSetHelper
