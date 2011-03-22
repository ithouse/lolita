module Lolita
  class Mapping
    attr_reader :class_name,:path,:singular,:plural,:path_prefix,:module,:controllers,:as
    alias :name :singular
    
    # TODO how it is when lolita plugin extend default path and there is module is this not break the logic?
    def initialize(name,options={})
      @plural=name.to_sym#(options[:as] ? "#{options[:as]}_#{name}" : name).to_sym
      @singular=(options[:singular] || @plural.to_s.singularize).to_sym
      @class_name=(options[:class_name] || name.to_s.classify).to_s
      @ref = ActiveSupport::Dependencies.ref(@class_name)
      @path_prefix=options[:path_prefix]
      @path=(options[:path] || "lolita").to_s
      @module=options[:module] 
      mod=@module ? nil :  "lolita/"
      @controllers=Hash.new{|h,k|
        h[k]="#{mod}#{k}" 
      }
    end
    #
    # lolita/posts/new => lolita/crud/new :class=>Post
    # posts/new => posts/new
    #
    def to
      @ref.get
    end
    
    def fullpath
      "#{@path_prefix}/#{@path}".squeeze("/")
    end

    def url_name #TODO test what with namespace
      "#{@path}_#{@plural}"
    end
    
  end
end
