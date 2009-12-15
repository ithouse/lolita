# Handle #Media::SimpleFile records, no new _actions_ are added. See #Media::ControllerFileBase for detail.
class Media::SimpleFileController < Media::ControllerFileBase
  allow :all=>[:new_create,:destroy,:show,:refresh]
  
end
