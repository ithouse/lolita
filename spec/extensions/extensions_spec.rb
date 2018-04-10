require 'simple_spec_helper'

class WithLolitaExtensions
  include Lolita::Extensions
end

module Lolita::Extensions::Test
  class Proxy
    def initialize *args
    end
  end
end

describe Lolita::Extensions do
  let(:test_class){ WithLolitaExtensions.new }
  let(:object){
    klass = Object.new
    klass.class_eval{include Lolita::Extensions}
    klass
  }
  
  it "should load all extensions proxies" do
    Lolita::Extensions.add(:test)
    test_class.load_extensions_proxies(object)
    test_class.test_proxy.should be_a(Lolita::Extensions::Test::Proxy)
  end
  
  context "default extensions" do
    it "should have default extensions proxies" do
      test_class.load_extensions_proxies(object)
      Lolita::Extensions::EXTENSIONS.each do |name|
        test_class.send(:"#{name}_proxy").should be_a("Lolita::Extensions::#{name.to_s.camelize}::Proxy".constantize)
      end
    end
  end

  context "default configuration" do

    it "should have authentication adapter" do
      test_class.load_extensions_proxies(object)
      test_class.authentication_proxy.respond_to?(:adapter).should be_truthy
    end

  end
end
