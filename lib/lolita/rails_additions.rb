module Lolita
  module ArrayExtractOptions
    def extract_options!
      last.is_a?(::Hash) ? pop : {}
    end
  end
  module StringSupport
    def camelize( first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        self.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        self.to_s[0].chr.downcase + camelize(self)[1..-1]
      end
    end
    
    def underscore()
      word = self.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

    def constantize()
      names = self.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
  end
end

Array.send(
  :include, Lolita::ArrayExtractOptions
) unless Array.instance_methods.include?("extract_options!")
String.send(
  :include, Lolita::StringSupport
) unless String.instance_methods.include?("constantize")
