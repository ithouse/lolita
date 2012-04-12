module Lolita
  module Sinatra
    class Routes

      def self.add_to(klass,mapping)
        klass.class_eval do 
     
          get "/#{mapping.controller}" do 
            self.lolita_mapping = mapping
            processor = Lolita::Processors::RequestProcessor.respond_to(mapping,self,:index)
          end

          get "/#{mapping.controller}/new" do 
            lolita_mapping = mapping
            "#{mapping.controller} new"
          end

          get "/#{mapping.controller}/:id/edit" do 
            lolita_mapping = mapping
            "#{mapping.controller} edit"
          end

          post "/#{mapping.controller}" do
            lolita_mapping = mapping
            "#{mapping.controller} create"
          end

          patch "/#{mapping.controller}/:id" do 
            lolita_mapping = mapping
            "#{mapping.controller} update"
          end

          delete "/#{mapping.controller}/:id" do 
            lolita_mapping = mapping
            "#{mapping.controller} delete"
          end 
        end
        mapping.add_to_navigation_tree
      end

    end
  end
end
