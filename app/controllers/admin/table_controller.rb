class Admin::TableController < Managed
  allow Admin::Role.admin
  access_control :exclude=>[:destroy,:edit,:new], :redirect_to=>{:action=>:list}
  def index
    redirect_to :action=>'list', :all=>params
  end
  
  def save
    begin
      table=nil
      if params[:object] && params[:object].respond_to?("each")
        params[:object].each{|key,value|
          table=Admin::Table.find_by_name(key)
          value=value.size>0 ? value : nil
          table.human_name=value
          table.save
        }
      end
      flash[:notice]="Veiksmīgi saglabāts"
    rescue
      errors={}
      if table && !table.errors.empty?
        table.errors.each{|attr,msg|
          errors[attr]=msg
        }
      else
        errors['Neizdevās saglabāt - ']=[" nezināma kļūda",nil]
      end
      flash[:error]=errors
    end
    redirect_to :action=>'list',:is_ajax=>true
  end
  
  private

  def before_list
    unless params[:paging]
      Admin::Table.collect_modules
    end
  end
  
  def config
    {
      :list=>{
        :sort_column=>'name',
        :sort_direction=>'asc',
        :list_intro=>"Sadaļu nosaukumu pārdēvēšana saprotamākos nosaukumos."
      }
    }
  end
  
end
