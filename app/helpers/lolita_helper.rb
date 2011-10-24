module LolitaHelper
	# Classes for div block that is located to the right of menu
	# This is helpful because different positionings within it exist depending on action
  def content_classes
    classes = []
    if params[:action] == "edit" || params[:action] == "new"
    	classes << "with-secondary"
    end
    classes.join(" ")
  end

  def include_application_assets
    result = ""
    Lolita.application.assets.each do |asset_name|
      if attr_name.match(/\.js(\.|$)/)
        result << javascript_include_tag(asset_name)
      elsif attr_name.match(/\.css(\.|$)/)
        result << stylesheet_link_tag(asset_name)
      end
    end
    raw(result)
  end
end