module Lolita
  class Buffer
    def self.add(object,method_name,*args)
      buffer=object.instance_variable_get(:@lolita_buffer)
      unless buffer
        values={method_name=>[args]}
      else
        if buffer[method_name]
          values=buffer[method_name]
        end
      end
      object.instance_variable_set(:@lolita_buffer,values)
    end
  end
end
