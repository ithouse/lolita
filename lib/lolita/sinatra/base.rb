require 'haml'
require 'sinatra/base'

module Lolita 
  module Sinatra
    extend ActiveSupport::Concern

    module ClassMethods
      def lolita_for *resources
        options = resources.extract_options!
        resources.each do |resource|
          resource = resource.to_sym

          mapping = Lolita.add_mapping(resource,options)
          Lolita.resources[mapping.name] = mapping

          Lolita::Sinatra::Routes.add_to(Lolita::RestController,mapping)
        end
      end
    end

  end
end

require 'lolita/sinatra/routes'


