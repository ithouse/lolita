class Lolita::RestController < ApplicationController
  include Lolita::Controllers::InternalHelpers

  layout "lolita/layouts/default"
  
  def new
    build_resource
    render :text=>build_response_from(:tabs)
  end

  def create

  end

  def edit
    self.resource=resource_class.find(params[:id])
    render :text=>build_response_from(:tabs)
  end
  
  def update

  end

  def destroy

  end

  def index
    page=resource_class.lolita.list.paginate(params[:page])
    respond_to do |format|
      format.html do
        @response_text=build_response_from(:list,:page=>page)
        render
      end
      format.json do
        render :json=>page
      end
    end
  end
end
