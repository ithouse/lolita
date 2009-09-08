module Media::ImageFileHelper

  def image_extensions
    UploadColumn.image_extensions.collect{|t| "*.#{t};"}.join
  end

  #End of managed needed functions
  def draw_draggable_pictures options={},count_in_row=1
    if options[:files]
      pictures_group=[]
      for picture in options[:files].compact
        picture_url=picture.name.thumb.url
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
    result+=image_tag url, :alt=>picture.alt, :title=>picture.title, :id=>"normalpicturesthumb_#{picture.id}", :class=>"normal-picture-thumb",:onclick=>"ITH.ImageFile.check_state(event,this,#{picture.id})"
    result+=%(<input type="hidden" name="thumb[normal]" value="#{picture.id}" id="normalpicturesthumb_#{picture.id}_hidden" />)
    result+=draggable_picture_tools picture
    unless options[:read_only] && options[:main_image]
      result+=yui_draggable_element("normalpicturesthumb_#{picture.id}",
        :group=>"pictures",
        :update=>{:success => 'picture-photos-main', :failure => 'status'},
        :url=>{:controller=>'/media/image_file', :action=>'get_large_picture', :authenticity_token => form_authenticity_token,:id=>picture.id}.merge(options)
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
      content_tag("span",edit_image,:class=>"ith-media-image-tool",:onclick=>"ITH.ImageFile.show_attributes_dialog(#{json})")+"<br/>"+
      content_tag("span",images,:class=>"ith-media-image-tool",:onclick=>"ITH.ImageFileVersions.load(#{json})"),
      :class=>"ith-media-image-tools")
  end

  def get_main_image (parent="", parent_id=0,temp=false)
    if temp
      Media::ImageFile.main.by_ids(Media::ImageFile.find_in_memory(parent_id).collect{|t| t.id}).first
    else
      Media::ImageFile.main.by_parent(parent,parent_id).first
    end
  end
end
