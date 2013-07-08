require 'spec_helper'
require 'generator_spec/test_case'
require_relative '../../../lib/generators/lolita/install_generator'

module FakeDevise
  def self.mappings
    {user: Object}
  end
end

describe Lolita::Generators::InstallGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../../../tmp", __FILE__)

  context "without Devise" do
    before do
      prepare_destination
      run_generator
    end

    specify "generates lolita.rb initializer" do
      destination_root.should have_structure {
        directory "config" do
          directory "initializers" do
            file "lolita.rb" do
              contains "Lolita.setup"
              contains "#= Sample config for Admin user managing Lolita"
            end
          end
        end
      }
    end
  end

  context "with Devise" do
    before do
      stub_const('Devise', FakeDevise)
      prepare_destination
      run_generator
    end

    specify "generates lolita.rb initializer" do
      destination_root.should have_structure {
        directory "config" do
          directory "initializers" do
            file "lolita.rb" do
              contains "Lolita.setup"
              contains "config.authentication=:authenticate_user!"
            end
          end
        end
      }
    end
  end
end