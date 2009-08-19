class PictureController < ApplicationController
  #FIXME JF:nācās ielikt protect_from_forgery exceptu, jo nekādīgi negribēja ņemt padoto auth tokenu
  protect_from_forgery :except=>[:new_create]
  allow :public=>[:only_image,:load_image_with_siblings,:all_pictures],
    :all=>[
    :load_image_for_cropping,
    :create,:destroy,:new_create,
    :show_picture,
    :all_images,
    :get_large_picture,
    :reload,
    :remove_large_picture,
    :attributes,
    :save_attributes,
    :recreate
  ]

  def all_pictures
    if params[:id] && news=Cms::News.find(params[:id])
      if news.status==4
        all=news.pictures.find(:all,:conditions=>["id!=?",params[:current]])
        current=news.pictures.find(params[:current])
        render :json=>{:urls=>[current.url]+all.collect{|p| p.url}}
        return
      end
    end
    render :json=>{:urls=>[]}
  end
  
  def only_image
    if params[:id] && request.get?
      @picture=Picture.find_by_id(params[:id])
    end
    render :layout=>false
  end

  def recreate
    render :json=>{:id=>params[:id],:info=>Picture.recreate(params)}
  end

  def load_image_for_cropping
    picture=Picture.find_by_id(params[:id])
    image=picture.picture.cropped if picture && picture.picture && picture.picture.cropped.url.to_s.size>0
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
    if params[:id] && [:main,:middle,:thumb,:video].include?(params[:version].to_sym) && picture=Picture.find_by_id(params[:id])
      render :json=>{
        :url=>picture.picture.send(params[:version]).url,
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
    picture=Picture.find_by_id(get_id)
    if request.post? && params[:parent_id] && picture && picture.pictureable_id==params[:parent_id].to_i
      render :partial=>"single_picture_view", :locals=>{:picture=>picture,:container=>params[:container]}
    else
      render :partial=>"single_picture_view", :locals=>{:picture=>nil,:container=>params[:container]}
    end
  end

  def new_create
    params[:picture]={:picture=>params['Filedata']}
    check_session
    if params[:picture] && params[:picture][:picture]
      clear_for_single_picture if single?
      @picture=Picture.new_from_params(params)
      handle_pdf
      if new? && @picture
        session_pictures << @picture.id
      end
      render :text=>"OK"
    else
      render :text=>"Nav norādīts attēls!", :status=>404
    end
  end
  
  def create
    check_session
    if params[:picture] && params[:picture][:picture]
      clear_for_single_picture if single?
      @picture=Picture.new_from_params(params)
      handle_pdf
      if new? && @picture
        session_pictures << @picture.id
      end
      respond_pictures
    else
      render :text=>"Nav norādīts attēls!", :status=>404
    end
  end
  def attributes
    @picture=Picture.find_by_id(params[:id])
    render :layout=>false
  end
  
  def save_attributes
    if @picture=Picture.find_by_id(params[:id])
      @picture.update_attributes(params[:picture])
      render :json=>@picture.attributes
    else
      render :json=>{:id=>params[:id]}
    end
  end
  
  def clear_for_single_picture
    if new?
      Picture.find(session[:uploaded_pictures][session_parent_id] || []).each{|picture|
        picture.destroy
      }
    else
      Picture.by_parent(params[:parent],params[:parent_id]).each{|picture|
        picture.destroy
      }
    end
  end

  def destroy
    if thumb
      thumb.each{|key,id|
        if key!='normal'
          picture=Picture.find_by_id(key.to_i)
          picture.destroy if picture
          session_pictures.delete(id.to_i) if new?
        end
      }
    end
    respond_pictures true
  end

  def get_large_picture
    if new? #gadījumā ja nav izveidots vecāka elements, tad id ir sesijā
      pictures.each{|picture|
        picture.update_attributes(:main_image=>nil)
      }
    end
    Picture.find(get_id).update_attributes(:main_image=>true) if Picture.exists?(get_id)
    render :partial=>'get_image', :object=>{:parent=>parent_name, :parent_id=>parent,:tempid=>new?,:id=>get_id}
  end
 
  def remove_large_picture
    Picture.find(get_id).update_attributes(:main_image=>nil) if Picture.exists?(get_id)
    render :text=>"<img src='/images/cms/blank_main.png' alt='blank image' />"  
  end
  
  def reload
    render :partial=>"thumb_list",:object=>get_params
  end
  
  private
  
  def get_params
    {
      :pictures=>pictures,
      :single=>single?,
      :parent=>parent_name,
      :parent_id=>parent,
      :tempid=>new?,
      :pdf=>pdf?,
      :main_image=>params[:main_image].to_b,
      :read_only=>params[:read_only].to_b,
      :title=>params[:title].to_b
    }
  end
  
  def thumb
    params[:thumb] || nil
  end
 
  def session_pictures
    session[:uploaded_pictures]||={}
    if !session[:uploaded_pictures][session_parent_id]
      session[:uploaded_pictures][session_parent_id]=Array.new
    else
      session[:uploaded_pictures][session_parent_id]
    end
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
  def parent
    params[:parent_id].to_i
  end
  def parent?
    params[:parent_id] && params[:parent_id].to_i>0
  end
  def parent_name
    params[:parent]||""
  end
  def pdf?
    params[:pdf].to_b
  end
 
  def check_session
    if !session[:uploaded_pictures]
      session[:uploaded_pictures]={}
    end
  end
  
  def session_parent_id
    ("t"+parent.to_s).to_sym
  end
  
  def respond_pictures (update_main=false)
    config=get_params
    config[:update_main]=update_main
    render :partial=>'thumb_list', :object=>config, :layout=>false
  end
  
  def pictures
    existing? ? Picture.positioned("asc").by_parent(params[:parent],params[:parent_id]) : Picture.positioned("asc").by_ids(session_pictures || [])
  end
  
  def handle_pdf
    if pdf? && @picture
      begin
        require 'pdf/writer'
      rescue LoadError => le
        if le.message =~ %r{pdf/writer$}
          $LOAD_PATH.unshift("../lib")
          require 'pdf/writer'
        else
          raise
        end
      end
      begin
        pdf = PDF::Writer.new
        i0 = pdf.image RAILS_ROOT+"/public/images/images/picture/#{@picture.id}/#{@picture.picture}"
        file_name=@picture.picture.filename
        file_name=File.basename(file_name,File.extname(file_name))+"_"+rand(100000000).to_s+'.pdf'
        file_id=ActiveRecord::Base.connection.insert("INSERT INTO files (name,fileable_type,fileable_id,name_mime_type) VALUES('#{file_name}','#{@picture.pictureable_type}',#{@picture.pictureable_id},'attachment/octet-stream')")
       
        file=FileItem.find(file_id)
        # Dir.mkdirs("public/files/#{file_id}") unless File.directory?("public/files/#{file_id}")
        begin
          Dir.mkdir(RAILS_ROOT+"/public/files/#{file_id}")
        rescue
        end
        pdf.save_as(RAILS_ROOT+"/public/files/#{file_id}/#{file_name}")
        file.name_filesize=File.size(RAILS_ROOT+"/public/files/#{file_id}/#{file_name}")
        file.save!
      rescue
        # raise "Nevar izveidot pdf failu!"
      end
    end
  end
end