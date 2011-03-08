module Lolita
  module Controllers
  	# Helper that add #render_component method. That is shortstand for render :partial for lolita
  	# partial files. Also it provide view hooks for Lolita.
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
        @opts=args.extract_options!
        name=args[0]
        state=args[1]
        raise "Can't render component without name!" unless name
        return render(:partial=>"/components/#{name}#{state ? "/#{state}" : nil}",:locals=>@opts)
      end
    end
  end
end