class Lolita::RestController < ApplicationController
  include Lolita::Controllers::UserHelpers
  include Lolita::Controllers::InternalHelpers
  
  before_filter :authenticate_lolita_user!
  after_filter :discard_xhr_flash
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
    if request.xhr?
      render :form, :layout => false
    else
      render :form
    end
  end
  
  def save_and_redirect
    if self.resource.save
      flash[:notice] = I18n.t "lolita.shared.save_notice"
      show_form
    else
      flash[:alert] = I18n.t "lolita.shared.save_alert"
      show_form #to_list
    end
  end
  
  def to_list
    page=resource_class.lolita.list.paginate(params[:page])
    builder=build_response_for(:list,:page=>page)
    render :index
    #render_component *builder
  end
  
  def discard_xhr_flash
    flash.discard if request.xhr?
  end
end
