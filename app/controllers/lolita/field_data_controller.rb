class Lolita::FieldDataController < ApplicationController
  include Lolita::Controllers::UserHelpers

  before_filter :authenticate_lolita_user!
  before_filter :find_field, :except => [:autocomplete_field]

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

	def autocomplete_field
		model = params[:class].singularize.camelize.constantize
		column = model.lolita.tabs.first.fields.first.name.to_sym
		data = model.where(model.arel_table[column].matches("%#{params[:term]}%")).map do |record| 
			{:id => record.id, 
			 :value => record.send(column), 
			 :name => "#{params[:field_class].downcase}[#{params[:class].singularize}_ids][]",
			 :delete_link => I18n.t("lolita.shared.delete")}
		end
		render :json => data
	end
end
