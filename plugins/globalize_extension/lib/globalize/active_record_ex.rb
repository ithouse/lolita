require 'active_record'

class ActiveRecord::Base # :nodoc:
  include Globalize::DbTranslate
  
  # accessor for the language code
  # return base_language if the product is not globalized
  # 
  # It seem that if originial_language is nil, that mean that
  # the language is equal to the base_language
  def language_code
    if self.class.globalized?
      unless @original_language.nil?
        code = @original_language.code
      else
        code = Globalize::Locale.base_language.code
      end
    elsif Globalize::Locale.language.nil?
      code = Globalize::Locale.base_language.code
    else
      code = Globalize::Locale.language.code
    end
    code
  end
  
  # return true if the model is globalized
  def self.globalized?
    true if class_variables.include? "@@globalize_facets"
  end
  
  # Translate the current doc in another language
  # The previous language attributes were kept in the @translation_cache[language_code]
  # Then you can do :
  # 
  # {{{
  # Locale.set('fr')
  # @document.title = "Nouvelles du jour"
  # @document.switch_language('en') do
  #   @document.title = "Today News"
  #   @document.title #--> Today News
  # end
  # @document.title #--> Nouvelle du jour
  # 
  # # And then save everything:
  # @document.save
  # @document.save_translations
  # }}}
  # 
  # If there is association in @document, they will be translated too.
  # There is an additional 'manual method if you need somme speed increase' but
  # I think this is more error prone because you have to manage the Locale and
  # the object language.
  # 
  # {{{
  # Locale.set('fr')
  # @document.title = "Nouvelles du jour"
  # Locale.set('en')
  # @document.switch_language('en')
  # @document.title = "Today News"
  # @document.title #--> Today News
  # 
  # Locale.set('fr')
  # @document.switch_language('fr')
  # @document.title #--> Nouvelle du jour
  # 
  # # And then save everything:
  # @document.save
  # }}}
  def switch_language(code)
    if block_given?
      old_code = language_code 
      if self.class.globalized?
        operate_switch_language(code)
      else
        operate_switch_language_on_associations(code)
      end
      result =Globalize::Locale.switch(code) do
        yield
      end
      if self.class.globalized?
        operate_switch_language(old_code)
      else
        operate_switch_language_on_associations(old_code)
      end
    else
      if self.class.globalized?
        operate_switch_language(code)
      else
        operate_switch_language_on_associations(code)
      end
      result = Globalize::Locale.switch(code) do
        self
      end
    end
    result
  end
  
  private
    # Switch associations language for loaded associations
    def operate_switch_language_on_associations(code)
      self.class.reflect_on_all_associations.each do |ref|
        association = instance_variable_get("@#{ref.name}".to_sym)
        if !association.nil? && !ref.options[:polymorphic] #Arturs Meisters
          if association.kind_of? ref.klass
            send(ref.name).switch_language(code)
          else
            send(ref.name).each {|r| r.switch_language(code)}
          end
        end
      end
    end
end