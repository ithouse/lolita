class Admin::ConfigurationController < Managed
  allow Admin::Role.admin
  def index
    redirect_to :action=>'list'
  end

  def save
    begin
      configuration=nil
      if params[:object] && params[:object].respond_to?("each")
        params[:object].each{|key,value|
          configuration=Admin::Configuration.find_by_name(key)
          if configuration
            value=value.size>0 ? value : nil
            configuration.value=value
            configuration.save!
          end
        }
      end
      flash[:notice]=t(:"flash.saved")
    rescue
      errors={}
      if configuration && !configuration.errors.empty?
        configuration.errors.each{|attr,msg|
          errors[attr]=msg
        }
      else
        errors["#{t(:"errors.cant_save")} - "]=[" #{t(:"errors.unknown_error")}",nil]
      end
      flash[:error]=errors
    end
    redirect_to({:action=>'list',:is_ajax=>true})
  end
  private
  
  def config
    {
      :tabs=>[
        {:type=>:content,:fields=>:default,:in_form=>true,:opened=>true}
      ],
      :list=>{
        :sort_column=>'name',
        :sort_direction=>'asc'
      },
      :fields=>[
        {:type=>:text,:field=>:name, :html=>{:maxlength=>255}},
        {:type=>:text,:field=>:title,:html=>{:maxlength=>255}}
      ]
    }
  end
end
