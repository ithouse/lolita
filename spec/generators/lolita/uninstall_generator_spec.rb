require 'spec_helper'
require 'fileutils'
require 'generator_spec/test_case'
require_relative '../../../lib/generators/lolita/uninstall_generator'

describe Lolita::Generators::UninstallGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../../../tmp", __FILE__)

  before do
    prepare_destination
    Rails.stub(:root).and_return(Pathname.new(destination_root))
    create_initializer(destination_root)
    create_tinymce(destination_root)
    create_routesrb(destination_root)
    run_generator
  end

  specify "removes lolita.rb initializer" do
    destination_root.should have_structure {
      directory "config" do
        directory "initializers" do
          no_file "lolita.rb"
        end
      end
    }
  end

  specify "removes tinymce.yml config" do
    destination_root.should have_structure {
      directory "config" do
        no_file "tinymce.yml"
      end
    }
  end


  specify "removes lolita_for from routes.rb" do
    destination_root.should have_structure {
      directory "config" do
        file "routes.rb" do
          if open(@name, &:read).include?('lolita_for')
            throw :failure, 'lolita_for not removed from routes.rb'
          end
        end
      end
    }
  end
end

def create_initializer destination_root
  initializers_dir = File.join(destination_root, 'config', 'initializers')
  FileUtils.mkdir_p(initializers_dir)
  FileUtils.touch(File.join(initializers_dir, 'lolita.rb'))
end

def create_tinymce destination_root
  tinymce_dir = File.join(destination_root, 'config')
  FileUtils.mkdir_p(tinymce_dir)
  FileUtils.touch(File.join(tinymce_dir, 'tinymce.yml'))
end

def create_routesrb destination_root
  File.open(File.join(destination_root, 'config', 'routes.rb'), 'w') { |file| file.write("lolita_for :some_model") }
end
