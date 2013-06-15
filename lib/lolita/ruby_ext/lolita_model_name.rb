module Lolita
  class ModelName
    def initialize(given_class)
      @klass = given_class
      @class_name = @klass.to_s
    end

    def human(options={})
      name = if defined?(ActiveRecord::Base) && @klass.ancestors.include?(ActiveRecord::Base)
        "activerecord.models.#{@class_name.underscore}"
      else
        "lolita.models.#{@class_name.underscore.gsub("/",".")}"
      end
      ::I18n.t("#{name}.#{prefix(options)}", default: default_human_name(options))
    end

    private

    def default_human_name options = {}
      if prefix(options) == 'one'
        @class_name.humanize
      else
        ActiveModel::Naming.plural(@klass).humanize
      end
    end

    def prefix options
      if options[:count]
        if options[:count] == 1
          "one"
        else
          "other"
        end
      else
        "one"
      end
    end
  end
end

Object.class_eval do
  def lolita_model_name
    @lolita_model_name ||= Lolita::ModelName.new(self)
  end
end