class Lolita::FieldDataController < ApplicationController
  include Lolita::Controllers::AuthenticationHelpers

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
    klass = params[:field_class].camelize.constantize
    field = klass.lolita.tabs.fields.detect{|field| field.name.to_s == params[:field_name]}
    data = if field
      (field.search || field.create_search(true)).run(params[:term],request).map do |record|
        {
          :id => record.id,
          :value => record.send(field.current_text_method(field.association.klass)),
          :name => "#{params[:field_class].underscore}[#{params[:field_name].singularize}_ids][]",
          :delete_link => I18n.t("lolita.shared.delete").to_s.downcase
        }
      end
    end
    render :json => data || {}
	end
end
