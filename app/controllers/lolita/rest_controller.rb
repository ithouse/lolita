class Lolita::RestController < ApplicationController
  include Lolita::Controllers::InternalHelpers

  layout "lolita/layouts/default"
  
  def new
    build_resource
    render :text=>build_response_for(:tabs)
  end

  def create
    build_resource
    save_and_redirect
  end

  def edit
    get_resource
    render :text=>build_response_for(:tabs)
  end
  
  def update
    get_resource
    if self.resource
      self.resource=resource_with_attributes(self.resource,resource_attributes)
      save_and_redirect
    end
  end

  def destroy
    get_resource
    if self.resource && self.resource.destroy
      redirect_to :action=>:index
    end
  end

  def index
    page=resource_class.lolita.list.paginate(params[:page])
    respond_to do |format|
      format.html do
        @response_text=build_response_for(:list,:page=>page)
      end
      format.json do
        render :json=>page
      end
    end
  end

  private

  def save_and_redirect
    if self.resource.save
      if self.resource.errors.empty?
        render :text=>build_response_for(:tabs)
      else
        redirect_to :action=>:index
      end
    end
  end
end
