class Media::MediaDialogController < ApplicationController
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
      @image=ImageFile.find_by_id(params[:id])
    when "files"
      @file=FileItem.find_by_id(params[:id])
    end
    render :partial=>"update_#{params[:media]}", :object=>{:id=>params[:id]},:layout=>false
  end
  
  def save_attributes
    case params[:media]
    when "images"
      object=ImageFile.find_by_id(params[:id])
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
      object=ImageFile.find_by_id(params[:id])
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
      ImageFile.find(:all,:conditions=>["pictureable_type=? AND pictureable_id=? AND NOT picture IS NULL",params[:parent].camelize,params[:parent_id]])
    else
      ImageFile.find(session_ids(:uploaded_pictures)||[])
    end
  end
  
  def find_all_files
    unless params[:temp].to_b
      FileItem.find(:all,:conditions=>["fileable_type=? AND fileable_id=?",params[:parent].camelize,params[:parent_id]])
    else
      FileItem.find(session_ids(:uploaded_files)||[])
    end
  end
  
end
