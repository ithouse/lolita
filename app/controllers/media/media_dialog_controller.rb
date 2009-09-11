class Media::MediaDialogController < ApplicationController
  allow :all=>[:all_image_file,:open_attributes,:save_attributes,:destroy,:detail]
  def all_image_file
    @images=Media::ImageFile.find_current_files(params[:parent],params[:parent_id])
    render :partial=>"dialog", :object=>{:media=>"image_file"}
  end
  
  def open_attributes
    @image=Media::ImageFile.find_by_id(params[:id])
    render :partial=>"update_image_file", :object=>{:id=>params[:id]},:layout=>false
  end
  
  def save_attributes
    object=Media::ImageFile.find_by_id(params[:id])
    updateable=params[:image]
    if object && object.update_attributes(updateable)
      render :json=>[object.attributes]
    else
      render :text=>"Can't save!", :status=>400
    end
  end
  
  def destroy
    Media::ImageFile.delete_file(params[:id])
    find_by_media
    render :partial=>"dialog", :object=>{:media=>params[:media]}
  end
  
  def detail
    @object=Media::ImageFile.find_by_id(params[:id])
    render :partial=>"image_file_detail", :layout=>false
  end
  private

  def find_by_media
    @images=Media::ImageFile.find_current_files(params[:parent],params[:parent_id])
  end
  
end
