module Lolita
  module Controllers
  	# Helper that add #render_component method. That is shortstand for render :partial for lolita
  	# partial files. Also it provide view hooks for Lolita.
	  # For any component there may be helper module. Modules are include in current view or 
    # controller instance when component is rendered.
    # All components ar placed in "app/helpers/components/[your component path]".
    # Component should have fallowing module structure Components::[NameSpace]::[Component name]Component
    #     Components::Lolita::ListComponent
    # ====Example
    #     render_component :"lolita/configuration/list", :dispaly
    #     # try to find /helpers/components/lolita/list_component.rb in every directory in $: that
    #     # ends with /helpers
    #     # require this file if found and extend self with Components::Lolita::ListComponent.
    # Component helpers is loaded in same order as views or controller.
    module ComponentHelpers
      # Render partial template.
      # Accept:
      # <tt>name</tt> - name for component in '/components' directory,
      #  can be full name too.
      #  Example 'lolita/list'
      # <tt>state</tt> - name for partial. Example 'row'.
      # <tt>options</tt> - any options to pass as <code>:locals</code> to partial,
      #  also available through <code>@opts</code> variable.
      # =====Example
      #      render_component "lolita/list", :display
      #      render_component "lolita/list/display"
      def render_component *args
        @rendering_components ||= []
        name,state,options=get_render_options(*args)
        format=options.delete(:format)
        raise "Can't render component without name!" unless name
        will_use_component name
        component_name=File.join(name.to_s,state ? "#{!Lolita.rails? && "_" || ""}#{state}" : "")
        partial_name=File.join("/components",component_name)

        @rendering_components.push(component_name)
        @current_component_name = component_name
        output = output_component(partial_name,component_name,:format=>format ,:locals=>options)
        @rendering_components.pop
        @current_component_name = @rendering_components.last
        self.respond_to?(:raw) ? raw(output) : output
      end
      
      def get_render_options *args
        options=args.extract_options!
        if args.first.respond_to?(:build) 
          name,state,options=args[0].build("",args[1],options)
        elsif args.first.class.ancestors.include?(Lolita::Configuration)
          raise ArgumentError, "Include Lolita::Builder in #{args.first.class}"
        else
          name,state=args
          name = "/#{name}" unless name.to_s.match(/^\//)
        end
        return name,state,options
      end

      def output_component(partial_name,name,options={})
        output=""
        if options[:format]
          with_format(options[:format]) do
            output << output_with_callbacks(partial_name,name,options[:locals])
          end
        else
          output << output_with_callbacks(partial_name,name,options[:locals])
        end
        output
      end

      def output_with_callbacks(partial_name,name,locals)
        @component_locals ||={}
        @component_locals[name] = locals
        output = Lolita::Hooks.component(name).run(:before,:run_scope => self).to_s
        block_output = Lolita::Hooks.component(name).run(:around, :run_scope => self) do
          if Lolita.rails?
            render(:partial => partial_name, :locals => locals)
          else
            haml :"#{partial_name}.html", :locals => locals
          end
        end
        #FIXME does block_output raises error?
        output << block_output.to_s
        output << Lolita::Hooks.component(name).run(:after,:run_scope => self).to_s
        @component_locals[name] = nil
        output
      end

      def with_format(format, &block)
        old_formats = formats
        self.formats = [format]
        result=block.call
        self.formats = old_formats
        result
      end

      # Require component helper file and extend current instance with component helper module.
      # ====Example
      #     will_use_component :"lolita/configuration/list"
      def will_use_component component_name
        helpers_for_component(component_name) do |possible_component_name|
          @used_component_helpers||={}
          unless @used_component_helpers.include?(possible_component_name)
            if path=component_helper_path(possible_component_name)
              self.class.class_eval do
                require path
              end
              class_name=possible_component_name.to_s.camelize
              helper_module = "Components::#{class_name}Component".constantize rescue nil
              if helper_module
                self.extend(helper_module) 
              end
            end
            @used_component_helpers[possible_component_name] = helper_module
          else
            if helper_module = @used_component_helpers[possible_component_name]
              self.extend(helper_module)
            end
          end
        end
      end
      
      def helpers_for_component component_name
        names=component_name.to_s.gsub(/^\//,"").split("/")
        start_index=1 # first is lolita
        start_index.upto(names.size) do |index|
          yield names.slice(0..index).join("/")
        end
      end

      # Find path for given component.
      # 
      #    component_helper_path :"lolita/list" #=> [path_to_lolita]/app/helpers/components/lolita/list_component.rb
      def component_helper_path component_name
         @helper_paths||=$:.reject{|p| !p.match(/\/helpers$/)}
         get_path=lambda{|paths|
          extra_path=component_name.to_s.split("/")
          component=extra_path.pop
          paths.each do |path|
            new_path=File.join(path,"components",*extra_path,"#{component}_component.rb")
               if File.exist?(new_path) 
                 return new_path
               end
            end  
          nil
        }
        path=get_path.call(@helper_paths)
        path
      end

      # Return locals for component that will be rendered next. Very useful in hook views, where is no locals.
      def component_locals
        @component_locals[@current_component_name]
      end
      
    end
  end
end