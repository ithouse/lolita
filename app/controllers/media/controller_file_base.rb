# All file kind media classes are subclasses of this class.
# Define main _actions_ methods for these classes.
class Media::ControllerFileBase < Media::ControllerBase
  #FIXME JF:nācās ielikt protect_from_forgery exceptu, jo nekādīgi negribēja ņemt padoto auth tokenu
  protect_from_forgery :except=>[:new_create]

  # Create new media file and DB record from received params.
  # Render message and status code.
  # ====Example
  #  params #=> {:media=>"image_file", :parent_id=>1, :parent=>"cms/blog", 'Filedata'=> FileData}
  # If :single passed then all other files will be destroyed.
  # If :tempid is greater then 0 than create #Media::MediaFileTempMemory record.
  # If file without name is create then something goes wrong and file will be destroyed.
  def new_create
    params[params[:media].to_sym]={:name=>params['Filedata']}
    if file
      @file=media_class.respond_to?(:new_from_params) ? media_class.new_from_params(params) : media_class.new_file(params)
      begin
        @file.save!
        unless @file.name
          @file.destroy()
          @error_msg="#{t(:"media.bad type")}!"
        else
          media_class.delete_all_files(parent,new?,@file) if single?
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

  # Destroy files from received id or ids for current media class.
  # Accepts Hash with :thumb, where all records with id and state different from _normla_ will be destroyed.
  # Or :thumb might be Array of ids and resond all files.
  # ====Example
  #    params #=> {:media=>"image_file", :thumb=>{:2=>"normal",:3=>"delete", :4=>"something"}
  #    Media::ImageFile records with ids 3 and 4 will be destroyed
  #    params #=> {:media=>"simple_file", :thum=>[1,2]
  #    Media::SimpleFile records with ids 1 and 2 will be destroyed.
  def destroy
    ids=[params[:id]]+if params[:thumb]
      if params[:thumb].is_a?(Hash)
        params[:thumb]=params[:thumb].delete_if{|k,v| k.to_s=="normal"}
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

  # Just respond all files.
  def refresh
    respond_files
  end

  # Set @files and render current media show.html
  def show
    @files=media_class.find_current_files()
  end

  # Respond configuration for using in JS.
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
