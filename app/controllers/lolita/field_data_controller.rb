class Lolita::FieldDataController < ApplicationController
  include Lolita::Controllers::UserHelpers

  before_filter :authenticate_lolita_user!
  before_filter :find_field

  def array_polymorphic
    klass = params[:class].camelize.constantize
    data_collection = @field.polymorphic_association_values(:klass => klass)
    @id = params[:id].to_s.to_i
    @collection = [[]]+data_collection
    render_component(*@field.build(:state => :options_for_select, :collection => @collection, :id => @id))
  end

  def find_field
    @field = params[:field_class].camelize.constantize.lolita.tabs.fields.detect{|field|
      field.name.to_s == params[:name].to_s
    }
  end
end