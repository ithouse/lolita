module Lolita
  # Create mapping for routes.
  # Each mapping has name, like :posts, :files etc.
  # Also it accepts options: 
  # * <tt>:singular</tt> - singular form for route, by default it call #singularize on _name_.
  # * <tt>:class_name</tt> - class that is related with route, by default it uses :singular, and classify it. It should be like "Post".
  # * <tt>:path_prefix</tt> - path starts with path prefix, like /path_prefix/lolita/posts.
  # * <tt>:path</tt> - path and path url methods starts with this path.
  # =====Example
  #     lolita_for :posts, :path=>"admin"
  #     # add paths like this to routes
  #     # admin_posts GET /admin/posts {:controller=>"lolita/rest", :action=>:index}
  #     # edit_admin_posts GET /admin/post/1/edit {:controller=>"lolita/rest",:action=>:edit}
  # * <tt>:module</tt> - change module for path, it changes <i>:controller</i> that is used for lolita, like, 
  #   <code>:module=>"admin"</code>, change controller to "admin/posts". If this is used without :path then no named routes will be generated
  # Instances of this class is used all over the Lolita, this class itself represent what name does resource has,
  # what controller to use, what model is related with it and so on. This is used to generate urls and paths.
  # Also eahc request containers information with mapping related to it.
  class Mapping
    attr_reader :class_name,:path,:singular,:plural,:path_prefix,:module,:controllers,:as
    attr_reader :visible, :only
    alias :name :singular
    
    
    def initialize(name,options={})
      # TODO how it is when lolita plugin extend default path and there is module is this not break the logic?
      @as=options[:as]
      @visible = options.keys.include?(:visible) ? options[:visible] : true
      @only = options[:only] || nil
      @plural=(options[:as] ? options[:as] : name).to_sym
      @singular=(options[:singular] || @plural.to_s.singularize).to_sym
      @class_name=(options[:class_name] || name.to_s.classify).to_s
      @ref = @class_name.to_s.camelize
      @path_prefix=options[:path_prefix]
      @path=(options[:path] || "lolita").to_s
      @module=options[:module] 
      mod=@module ? nil :  "lolita/"
      @controllers=Hash.new{|h,k|
        h[k]=options[:controller] || "#{mod}#{k}" 
      }
    end
  
    # Return class that is related with mapping.
    def to
      @ref.constantize
    end
    
    # full path of current mapping
    def fullpath
      "#{@path_prefix}/#{@path}".squeeze("/")
    end

    def url_name #TODO test what with namespace
      "#{@path}_#{@plural}"
    end

    def add_to_navigation_tree
      if self.visible
        tree = Lolita::Navigation::Tree[:"left_side_navigation"]
        unless tree.branches.detect{|b| b.object.is_a?(Lolita::Mapping) && b.object.to==self.to}
          tree.append(self)
        end
      end
    end
    
  end
end
