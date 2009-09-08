class Media::ImageFileController < Media::Base

  allow :public=>[:only_image,:load_image_with_siblings],
    :all=>[
    :load_image_for_cropping,
    :destroy,:new_create,
    :get_large_picture,
    :remove_large_picture,
    :attributes,
    :save_attributes,
    :recreate
  ]

  def only_image
    if params[:id] && request.get?
      @picture=Media::ImageFile.find_by_id(params[:id])
    end
    render :layout=>false
  end

  def recreate
    render :json=>{:id=>params[:id],:info=>Media::ImageFile.recreate(params)}
  end

  def load_image_for_cropping
    picture=Media::ImageFile.find_by_id(params[:id])
    image=picture.name.cropped if picture && picture.name && picture.name.cropped.url.to_s.size>0
    if params[:version].to_sym==:cropped && image && image.url.to_s.size>0
      render :json=>{
        :url=>image.url,
        :next=>picture.next_picture.id,
        :prev=>picture.prev_picture.id,
        :versions_info=>picture.versions_info,
        :info=>{:crop=>true,:width=>image.width,:height=>image.height}
      }
    else
      render :json=>{}, :status=>404
    end
  end
  
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
  
  def single_image
    picture=Media::ImageFile.find_by_id(get_id)
    if request.post? && params[:parent_id] && picture && picture.pictureable_id==params[:parent_id].to_i
      render :partial=>"single_picture_view", :locals=>{:picture=>picture,:container=>params[:container]}
    else
      render :partial=>"single_picture_view", :locals=>{:picture=>nil,:container=>params[:container]}
    end
  end

  def save_attributes
    if @picture=Media::ImageFile.find_by_id(params[:id])
      @picture.update_attributes(params[:picture])
      render :json=>@picture.attributes
    else
      render :json=>{:id=>params[:id]}
    end
  end
  
  def get_large_picture
    if new? 
      media_class.find_current_files(parent_name,parent).each{|picture|
        picture.update_attributes(:main_image=>nil)
      }
    end
    Media::ImageFile.find_by_id(get_id).update_attributes(:main_image=>true)
    render :partial=>'get_image', :object=>get_params
  end
 
  def remove_large_picture
    Media::ImageFile.find(get_id).update_attributes(:main_image=>nil) if Media::ImageFile.exists?(get_id)
    render :text=>"<img src='/lolita/images/cms/blank_main.png' alt='blank image' />"
  end
 
end