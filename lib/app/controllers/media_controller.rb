class MediaController < ApplicationController
  allow :all=>[:all_images,:all_files,:open_attributes,:save_attributes,:destroy,:detail]
  def all_images
    @images=find_all_images
    respond "images"
  end
  
  def all_files
    @files=find_all_files
    respond "files"
  end
  
  def open_attributes
    case params[:media]
    when "images"
      @image=Picture.find_by_id(params[:id])
    when "files"
      @file=FileItem.find_by_id(params[:id])
    end
    render :partial=>"update_#{params[:media]}", :object=>{:id=>params[:id]},:layout=>false
  end
  
  def save_attributes
    case params[:media]
    when "images"
      object=Picture.find_by_id(params[:id])
      updateable=params[:image]
    when "files"
      object=FileItem.find_by_id(params[:id])
      updateable=params[:file]
    end
    if object && object.update_attributes(updateable)
      render :json=>[object.attributes]
    else
      render :text=>"Neizdevās saglabāt", :status=>400
    end
  end
  
  def destroy
    case params[:media]
    when "images"
      object=Picture.find_by_id(params[:id])
      media=:uploaded_pictures
    when "files"
      object=FileItem.find_by_id(params[:id])
      media=:uploaded_files
    end
    remove_from_session(media,params[:id])
    if object && Media::MEDIA_CLASSES[params[:media]]
      object.destroy
      Media::MEDIA_CLASSES[params[:media]].delete(params[:id])
    end
    find_by_media
    respond params[:media]
  end
  
  def detail
    if Media::MEDIA_CLASSES[params[:media]]
      @object=Media::MEDIA_CLASSES[params[:media]].find_by_id(params[:id])
      render :partial=>"#{params[:media]}_detail", :layout=>false
    else
      respond params[:media]
    end
  end
  private

  def find_by_media
    case params[:media]
    when "images"
      @images=find_all_images
    when "files"
      @files=find_all_files
    end
  end
  def find_all_images
    unless params[:temp].to_b
      Picture.find(:all,:conditions=>["pictureable_type=? AND pictureable_id=? AND NOT picture IS NULL",params[:parent].camelize,params[:parent_id]])
    else
      Picture.find(session_ids(:uploaded_pictures)||[])
    end
  end
  
  def find_all_files
    unless params[:temp].to_b
      FileItem.find(:all,:conditions=>["fileable_type=? AND fileable_id=?",params[:parent].camelize,params[:parent_id]])
    else
      FileItem.find(session_ids(:uploaded_files)||[])
    end
  end
  #Atgreiž sesijā saglabātos attēlu id, ja tiek objekts reāli vēl nav izveidots
  def session_ids media
    if session[media]
      if !session[media][session_id]
        session[media][session_id]=[]
      else
        session[media][session_id]
      end
    end
  end
  #Atgriež id, kas glabā sesijā attēlu id, tas ir,piemēram, 
  # t23453535
  def session_id
    "t#{params[:parent_id]}".to_sym
  end
  def respond media
    render :partial=>params[:container] ? "#{media}_list_#{params[:container]}" : "dialog", :object=>{:media=>media}, :layout=>false
  end
  def remove_from_session(media,id)
    if params[:temp].to_b
      session_media(media).delete(id.to_i)
    end
  end
  def session_media media
    session[media][session_id]=[] if !session[media][session_id]
    session[media][session_id]
  end
end
