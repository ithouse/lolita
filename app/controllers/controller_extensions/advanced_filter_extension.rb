module ControllerExtensions::AdvancedFilterExtension
  def save_filter
    object=params[:controller].camelize.constantize
    if filter=object.save_advanced_filter(params[:advanced_filter])
      flash[:notice]="Filtrs saglabāts"
      redirect_to :action=>params[:filter_action], :advanced_filter=>filter.id, :is_ajax=>true
    end
  end

  def destroy_advanced_filter
    @module.destroy_advanced_filter(params[:id])
    flash[:notice]="Filtrs izdzēsts"
    redirect_to :action=>params[:filter_action], :is_ajax=>true
  end
  #reālā filtra ielāde notiek plugin helperī,
  #tur list_template forma izsauc advanced_filter, kas renderē advanced_filter partialu,
  #tas izsauc advanced_filter funkcijas, kas ģenerē filtru
  #Skatīt - _advanced_filter.html.erb
  def load_filter
    @current_filter=get_id
    render :partial=>"/cms/list_template"
  end
  #fields - tikai iekķeksētie, array ar vērtību nosaukums
  #conditions visi key=nosaukums, value=same,not_same uttt
  #values key=nosaukums vērtība masīvs ar vērtībām
  #is_visible[]
  def reset_filter
    
  end
  
  def apply_filter
    
  end
end
