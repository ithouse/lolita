class LocationController < Managed
  allow
  
  def create
    handle_params
    @object=Location.new(params[:object])
    if request.post?
      begin
        Location.transaction do
          @object.save!
          @object.name="Map #{@object.id}" unless @object.name.to_s>0
          @object.mappable_id=@object.id
          @object.mappable_type="Location"
          @object.save!
          redirect_to :action=>:list, :is_ajax=>params[:is_ajax]
        end
      rescue
        render :layout=>params[:is_ajax] ? false : "cms/default"
      end
    else
      render :layout=>params[:is_ajax] ? false : "cms/default"
    end
  end
  
  def update
    handle_params
    @object=Location.find_by_id(get_id)
    unless @object
      redirect_to :action=>:create
      return
    end
    begin
      if request.post? && @object.update_attributes!(params[:object])
        redirect_to :action=>:list, :is_ajax=>params[:is_ajax]
      else
        render :action=>"create", :layout=>params[:is_ajax] ? false : "cms/default"
      end
    rescue
      render :action=>"create", :layout=>params[:is_ajax] ? false : "cms/default"
    end
  end
  
  def config
    {
      :sort_column=>"name",
      :sort_direction=>"asc",
      :map=>true,
      :list_intro=>"Karšu pārvaldīšana, lai ievietotu karti lapā iekopējiet kartes <b>saiti</b>.",
      :fields=>{   
        1=>{:type=>'text',:title=>'Nosaukums',:field=>'name',:maxlength=>255},
        2=>{:type=>'text',:title=>'Platums',:field=>'width',:maxlength=>5},
        3=>{:type=>'text',:title=>'Augstums',:field=>'height',:maxlength=>5},
        4=>{:type=>"textarea",:title=>"Informācija",:field=>"info"}
      }
    }
  end

end
