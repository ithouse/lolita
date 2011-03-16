class Lolita::RestController < ApplicationController
  include Lolita::Controllers::UserHelpers
  include Lolita::Controllers::InternalHelpers
  
  before_filter :authenticate_lolita_user!
  layout "lolita/layouts/application"
  
  def new
    build_resource
    show_form
  end

  def create
    build_resource
    save_and_redirect
  end

  def edit
    get_resource
    show_form
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
      to_list
    end
  end

  def index
    page=resource_class.lolita.list.paginate(params[:page])
    respond_to do |format|
      format.html do
        build_response_for(:list,:page=>page)
      end
      format.json do
        render :json=>page
      end
    end
  end

  private

  def show_form
    build_response_for(:tabs)
    render :form
  end
  
  def save_and_redirect
    if self.resource.save
      unless self.resource.errors.empty?
        show_form
      else
        to_list
      end
    end
  end
  
  def to_list
    page=resource_class.lolita.list.paginate(params[:page])
    builder=build_response_for(:list,:page=>page)
    render_component *builder
  end
end
