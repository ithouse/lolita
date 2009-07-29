class Admin::Language < Cms::Base
  set_table_name :admin_languages
    
  belongs_to :globalize_language , :class_name => '::Globalize::Language', :foreign_key => 'globalize_languages_id'
    
  validates_presence_of :globalize_languages_id
    
  def self.find_all
    find(:all)
  end
    
  def self.find_all_short_names
    all_langs = self.find_all
    all_short_names = []
    all_langs.collect { |x| all_short_names << x.short_name }
    all_short_names
  end
   
  def self.find_base_language
    find(:first, :conditions =>["is_base_locale=?",true])
  end
    
  def self.find_additional_languages
    find(:all, :conditions =>["is_base_locale=?",false])
  end
    
  def self.find_by_globalize_language_id(id)
    find(:all, :conditions => 'globalize_languages_id = '+id).first
  end

  def short_name
    self.globalize_language.iso_639_1
  end
  def name
    self.globalize_language.english_name
  end
  def language
    self.globalize_language
  end
end
