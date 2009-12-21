module Lolita
  # MigrationHack add *ENGINE* and *CHARSET* to every table migrated with rails
  # unless that is specified in method call.
  module MigrationHack #:doc:

    def self.included(base)
      base.class_eval{
        include InstanceMethods
      }
      base.alias_method_chain :create_table, :utf8encoding
    end

    module InstanceMethods
      def create_table_with_utf8encoding(table_name,options={}, &block)
        options[:options]||='ENGINE=InnoDB DEFAULT CHARSET=utf8'
        create_table_without_utf8encoding(table_name,options,&block)
      end

    end

  end
end