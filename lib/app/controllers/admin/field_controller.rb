class Admin::FieldController < Managed
  allow Admin::Role.admin
  access_control :excluded=>[:edit,:new,:update,:destroy], :redirect_to=>{:action=>:list}
  
  def show_fields
    if params[:table_id] && Admin::Table.exists?(params[:table_id])
      table=Admin::Table.find(params[:table_id])
      real_fields=table.name.camelize.constantize.column_names
      existing_fields=Admin::Field.by_table(table.name).collect{|field| field.name}
      real_fields.each{|real_field|
        unless existing_fields.include?(real_field)
          existing_fields<<real_field
          Admin::Field.create(:name=>real_field,:table=>table.name)
        end
      }
      (existing_fields-real_fields).each{|removeable_field|
        Admin::Field.find(:first,:conditions=>["name=? AND `table`=?",removeable_field,table.name]).destroy
      }
      @fields=Admin::Field.by_table(table.name)
    end 
    render :partial=>"table_list"
  end

  def switch_language
    if params[:fields_locale]
      Globalize::Locale.set("#{base_lang.short_name}-#{base_lang.short_name=='en' ? "US" : base_lang.short_name.upcase}")
    end
  end
  
  def save
    if params[:table_id] && table=Admin::Table.find_by_id(params[:table_id])
      if params[:object] && params[:object].is_a?(Hash)
        params[:object].each{|field_id,h_name|
          field=Admin::Field.find_by_id(field_id)
          field.update_attributes(:human_name=>h_name.to_s.size>0 ? h_name : nil) if field && h_name.to_s.size>0
        }
        flash[:notice]="Veiksmīgi saglabāts"
      end
      @fields=Admin::Field.by_table(table.name)
    end
    render :partial=>"table_list"
  end
  private

  def before_list
    unless params[:paging]
      Admin::Table.collect_modules
    end
  end

  def config
    {
      :object=>"Admin::Table",
      :list=>{
        :sort_column=>'human_name',
        :sort_direction=>'asc',
        :sortable=>true,
        :intro=>"Tabulu lauku nosaukumu normalizēšana."
      }
    }
  end
  
end
