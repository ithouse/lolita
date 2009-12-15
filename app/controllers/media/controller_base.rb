# All media controller classes are subclasses of this class.
# Media::ControllerBase provide some useful methods for these clases.
class Media::ControllerBase < ApplicationController

  protected
  # Return @media_class variable or set it using params[:media]
  # ====Example
  #  params[:media] #=> "image_file"
  #  media_class #=> Media::ImageFile
  def media_class
    @media_class||="Media::#{params[:media].camelize}".constantize
    @media_class
  end

  # Is record new. Return _true_ when params[:tempid] is greater than 0.
  def new?
    params[:tempid].to_b
  end

  # Is only single record need to b created. _True_ when params[:single] is true
  def single?
    params[:single].to_b
  end

  # Return parent id, from params[:parent_id]
  def parent
    params[:parent_id].to_i
  end

  # Return parent name from params[:parent]
  # ====Example
  #  params[:parent] #=> cms/blog
  #  parent_name #=> cms/blog
  def parent_name
    params[:parent]||""
  end
end
