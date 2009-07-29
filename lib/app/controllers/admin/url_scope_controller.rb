class Admin::UrlScopeController < Managed
  allow Admin::Role.admin
  def index
    redirect_to :action=>'list', :all=>params
  end
  
  def save
    begin
      urlsc=nil
      if params[:object] && params[:object].respond_to?("each")
        params[:object].each{|key,value|
          urlsc=Admin::UrlScope.find_by_name(key)
          if urlsc
            value=value.size>0 ? value : nil
            urlsc.scope=value
            urlsc.save
          end
        }
      end
      flash[:notice]="Veiksmīgi saglabāts"
    rescue
      errors={}
      if urlsc && !urlsc.errors.empty?
        urlsc.errors.each{|attr,msg|
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
  
  def config
    {
      :list=>{
        :sort_column=>"name",
        :sort_direction=>"asc",
        :intro=>"Šie nosaukumi tiek izmantoti publiskajā daļā veidojot adreses.<br/>
                    Ja /cms/text_page = raksts,<br/> tad
                    <code>www.example.lv/cms/text_page/1</code> =>
                    <code>www.example.lv/raksts/1</code>
        "
      },
      :fields=>[
        {:type=>'text',:field=>'name',:title=>'Orģinālais nosaukums',:maxlength=>255},
        {:type=>'text',:field=>'scope',:title=>'Redzamais nosaukums',:maxlength=>255}
      ]
    }
  end
 
end
