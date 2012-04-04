module Lolita
  module Configuration
    class Action

      include Lolita::Builder
      lolita_accessor :url
      attr_writer :title,:html
      attr_reader :name

      def initialize(dbi,name, options ={}, &block)
        @dbi = dbi
        @name = name
        options.each do |key,value|
          self.send(:"#{key}=",value)
        end
        instance_eval(&block) if block_given?
      end

      def html attributes = nil
        if attributes
          @html = attributes
        else
          result = {}
          (@html || {}).each{|k,v|
            result[k] = v.respond_to?(:call) ? v.call : v
          }
          result
        end
      end

      def title value=nil
        if value
          @title = value
        else
          if @title
            @title.respond_to?(:call) ? @title.call : @title
          else
            ::I18n.t("#{@dbi.klass.to_s.underscore}.actions.#{@name}")
          end
        end
      end

      def view_url view, record
        if @url.respond_to?(:call)
          @url.call(view,record)
        else
          @url
        end
      end

    end
  end
end