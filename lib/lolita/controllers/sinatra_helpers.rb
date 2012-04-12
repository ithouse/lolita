module Lolita
  module Controllers

    module SinatraHelpers
      include Lolita::Controllers::InternalHelpers

      def lolita_mapping=(new_mapping)
        @lolita_mapping = new_mapping
      end

      def paginate *args
        "-paginator-"
      end

      def raw string
        string
      end

      def csrf_meta_tag
        ""
      end
      # def image_tag image,options = {}
      #   options[:alt] ||= image
      #   attrs = __to_html_attr__(options)
      #   %Q{<img scr="/app/assets/images/#{image}" #{attrs} />}
      # end

      def __to_html_attr__(options = {})
        options.map{|k,v| %Q{#{k}="#{v}"}}.join(" ")
      end
    end

  end
end