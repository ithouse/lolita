module Lolita
  module Configuration
    class Action

      include Lolita::Builder
      lolita_accessor :url
      attr_writer :title
      attr_reader :name

      def initialize(dbi,name, options ={}, &block)
        @dbi = dbi
        @name = name
        options.each do |key,value|
          self.send(:"#{key}=",value)
        end
        instance_eval(&block) if block_given?
      end

      def title value=nil
        if value
          @title = value
        else
          @title || ::I18n.t("#{@dbi.klass.to_s.underscore}.actions.#{@name}")
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