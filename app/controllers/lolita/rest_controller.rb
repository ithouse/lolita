class Lolita::RestController < ApplicationController
  include Lolita::Controllers::UserHelpers
  include Lolita::Controllers::InternalHelpers

  include Lolita::Hooks
  add_hook :before_new, :after_new, :before_create,:after_create,:before_edit,:after_edit
  add_hook :before_update,:after_update,:before_destroy,:after_destroy,:before_index,:after_index
  add_hook :before_build_resource, :after_build_resource
  
  before_filter :authenticate_lolita_user!
  layout "lolita/application"
  
  def new
    self.run(:before_new)
    build_resource
    show_form
  end

  def create
    self.run(:before_create)
    build_resource
    save_and_redirect
  end

  def edit
    self.run(:before_edit)
    get_resource
    show_form
  end
  
  def update
    self.run(:before_update)
    get_resource
    if self.resource
      self.resource=resource_with_attributes(self.resource,resource_attributes)
      save_and_redirect

    end
  end

  def destroy
    self.run(:before_destroy)
    get_resource
    if self.resource && self.resource.destroy
      flash.now[:notice] = I18n.t "lolita.shared.destroy_notice"
    else
      flash.now[:alert] = I18n.t "lolita.shared.destroy_alert"
    end
    self.run(:after_destroy)
    redirect_to :action=>"index"
  end

  def index
    self.run(:before_index)
    respond_to do |format|
      format.html do
        build_response_for(:list,:page=>page)
      end
      format.json do
        render :json=>page
      end
    end
    self.run(:after_index)
  end

  private

  def show_form
    build_response_for(:tabs)
    self.run(:"after_#{params[:action]}")
    if request.xhr?
      render "/lolita/rest/form", :layout => false
    else
      render "/lolita/rest/form"
    end
  end
  
  def save_and_redirect
    respond_to do |format|
      if self.resource.save
        self.resource.reload
        
        format.html{ respond_html_200}
        format.json{ respond_json_200}
      else
        format.html{ respond_html_400 }
        format.json{ respond_json_400 }
      end
    end
  end
  
  def respond_html_200
    flash.now[:notice] = I18n.t "lolita.shared.save_notice"
    show_form
  end

  def respond_html_400
    flash.now[:alert] = I18n.t "lolita.shared.save_alert"
    show_form
  end

  def respond_json_200
    respond_json(200)
  end

  def respond_json_400
    respond_json(400)
  end

  def respond_json(status)
    self.run(:"after_#{params[:action]}")
    render :status=>status, :json=>self.resource
  end

  def to_list
    builder=build_response_for(:list,:page=>page)
    render :index
    #render_component *builder
  end

  def page
    resource_class.lolita.list.paginate(params[:page], :params => params)
  end
end
