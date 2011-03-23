module LolitaHelper
	
	# Classes for div block that is located to the right of menu
	# This is helpful because different positionings within it exist depending on action
  def content_classes
    classes = []
    if params[:action] == "edit"
    	classes << "with-secondary"
    end
    classes.join(" ")
  end
end