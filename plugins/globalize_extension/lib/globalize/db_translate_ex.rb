# Add custom methods to globalize -> db_translate
module Globalize # :nodoc:
  module DbTranslate  # :nodoc:

    module ClassMethods # :nodoc:
      alias_method :pulp_old_translates, :translates
      def translates(*facets)
        class_eval <<-CLASS
          after_save :save_translations
        CLASS
        
        pulp_old_translates(*facets)
      end
    end
    
    module TranslateClassMethods # :nodoc:
#      def after_switch_language_callback_chain(*callbacks, &block)
#        callbacks << block if block_given?
#        write_inheritable_array(:after_switch_language, callbacks)
#      end
#      
#      def before_switch_language_callback_chain(*callbacks, &block)
#        callbacks << block if block_given?
#        write_inheritable_array(:before_switch_language, callbacks)
#      end
      
      private
        
        def find_every(options)
          return globalize_old_find_every(options) if options[:untranslated]
          #raise StandardError, 
           # ":select option not allowed on translatable models " +
           # "(#{options[:select]})" 
      if options[:select] && !options[:select].empty? #artūrs meisters
            records = scoped?(:find, :include) || options[:include] ?
            find_with_associations(options) :
            find_by_sql(construct_finder_sql(options))

            records.each { |record| record.readonly! } if options[:readonly]

            records
       else #artūrs meisters           
          # do quick version if base language is active
          if Locale.base? && !options.has_key?(:include_translated) 
            results = globalize_old_find_every(options) 
            results.each {|result|
              result.set_original_language
            }
            return results
          end

          options[:conditions] = sanitize_sql(options[:conditions]) if options[:conditions]

          # there will at least be an +id+ field here
          select_clause = untranslated_fields.map {|f| "#{table_name}.#{f}" }.join(", ")

         # joins_clause = options[:joins].nil? ? "" : options[:joins].dup
          joins_clause = options[:joins].nil? ? "" : add_joins!("",options)    #artūrs meisters
          joins_args = []
          load_full = options[:translate_all]
          facets = load_full ? globalize_facets : preload_facets

          if Locale.base?
            select_clause <<  ', ' << facets.map {|f| "#{table_name}.#{f}" }.join(", ")
          else
            language_id = Locale.active.language.id
            load_full = options[:translate_all]
            facets = load_full ? globalize_facets : preload_facets
            
=begin
          There's a bug in sqlite that messes up sorting when aliasing fields, 
          see: <http://www.sqlite.org/cvstrac/tktview?tn=1521,33>.

          Since I want to use sqlite, and sorting, I'm hacking this to make it work.
          This involves renaming order by fields and adding them to the SELECT part. 
          It's a sucky hack, but hopefully sqlite will fix the bug soon.
=end

            # sqlite bug hack          
            select_position = untranslated_fields.size

            # initialize where tweaking
            if options[:conditions].nil?
              where_clause = ""
            else
              if options[:conditions].kind_of? Array          
                conditions_is_array = true
                where_clause = options[:conditions].shift
              else
                where_clause = options[:conditions]
              end
            end

            facets.each do |facet| 
              facet = facet.to_s
              facet_table_alias = "t_#{facet}"

              # sqlite bug hack          
              select_position += 1
              options[:order].sub!(/\b#{facet}\b/, select_position.to_s) if options[:order] && sqlite?

              select_clause << ", COALESCE(#{facet_table_alias}.text, #{table_name}.#{facet}) AS #{facet}, " 
              select_clause << " #{facet_table_alias}.text AS #{facet}_not_base " 
              joins_clause  << " LEFT OUTER JOIN globalize_translations AS #{facet_table_alias} " +
                "ON #{facet_table_alias}.table_name = ? " +
                "AND #{table_name}.#{primary_key} = #{facet_table_alias}.item_id " +
                "AND #{facet_table_alias}.facet = ? AND #{facet_table_alias}.language_id = ? "
              joins_args << table_name << facet << language_id            
              
              #for translated fields inside WHERE clause substitute corresponding COALESCE string
              #Artūrs Meisters changed because match incorrect when () used around field name
             #where_clause.gsub!(/((((#{table_name}\.)|\W)[`"]?#{facet}[`"]?)|^`?#{facet}`?)\W/, "COALESCE(#{facet_table_alias}.text, #{table_name}.#{facet}) ")
              where_clause.gsub!(/`/,"") #Artūrs Meisters add line lai būtu korekta pārveide
              where_clause.gsub!(/((((#{table_name}\.)|\W)[`"]?#{facet}[`"]?)|^`?#{facet}`?)/,   "COALESCE(#{table_name}.#{facet},#{facet_table_alias}.text)") #Artūrs Meisters COALESCE(#{facet_table_alias}.text,#{table_name}.#{facet}))
            end
            options[:conditions] = sanitize_sql( 
              conditions_is_array ? [ where_clause ] + options[:conditions] : where_clause 
            ) unless options[:conditions].nil?          
          end

          # add in associations (of :belongs_to nature) if applicable
          associations = options[:include_translated] || []
          associations = [ associations ].flatten
          associations.each do |assoc|
            rfxn = reflect_on_association(assoc)
            assoc_type = rfxn.macro
            raise StandardError, 
              ":include_translated associations must be of type :belongs_to;" +
              "#{assoc} is #{assoc_type}" if assoc_type != :belongs_to
            klass = rfxn.klass
            assoc_facets = klass.preload_facets
            included_table = klass.table_name
            included_fk = klass.primary_key
            fk = rfxn.options[:foreign_key] || "#{assoc}_id"
            assoc_facets.each do |facet|
              facet_table_alias = "t_#{assoc}_#{facet}"

             if Locale.base?
                select_clause << ", #{included_table}.#{facet} AS #{assoc}_#{facet} "
              else            
                select_clause << ", COALESCE(#{facet_table_alias}.text, #{included_table}.#{facet}) " +
                  "AS #{assoc}_#{facet} "
                joins_clause << " LEFT OUTER JOIN globalize_translations AS #{facet_table_alias} " +
                  "ON #{facet_table_alias}.table_name = ? " +
                  "AND #{table_name}.#{fk} = #{facet_table_alias}.item_id " +
                  "AND #{facet_table_alias}.facet = ? AND #{facet_table_alias}.language_id = ? "
                joins_args << klass.table_name << facet.to_s << language_id                        
              end                        
            end
            joins_clause << "LEFT OUTER JOIN #{included_table} " + 
                "ON #{table_name}.#{fk} = #{included_table}.#{included_fk} "
          end

          options[:select] = select_clause
          options[:readonly] = false
# 
          sanitized_joins_clause = sanitize_sql( [joins_clause , *joins_args] )        
          options[:joins] = sanitized_joins_clause
          results = globalize_old_find_every(options)

          results.each {|result|
            result.set_original_language
            result.fully_loaded = true if load_full
          }
          
          return results
          end
        end
        
    end
    
    module TranslateObjectMethods # :nodoc:
      # switch_language callbacks
    #  def after_switch_language_callback_chain() end
    #  def before_switch_language_callback_chain() end
      
      # call the attribute method for each given language
      # if no languages are given, it is assumed that all
      # attributes keys match a language.
      #
      # So you can send a params dict which contain keys 
      # like { :title => {:fr => 'Mon Titre', :en => 'My Title'} }
      def set_globalized_attributes(attributes, languages=nil)
        attributes = attributes.symbolize_keys
        languages = attributes.keys if languages.nil?
        languages.each do |language|
          language = language.code if language.kind_of? Language
          if attrs = attributes.delete(language.to_sym)
            switch_language(language.to_s) do
              self.attributes= attrs
            end
          end
        end
      end
      
      # Save the loaded translations of the current model
      # Only the translatable fields are saved while other is kept
      # to the current product value. The current values are set
      # to the last time saved model in the current language
      def save_translations
        return true unless translation_cache
        
        translation_cache.each do |code, attrs|
          switch_language(code) do
            @attributes.update attrs
            update_translation
          end
        end
        true
      end
      
      protected
        attr_accessor :translation_cache
      
      private
      
        # Update the model language for the model and all its loaded association.
        # The old translation is cached to make multi languages update at once.
        def operate_switch_language(code)
          #callback(:before_switch_language)
          @translation_cache = {} if @translation_cache.nil?
          facet_names = self.class.globalize_facets
          @translation_cache[language_code] = @attributes.dup.delete_if {|key, value| !facet_names.include? key.to_sym}
          Locale.switch(code) do
            set_original_language
            if @translation_cache.include? code
              @attributes.update @translation_cache[code]
            elsif @original_language == Locale.base_language and !@new_record
              reload
            elsif !@new_record
              trs = ModelTranslation.find(:all, 
                :conditions => [ "table_name = ? AND item_id = ? AND language_id = ? AND " +
                "facet IN (#{[ '?' ] * facet_names.size * ', '})", self.class.table_name,
                self.id, @original_language.id ] + facet_names.map {|facet| facet.to_s} )
              trs ||= []
              trs.each do |tr|
                attr = tr.text || base[tr.facet.to_s]
                write_attribute( tr.facet, attr )
              end
            end
            
            operate_switch_language_on_associations(code)
            
            #callback(:after_switch_language)
          end
        end
    end
  end
end