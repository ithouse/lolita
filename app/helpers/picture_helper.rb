module PictureHelper
  
  def first_picture(parent,version=nil,attributes={})
    if parent
      picture=Picture.by_parent(parent.class.to_s,parent.id).main.first
      picture=Picture.by_parent(parent.class.to_s, parent.id).positioned("asc").first unless picture
    end
    if picture
      attributes[:alt]=picture.alt unless attributes.has_key?(:alt)
      attributes[:title]=picture.title unless attributes.has_key?(:title)
      picture_tag_from(picture,version,attributes)
    else
      nil
    end
  end

  def picture_tag_from picture, version=nil, attributes={}
    image_url=picture.url(version) if picture
    if image_url && File.exist?(RAILS_ROOT+"/public"+image_url)
      image_tag(image_url,attributes)
    else
      nil
    end
  end
end
