class Media::SimpleFileController < Media::ControllerFileBase
  allow :all=>[:new_create,:destroy,:show,:refresh]
  
end
