module ActionView
  module Helpers
    module ActiveRecordHelper
      # Returns a string with a div containing all of the error messages for the objects located as instance variables by the names
      # given.  If more than one object is specified, the errors for the objects are displayed in the order that the object names are
      # provided.
      #
      # This div can be tailored by the following options:
      #
      # * <tt>header_tag</tt> - Used for the header of the error div (default: h2)
      # * <tt>id</tt> - The id of the error div (default: errorExplanation)
      # * <tt>class</tt> - The class of the error div (default: errorExplanation)
      # * <tt>object_name</tt> - The object name to use in the header, or
      # any text that you prefer. If <tt>object_name</tt> is not set, the name of
      # the first object will be used.
      #
      # Specifying one object:
      # 
      #   error_messages_for 'user'
      #
      # Specifying more than one object (and using the name 'user' in the
      # header as the <tt>object_name</tt> instead of 'user_common'):
      #
      #   error_messages_for 'user_common', 'user', :object_name => 'user'
      #
      # NOTE: This is a pre-packaged presentation of the errors with embedded strings and a certain HTML structure. If what
      # you need is significantly different from the default presentation, it makes plenty of sense to access the object.errors
      # instance yourself and set it up. View the source of this method to see how easy it is.
      #
      # Adapted for Globalize Edge Rails by Claudio Poli (claudio@icoretech.org)
      def error_messages_for(*params)
        options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
        objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        count   = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'errorExplanation'
            end
          end
          header_message = "#{pluralize(count, 'error')} prohibited this #{(options[:object_name] || params.first).to_s.gsub('_', ' ').t} from being saved"
          error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }
          content_tag(:div,
            content_tag(options[:header_tag] || :h2, header_message) <<
              content_tag(:p, 'There were problems with the following fields:'.t) <<
              content_tag(:ul, error_messages),
            html
          )
        else
          ''
        end
      end
    end
  end
end
