class MediaBase < ApplicationController
  #FIXME JF:nācās ielikt protect_from_forgery exceptu, jo nekādīgi negribēja ņemt padoto auth tokenu
  protect_from_forgery :except=>[:new_create]

  def new_create
    params[params[:media].to_sym]={:name=>params['Filedata']}
    check_session
    if file
      clear_for_single_file if single?
      @file=media_class.new_from_params(params)
      begin
        @file.save!
        unless @file.name
          @file.destroy()
          @error_msg="#{t(:"media.bad type")}!"
        else
          add_to_session @file.id if new?
        end
        render :text=>"OK"
      rescue
        @error_msg="#{t(:"media.bad type or file")}!"
      end
    else
      render :text=>"File not found!", :status=>404
    end
  end
  
  def create
    @error_msg=""
    check_session
    if file
      clear_for_single_file if single?
      @file=media_class.new_from_params(params)
      begin
        @file.save!
        unless @file.name
          @file.destroy()
          @error_msg="#{t(:"media.bad type")}!"
        else
          add_to_session @file.id if new?
        end
      rescue
        @error_msg="#{t(:"media.bad type or file")}!"
      end
    end
    respond_files
  end

  def clear_for_single_file
    if new?
      session[session_name][session_parent_id].each{|id| delete_file(id)}
    else
      media_class.by_parent(parent_name,parent).each{|file| file.destroy}
    end
  end

  def destroy
    if params[:thumb]
      params[:thumb].each{|id|
        delete_file id.to_i
        remove_from_session id.to_i
      }
    end

    if params[:id]
      delete_file params[:id].to_i
      remove_from_session params[:id].to_i
    end
    respond_files
  end
  
  def refresh
    respond_files
  end
  
  def show
    @files=files
  end

  def respond_configuration
    get_params
  end
  
  private
  
  def respond_files
    render :partial=>"/#{params[:media]}/thumb_list", :object=>get_params
  end

  def file
    params[params[:media].to_sym] ? params[params[:media].to_sym][:name] : nil
  end
  
  def session_files
    if !session[session_name][session_parent_id]
      session[session_name][session_parent_id]=[]
    else
      session[session_name][session_parent_id]
    end
  end
  
  def get_params
    {:files=>files,:single=>single?, :parent=>parent_name,:parent_id=>parent,:tempid=>new?,:error_msg=>@error_msg,:media=>params[:media]}
  end
  
  def id (splitter='_',part=1)
    ids=params[:id].split(/#{splitter}/)
    if ids.size>part
      ids[part]
    else
      params[:id].to_id>0 ? params[:id] : nil
    end
  end
  
  def check_session
    session[session_name]={} unless session[session_name]
  end
  # End of params

  def session_parent_id
    ("t"+parent.to_s).to_sym
  end

  def delete_file (id)
    file=media_class.find_by_id(id)
    file.destroy if file
  end

  def add_to_session(id)
    session_files << id
  end

  def remove_from_session (id)
    session_files.delete(id) if new?
  end
  
  def files   
    if existing?
      media_class.by_parent(parent_name,parent)
    else
      media_class.find(session_files)
    end
  end

  def session_name
    "uploaded_#{params[:media].pluralize}".to_sym
  end
  def media_class
    params[:media].to_sym==:file ? FileItem : params[:media].camelize.constantize
  end

  def new?
    params[:tempid].to_b
  end
  def existing?
    !new?
  end
  def single?
    params[:single].to_b
  end
  def many?
    !single?
  end
  def parent
    params[:parent_id].to_i
  end
  def parent?
    params[:parent_id] && params[:parent_id].to_i>0
  end
  def parent_name
    params[:parent]||""
  end
end
