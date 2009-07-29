require File.dirname(__FILE__) + '/test_helper'

class TranslationMethodsTest < Test::Unit::TestCase
  self.use_instantiated_fixtures = true
  fixtures :globalize_languages, :globalize_translations, :globalize_countries, 
    :globalize_products, :globalize_manufacturers

  class Product < ActiveRecord::Base
    set_table_name "globalize_products"

    translates :name, :description, :specs, { 
      :name => { :bidi_embed => false }, :specs => { :bidi_embed => false } }
    
    belongs_to :manufacturer, :foreign_key => 'manufacturer_id'
    has_and_belongs_to_many :categories, :join_table => "globalize_categories_products"    
  end
  
  class AfterSwitchLanguageProduct < ActiveRecord::Base
    set_table_name "globalize_products"

    translates :name, :description, :specs, { 
      :name => { :bidi_embed => false }, :specs => { :bidi_embed => false } }
    
    after_switch_language :new_name
    
    def new_name
      self.name="Nouveau nom"
    end
  end
  
  class Manufacturer < ActiveRecord::Base
    set_table_name "globalize_manufacturers"
    has_many :products

    translates :name  
  end
  
  # Same as above except that all fields are translated
  class FullyTranslatedManufacturer < ActiveRecord::Base
    set_table_name "globalize_manufacturers"
    has_many :products
    
    translates :name, :code
  end
  
  class Category < ActiveRecord::Base
    set_table_name "globalize_categories"
    has_and_belongs_to_many :products, :join_table => "globalize_categories_products"
    
    # translates nothing
  end
  
  def setup
    Globalize::Locale.set("en-US")
    Globalize::Locale.set_base_language("en-US")
  end
  
  # change Locale language during a block
  def test_locale_switch
    Globalize::Locale.switch('he') do
      prod = Product.find(1)
      assert_equal('he', prod.language_code)
    end
    assert_equal('en', Globalize::Locale.language_code)
  end
  
  def test_product_show_is_language_code
    prod = Product.find(6)
    assert_equal('en', prod.language_code)
  end
  
  def test_save_translations_method
    Locale.set('en')
    prod = Product.find(6)
    prod.name = "The new name"
    prod.code = "the-new-code"
    Globalize::Locale.switch('fr') do
      prod.switch_language('fr')
      prod.name = "Le nouveau nom"
    end
    prod.switch_language('en')
    assert(prod.save)
    
    prod = Product.find(6)
    assert_equal("The new name", prod.name)
    
    Globalize::Locale.switch('fr') do
      prod.switch_language('fr')
      assert_equal("Le nouveau nom", prod.name)
      assert_equal("the-new-code", prod.code)
    end
  end
  
  def test_save_translations_on_belongs_to_association
    prod = Product.new
    prod.name = "New Product"
    prod.switch_language('fr')
    prod.manufacturer = Manufacturer.find(2)
    assert_equal 2, prod.manufacturer_id
    
    prod.switch_language('en')
    assert(prod.save)
    prod.reload
    
    assert_equal prod.id, prod.id
    assert_not_nil prod.manufacturer
  end
  
  def test_product_switch
    prod = Product.find(6)
    prod.name = "Other Name"
    prod.switch_language('fr')
    Locale.switch('fr') do
      assert_nothing_raised {prod.name}
      assert_equal "Briquet de test de traduction", prod.name
    end
    prod.switch_language('en')
    assert_nothing_raised {prod.name}
    assert_equal "Other Name", prod.name
  end
  
  def test_belongs_to_associations_switch_language
    prod = Product.find(6)
    assert_equal('en', prod.manufacturer.language_code)
    prod.name = 'New product name'
    prod.manufacturer.name = 'New manufacturer name'
    Locale.switch('fr') do 
      prod.switch_language('fr')
      assert_equal('fr', prod.manufacturer.language_code)
      prod.name = 'Nouveau nom de produit'
      prod.manufacturer.name = 'Nouveau nom de fabricant'
    end
    prod.switch_language('en')
    assert(prod.save)
    assert(prod.manufacturer.save)
    prod.reload
    assert_equal('New product name', prod.name)
    assert_equal('New manufacturer name', prod.manufacturer.name)
    Locale.switch('fr') do
      prod.switch_language('fr')
      assert_equal('Nouveau nom de produit', prod.name)
      assert_equal('Nouveau nom de fabricant', prod.manufacturer.name)
    end
  end
  
  def test_has_many_associations_switch_language
    mfr = Manufacturer.find(2)
    assert_equal('en', mfr.language_code)
    mfr.name = "New manufacturer name"
    mfr.products.first.name = "New product name"
    Locale.switch('fr') do
      mfr.switch_language('fr')
      mfr.products.each do |prod|
        assert_equal('fr', prod.language_code)
      end 
      mfr.name = "Nouveau nom de fabricant"
      mfr.products.first.name = "Nouveau nom de produit"
    end
    mfr.switch_language('en')
    assert(mfr.save)
    mfr.products.each {|p| assert p.save}
    
    assert_equal('New manufacturer name', mfr.name)
    assert_equal('New product name', mfr.products.first.name)
    Locale.switch('fr') do
      mfr.switch_language('fr')
      assert_equal('Nouveau nom de fabricant', mfr.name)
      assert_equal('Nouveau nom de produit', mfr.products.first.name)
    end
    
    mfr.reload
    assert_equal('New manufacturer name', mfr.name)
    assert_equal('New product name', mfr.products.first.name)
    Locale.switch('fr') do
      mfr.switch_language('fr')
      assert_equal('Nouveau nom de fabricant', mfr.name)
      assert_equal('Nouveau nom de produit', mfr.products.first.name)
    end
  end
  
  def test_should_not_switch_non_globalized_products
    prod = Product.new
    prod.categories << Category.new
    assert_nothing_raised {prod.switch_language('fr')}
  end
  
  def test_switch_with_block
    prod = Product.new
    prod.name = 'New product'
    prod.switch_language('fr') do
      prod.name = 'Nouveau produit'
    end
    assert_equal('New product', prod.name)
  end
  
  def test_after_switch_language_callback
    prod = AfterSwitchLanguageProduct.new
    prod.switch_language('fr')
    Locale.switch('fr'){
      assert_equal("Nouveau nom", prod.name)
    }
  end
  
  def test_globalized_products
    prod = Product.new
    attrs = {
      :en=>{:name=>'my product'},
      :fr=>{:name=>'mon produit'},
      :de=>{:name=>'Meine Produkt'}
    }
    prod.set_globalized_attributes(attrs, ['en', 'fr'])
    prod.switch_language('fr') do
      assert_equal 'mon produit', prod.name
    end
    prod.switch_language('en') do
      assert_equal 'my product', prod.name
    end
    prod.switch_language('de') do
      assert_equal 'my product', prod.name
    end
  end
  
  def test_globalized_products_without_language
    prod = Product.new
    attrs = {
      :en=>{:name=>'my product'},
      :fr=>{:name=>'mon produit'},
      :de=>{:name=>'Meine Produkt'}
    }
    prod.set_globalized_attributes(attrs)
    prod.switch_language('fr') do
      assert_equal 'mon produit', prod.name
    end
    prod.switch_language('en') do
      assert_equal 'my product', prod.name
    end
    prod.switch_language('de') do
      assert_equal 'Meine Produkt', prod.name
    end
  end
  
  def test_update_when_all_fields_are_translated
    FullyTranslatedManufacturer.new(:name => "The Global Thing", :code => "all_is_translated").save!
    Globalize::Locale.set("fr-FR")
    man = FullyTranslatedManufacturer.find_by_code("all_is_translated")
    man.attributes = {:name => "La chose globale", :code => "tout_est_traduit"}
    assert_nothing_raised {man.save!}
    man.reload
    assert_equal("La chose globale", man.name)
    assert_equal("tout_est_traduit", man.code)
  end
end
