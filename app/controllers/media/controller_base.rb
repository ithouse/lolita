class Media::ControllerBase < ApplicationController

  private
  
  def media_class
    @media_class||="Media::#{params[:media].camelize}".constantize
    @media_class
  end

  def new?
    params[:tempid].to_b
  end

  def single?
    params[:single].to_b
  end

  def parent
    params[:parent_id].to_i
  end

  def parent_name
    params[:parent]||""
  end
end
