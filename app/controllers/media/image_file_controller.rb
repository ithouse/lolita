# Handle #Media::ImageFile records and also add special _actions_.
class Media::ImageFileController < Media::ControllerFileBase

  allow :public=>[:only_image,:load_image_with_siblings],
    :all=>[
    :load_image_for_cropping,
    :destroy,:new_create,
    :get_large_picture,
    :remove_large_picture,
    :load_all_versions,
    :attributes,
    :save_attributes,
    :recreate,
    :refresh
  ]

  # Load versions that are available for image file with given :id.
  # Render :json array.
  def load_all_versions
    if picture=Media::ImageFile.find_by_id(params[:id])
      render :json=>picture.versions.to_json
    else
      render :json=>{}
    end
  end

  # Set @picture variable and render <i>only_image</i> template with no layout.
  def only_image
    if params[:id] && request.get?
      @picture=Media::ImageFile.find_by_id(params[:id])
    end
    render :layout=>false
  end

  # Call Media::ImageFile#recreate and return new information about new image.
  def recreate
    render :json=>{:id=>params[:id],:info=>Media::ImageFile.recreate(params)}
  end

  # Load images in cropping window from given :id.
  def load_image_for_cropping
    picture=Media::ImageFile.find_by_id(params[:id])
    image=picture.name.cropped if picture && picture.name && picture.name.cropped.url.to_s.size>0
    if params[:version].to_sym==:cropped && image && image.url.to_s.size>0
      render :json=>{
        :url=>image.url,
        :next=>picture.next_picture.id,
        :prev=>picture.prev_picture.id,
        :versions_info=>picture.versions_info,
        :info=>{:crop=>true,:width=>picture.width(:cropped),:height=>picture.height(:cropped)}
      }
    else
      render :json=>{}, :status=>404
    end
  end

  # Helper action, that return JSON array about next and previous image.
  def load_image_with_siblings
    if params[:id] && picture=Media::ImageFile.find_by_id(params[:id])
      render :json=>{
        :url=>picture.name.send(params[:version]).url,
        :current=>picture.url,
        :source_name=>picture.source ? picture.source.name : nil,
        :source_url=>picture.source ? url_for(picture.source.url) : nil,
        :next=>picture.next_picture.id,
        :prev=>picture.prev_picture.id,
        :caption=>picture.caption
      }
    else
      render :json=>{}, :status=>404
    end
  end

  # Render single image from :id 
  def single_image
    picture=Media::ImageFile.find_by_id(get_id)
    if request.post? && params[:parent_id] && picture && picture.pictureable_id==params[:parent_id].to_i
      render :partial=>"single_picture_view", :locals=>{:picture=>picture,:container=>params[:container]}
    else
      render :partial=>"single_picture_view", :locals=>{:picture=>nil,:container=>params[:container]}
    end
  end

  # Render image_file/attributes
  def attributes
    @picture=Media::ImageFile.find_by_id(params[:id])
    @picture=Media::ImageFile.new unless @picture
    render :layout=>false
  end

  # Save attributes for image file and render JSON array of attributes.
  def save_attributes
    if @picture=Media::ImageFile.find_by_id(params[:id])
      @picture.update_attributes(params[:picture])
      render :json=>@picture.attributes
    else
      render :json=>{:id=>params[:id]}
    end
  end

  # Render main image for current _parent_ with given <em>parent_id</em>.
  def get_large_picture
    if new? 
      media_class.find_current_files(parent_name,parent).each{|picture|
        picture.update_attributes(:main_image=>nil)
      }
    end
    Media::ImageFile.find_by_id(get_id).update_attributes(:main_image=>true)
    render :partial=>'get_image', :object=>get_params
  end

  # Remove main image for current _parent_ with given <em>parent_id</em>.
  def remove_large_picture
    Media::ImageFile.find(get_id).update_attributes(:main_image=>nil) if Media::ImageFile.exists?(get_id)
    render :text=>"<img src='/lolita/images/cms/blank_main.png' alt='blank image' />"
  end
 
end