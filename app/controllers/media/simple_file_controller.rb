class Media::SimpleFileController < Media::Base
  allow :all=>[:new_create,:destroy,:show,:refresh]
  
end
