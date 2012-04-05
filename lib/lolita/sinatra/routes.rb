
def lolita_for *resources
  options = resources.extract_options!

  resources.each do |resource|
    resource = resource.to_sym

    mapping = Lolita.add_mapping(resource,options)
    Lolita.resources[mapping.name] = mapping
 
    get "/#{mapping.controller}" do 
      "#{mapping.controller} index"
    end

    get "/#{mapping.controller}/new" do 
      "#{mapping.controller} new"
    end

    get "/#{mapping.controller}/:id/edit" do 
      "#{mapping.controller} edit"
    end

    post "/#{mapping.controller}" do
      "#{mapping.controller} create"
    end

    patch "/#{mapping.controller}/:id" do 
      "#{mapping.controller} update"
    end

    delete "/#{mapping.controller}/:id" do 
      "#{mapping.controller} delete"
    end
  end
end
