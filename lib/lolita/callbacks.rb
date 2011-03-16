module Lolita
  @@callbacks={}
  # define_callback :before_component
  def define_callback name
    @@callbacks[name.to_sym]||=[]
  end
  
  def run_callback name, *args
    
  end
end