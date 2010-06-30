module ControllerExtensions
  module Cms
    module Crud
      # Open new _object_ form. For detail see #ControllerExtensions
      def new
        params[:action]="create"
        handle_before_create
        handle_function "before_new"
        @metadata=MetaData.new(my_params[:metadata]) if has_tab_type?(:metadata)
        @object=object.new(params[:object])
        handle_function "after_new"
        set_parent_values_to_object
        redirect_me :only_render=>true, :layout=>self_layout
      end

      # Create new _object_. For detail see _code_ and/or #ControllerExtensions
      def create
        return false unless request.post?
        begin
          params[:action]="create"
          handle_before_create
          manage_nested_params
          handle_special_fields(true)
          MetaData.transaction do
            handle_has_many_relation
            handle_function "before_create"
            @object=assign_object_attributes() unless @object
            @object.save!
            if @object.errors.empty?
              handle_metadata
              handle_after_create
              handle_after_save
              handle_function "after_create"
              redirect_step_back? ? redirect_me(:step_back=>true) : redirect_me
            else
              redirect_me :error=>true
            end
          end
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          handle_function "on_save_error"
          handle_invalid_record_metadata
          redirect_me :error=>true
        end
      end

      # Open existing _object_ form for editing. For details see _code_.
      def edit
        params[:action]="update"
        if (my_params[:id].to_i==0)  && !my_params[:object]
          redirect_to :action=>"new", :all=>@config[:all_params]
        else
          handle_function "before_edit"
          @object=object.find_by_id(my_params[:id])
          @metadata=MetaData.by_metaable(@object.id,@config[:object_name]) || MetaData.new
          handle_function "after_edit"
          redirect_me :only_render=>true, :layout=>self_layout
        end
      end

      # Update existing _object_. For details see _code_ and/or #ControllerExtensions
      def update
        return false if !(request.post? || request.put?)
        begin
          params[:action]='update'
          manage_nested_params
          handle_special_fields(true)
          @object=object.find_by_id(my_params[:id])
          return false unless @object
          @translation=@object.clone if Lolita.config.i18n :translation
          @metadata=get_crud_metadata_object
          if my_params[:object]
            if Lolita.config.i18n(:translation) && my_params[:translation]
              current_language=params[:translation_locale]
              #base_lang = session[:locale] || Admin::Language.find_base_language.short_name
              #jf: session[:locale] may come from frontend and mess up backend
              base_lang = Lolita.config.i18n :language_code || Admin::Language.find_base_language.short_name
              Globalize::Locale.set("#{base_lang}-#{base_lang=='en' ? "US" : base_lang.upcase}")
              @object=object.find_by_id(my_params[:id])
            end            
            MetaData.transaction do
              handle_function "before_update"
              handle_has_many_relation
              if Lolita.config.i18n(:translation) && my_params[:translation]
                @object.switch_language(current_language) do
                  assign_object_attributes(@object,my_params[:translation])
                  @object.save!
                end
              end
              assign_object_attributes(@object)
              @object.save!
              if @object.errors.empty?
                handle_metadata()
                handle_special_fields()
                handle_menu()
                handle_after_save()
                handle_function "after_update"
                redirect_me
              else
                redirect_me :error=>true, :layout=>true
              end
            end
          else
            redirect_me :error=>true, :layout=>true
          end
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          handle_function "on_save_error"
          handle_invalid_record_metadata
          redirect_me :error=>true
        end
      end

      # Destroy _object_ by receiving <tt>params[:list_check]</tt> and called to_array on that <tt>String</tt>
      # and destroy all _objects_ that could be found from _ids_ in that <tt>Array</tt>
      # Or receive <tt>params[:id]</tt> and try to find and destroy _object_ from it.
      def destroy
        handle_function "before_destroy"
        if my_params[:list_check]
          if my_params[:list_check].is_a?(String)
            my_params[:list_check]=my_params[:list_check].to_array
          end
          if my_params[:list_check].respond_to?("each")
            my_params[:list_check].each{|id|
              rec=object.find_by_id(id)
              rec.destroy() if rec
            }
          end
        else
          rec=object.find_by_id(my_params[:id])
          rec.destroy if rec
        end
        handle_function "after_destroy"
        redirect_me
      end

      #Handles updating of existing habtm objects as generated
      #by by :type=>:multi_input in your controllers config.
      #Parameters are interceipted and passed from <tt>assign_object_attributes</tt>, where:
      #
      #* <tt>obj</tt> - is the parent object e.g. post
      #* <tt>attr</tt> - is the attribute of the habtm relation, e.g. +comments+, that are
      #  prepended with "multi_input_existing_", by the cms_multi_input_field helper
      #* <tt>hash</tt> - is the portion of (POST) params in form of <i>id of bound object=>
      #  array of bound object attributes</i>.
      #  
      #  E.g. if <tt>{:type=>:multi_input,:field=>:post_comments}</tt> is provided in your config :fields
      #  an input with the name
      #   object[multi_input_existing_post_comments][2][name]
      #  is created in HTML and processed here, whereas <tt>hash</tt> will have a value equivalent
      #  to <tt>{'2'=>{:name=>'some value'}</tt>,...},
      #  meaning set the <tt>:name</tt> attribute of the <i>bound post_comment</i>
      #  with +id+=2 to <i>'some value'</i>
      #
      #<b>NOTE:</b> a hidden input field with a name of
      #<tt>{object}[multi_input_existing_{attr}][*hook*]</tt>
      #is present in the post data to interceipt a case where all existing options are marked deletable.
      def multi_input_existing obj,attr,hsh
        hsh.delete('hook')
        if hsh.empty?
          obj.send(attr).destroy_all
        else
          hsh.each { |id,args|
            if my_params[:object]["multi_input_deletable_existing_#{attr}"].nil? ||
                my_params[:object]["multi_input_deletable_existing_#{attr}"][id.to_s].nil?
              assoc=obj.send(attr).find_by_id(id.to_i)
              assoc.update_attributes( args ) if assoc
            end
          }
        end
      end
      
      #Handles the destoying of existing related habtm objects as generated
      #by by :type=>:multi_* in your controllers config.
      #Parameters are interceipted and passed from <tt>assign_object_attributes</tt>, where:
      #
      #* <tt>obj</tt> - is the parent object e.g. post
      #* <tt>attr</tt> - is the attribute of the habtm relation, e.g. +comments+, that are
      #  prepended with "multi_input_deletable_existing_", by the cms_multi_input_field helper
      #* <tt>hash</tt> - is the portion of (POST) params in form of <i>id of bound object=>
      #  array of bound object attributes</i>.
      #
      #  E.g. if <tt>{:type=>:multi_input,:field=>:post_comments}</tt> is provided in your config :fields
      #  an input with the name
      #   object[multi_input_deletable_existing_post_comments][2][name]
      #  is created in HTML and processed here, whereas <tt>hash</tt> will have a value equivalent
      #  to <tt>{'2'=>{:name=>'some value'}</tt>,...}, meaning to delete the <i>bound post_comment</i>
      #  with +id+=2
      def multi_input_deletable_existing obj,attr,hsh
        klass=attr.singularize.camelize.constantize
        klass.find( :all,
          :conditions=>[ "#{klass.primary_key} IN(?)", hsh.collect{|id,value| id} ]
        ).each{ |assoc_element| assoc_element.destroy }
      end

      #Handles the creation of new related habtm objects as generated
      #by by :type=>:multi_* in your controllers config.
      #Parameters are interceipted and passed from <tt>assign_object_attributes</tt>, where:
      #
      #* <tt>obj</tt> - is the parent object e.g. post
      #* <tt>attr</tt> - is the attribute of the habtm relation, e.g. +comments+, that are
      #  prepended with "multi_input_new_", by the cms_multi_input_field helper
      #* <tt>hash</tt> - is the portion of (POST) params in form of
      #  <i>auto generated client-side id=>array of bound object attributes</i>
      #  E.g. if <tt>{:type=>:multi_input,:field=>:post_comments}</tt> is provided in your config :fields
      #  an input with the name
      #   object[multi_input_new_post_comments][][name]
      #  is created in HTML and processed here, whereas <tt>hash</tt> will have a value equivalent
      #  to <tt>{'1'=>{:name=>'some value'}</tt>,...}, where <b>the +id+ part is ignored</b>.
      def multi_input_new obj,attr,collection
        obj.send(attr).reload()#won't succeed otherwise
        if collection.is_a?(Array)
          collection.each { |args|
            begin
              #obj.send("build_#{attr}",args)[.save]/obj.send(attr).build/create
              #don't [always] work; most probably on obj.new_record
              attr.singularize.camelize.constantize.create( args.merge({
                    "#{obj.class.to_s.singularize.downcase}_#{obj.class.primary_key}".to_sym=>
                      obj.send(obj.class.primary_key)
                  }) )
            rescue
              obj.errors.add("Subelement #{args.to_yaml}",'probably repeated')
            end
          }
        else
          collection.each{|meaningless_id,args|
            obj.send(attr).build(args)
          }
        end
      end

      private

      def assign_object_attributes(obj=nil,data=nil)
        date_times={}
        obj=object.new unless obj
        (data || my_params[:object]).each{|k,v|
          if k.match('multi_input') && !obj.respond_to?(:"#{k}=")
            parts=k.match(/(multi_input_(?:deletable_existing|existing|new))_(.+)/)
            self.send(parts[1],obj,parts[2],v) #e.g. multi_input_new(obj,"existing_options",hash)
          elsif k.to_s.match(/\((\d+i)\)/) # collecting date and datetime values for further usage
            date_index=$1.dup
            attr_name=k.to_s.gsub(/\(\d+i\)/,"")
            date_times[attr_name]||={}
            date_times[attr_name][date_index]=v
          else
            obj.send(:"#{k}=",v)
          end
        }
        # set date and datetime values
        date_times.each{|attr,values|
          periods=values.sort.collect{|pair| pair.last}
          obj.send(:"#{attr}=",Time.local(*periods))
        }
        obj
      end
    end
  end
end
