module Lolita
  module Utils

    def self.dynamic_string(str, options = {})
      response_str = if str.respond_to?(:call)
        str.call(str,options)
      else
        str
      end
      response_str || options[:default]
    end

  end
end