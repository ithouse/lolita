module Extensions::PictureHelper
  def draw_draggable_pictures options={},count_in_row=1
    if options[:pictures]
      pictures_group=[]
      for picture in options[:pictures].compact
        picture_url=picture.picture.thumb.url
        if File.exists?("#{RAILS_ROOT}/public/#{picture_url}")
          pictures_group<<draggable_picture(picture,picture_url,options)
          if pictures_group.size>=count_in_row
            yield pictures_group
            pictures_group=[]
          end
        end
      end
      yield pictures_group
    end 
  end
  
  def draggable_picture picture,url,options={}
    result=""
    result+=image_tag url, :alt=>picture.alt, :title=>picture.title, :id=>"normalpicturesthumb_#{picture.id}", :class=>"normal-picture-thumb",:onclick=>"ITH.Picture.check_state(event,this,#{picture.id})"
    result+=%(<input type="hidden" name="thumb[normal]" value="#{picture.id}" id="normalpicturesthumb_#{picture.id}_hidden" />)
    result+=draggable_picture_tools picture
    unless options[:read_only] && options[:main_image] 
      result+=yui_draggable_element("normalpicturesthumb_#{picture.id}",
        :group=>"pictures",
        :update=>{:success => 'picture-photos-main', :failure => 'status'},
        :url=>{:controller=>'/picture', :action=>'get_large_picture',:parent=>options[:parent],:parent_id=>options[:parent_id],:tempid=>options[:tempid],:pdf=>options[:pdf],:id=>picture.id}
      )
      #result+=yui_drop_receiving_element('picture-photos-main','pictures')
    end
    result
  end
  def draggable_picture_tools image
    json={:id=>image.id}.to_json
    edit_image='<span title="'+t(:"picture.change attributes")+'" class="picture-edit-tool picture-tool-common"></span>'
    images='<span title="'+t(:"picture.all sizes")+'" class="picture-all-sizes-tool picture-tool-common"></span>'
    #comment_image='<span title="Aplūkot komentārus" class="picture-comment-tool picture-tool-common"></span>'+"<span class='image-comments-count'>(#{image.comments.size})</span>" if image.respond_to?("comments")
    content_tag("span",
      content_tag("span",edit_image,:class=>"ith-media-image-tool",:onclick=>"ITH.Picture.show_attributes_dialog(#{json})")+"<br/>"+
      content_tag("span",images,:class=>"ith-media-image-tool",:onclick=>"ITH.PictureVersions.load(#{json})"),
      :class=>"ith-media-image-tools")
  end
  
  def default_url
    url={:controller=>params[:controller],:action=>params[:action]}
    params.each{|key,value|
      key=key.to_sym
      url[key]=value unless url.include?(key)
    }
    url
  end
 
  def get_all_image_types  picture_id
    if Picture.exists?(picture_id)
      picture=Picture.find(picture_id)
    end
    if picture
      {
        'Mazā (166x111)'=>get_image_thumb(picture),
        'Lielā (343x245)'=>get_image_large(picture),
        'Aplūkošanai (486x336)'=>get_image_viewer(picture),
        'Normāla'=>get_image_normal(picture)
      }
    else
      {}
    end
  end
  def is_picture? picture
    if !picture.nil? && picture.is_a?(Picture) && !picture.picture.nil?
      true
    else
      false
    end
  end
  
  def get_main_image (parent="", parent_id=0,temp=false)
    if temp
      session_parent_id = ("t"+parent_id.to_s).to_sym
      if session[:uploaded_pictures]
        picture=Picture.main.by_ids(session[:uploaded_pictures][session_parent_id] || []).first
      end
    else
      picture=Picture.main.by_parent(parent,parent_id).first
    end
    return picture
  end
  
  def get_all_parent_pictures (parent="", parent_id=0)
    begin
      session_parent_id = ("t"+parent_id.to_s).to_sym
      if session[:uploaded_pictures] && session[:uploaded_pictures][session_parent_id]
        pictures=Picture.positioned("asc").by_ids(session[:uploaded_pictures][session_parent_id] || [])
      else
        pictures=Picture.positioned("asc").by_parent(parent,parent_id)
      end
      yield pictures
    rescue
      yield nil
    end
  end
end
