# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'advanced_filter'
require 'advanced_filter_helper'
require 'models/advanced_filter'
require 'models/advanced_filter_field'
require 'models/custom_filter'
ActiveRecord::Base.send(:include, Lolita::Filters::AdvancedFilter)
ActionController::Base.send(:include, Lolita::Filters::AdvancedFilterController)
ActionView::Base.send(:include, Lolita::Filters::AdvancedFilterHelper)
#ActionView::Base.send :include, SymetrieCom::Acts::BetterNestedSetHelper
