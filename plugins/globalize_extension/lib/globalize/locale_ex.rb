module Globalize
  class Locale
    @@countries = {}
    @@countries_for_select = {}
    
    def self.switch(locale)
      cur_language_code = self.language_code
      self.set(locale)
      result = yield
      self.set(cur_language_code)
      result
    end
  end
end