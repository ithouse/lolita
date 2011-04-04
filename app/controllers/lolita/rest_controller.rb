class Lolita::RestController < ApplicationController
  include Lolita::Controllers::UserHelpers
  include Lolita::Controllers::InternalHelpers
  
  before_filter :authenticate_lolita_user!
  layout "lolita/application"
  
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
      flash.now[:notice] = I18n.t "lolita.shared.destroy_notice"
    else
      flash.now[:alert] = I18n.t "lolita.shared.destroy_alert"
    end
    redirect_to :action=>"index"
  end

  def index
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
    #TODO Valdis: ja es extendoju rest_controller un gribu pārdefinēt edit actionu, man vajag lai
    #  varu norādīt citu šablonu, piemēram, manā gadījumā ir services_controller un jamais meklē
    #  "services/form", bet es gribu izmantot to pašu "lolita/rest/form"
    #  tagad man viss šitais jāpārkopē uz projektu

    build_response_for(:tabs)
    if request.xhr?
      render :form, :layout => false
    else
      render :form
    end
  end
  
  def save_and_redirect
      respond_to do |format|
        format.html do
          if self.resource.save
            flash.now[:notice] = I18n.t "lolita.shared.save_notice"
          else
            flash.now[:alert] = I18n.t "lolita.shared.save_alert"
          end
          show_form
        end
        format.json do
          render :status => self.resource.save ? 200 : 400, :json => self.resource
        end
      end
  end
  
  def to_list
    builder=build_response_for(:list,:page=>page)
    render :index
    #render_component *builder
  end

  def page
    resource_class.lolita.list.paginate(params[:page])
  end
end
