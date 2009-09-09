class Media::FileBase < Media::Base
  #FIXME JF:nācās ielikt protect_from_forgery exceptu, jo nekādīgi negribēja ņemt padoto auth tokenu
  protect_from_forgery :except=>[:new_create]

  def new_create
    params[params[:media].to_sym]={:name=>params['Filedata']}
    if file
      media_class.delete_all_files(parent,new?) if single?
      @file=media_class.respond_to?(:new_from_params) ? media_class.new_from_params(params) : media_class.new_file(params)
      begin
        @file.save!
        unless @file.name
          @file.destroy()
          @error_msg="#{t(:"media.bad type")}!"
        else
          media_class.add_to_memory(parent,@file.id) if new?
        end
        render :text=>"OK"
      rescue
        @error_msg="#{t(:"media.bad type or file")}!"
        render :text=>@error_msg, :status=>404
      end
    else
      render :text=>"File not found!", :status=>404
    end
  end
  
  def destroy
    ids=[params[:id]]+if params[:thumb]
      if params[:thumb].is_a?(Hash)
        params[:thumb].values
      else
        params[:thumb]
      end
    else
      []
    end
    ids.compact.each{|id|
      media_class.delete_file(id)
    }
    respond_files
  end
  
  def refresh
    respond_files
  end
  
  def show
    @files=media_class.find_current_files()
  end

  def respond_configuration
    get_params
  end
  
  private
  
  def respond_files
    render :partial=>"/media/#{params[:media]}/thumb_list", :object=>get_params
  end

  def file
    params[params[:media].to_sym] ? params[params[:media].to_sym][:name] : nil
  end
  
  def get_params
    {:files=>media_class.find_current_files(parent_name,parent),:single=>single?, :parent=>parent_name,:parent_id=>parent,:tempid=>new?,:error_msg=>@error_msg,:media=>params[:media]}
  end
  
end
