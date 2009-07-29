module Extensions
  module Cms
    module HandleRelations
      protected
      #Funkcija domāta lai varētu vispārinātā veidā veidot daudzmoduļu tabulu vienā
      #elementā 'list' un to apstrādāt vienotā stilā
      #TODO vēl ir jāpilnveido izskats un dažas lietas lietotāja pusē, bet šī funkcija ir pareiza
#      def handle_has_many_polimorphic_relation save=false
#        @relations_polimorphic={} if ! @relations_polimorphic
#        if  @relations_polimorphic.empty?
#          get_parents_from_params my_params[:object],false,"_remote_list" do |key,value|
#            @relations_polimorphic[key]=value
#            my_params[:object].delete(key)
#          end
#        end
#        if save
#          # Izlasu arā visas dažādās tabulas no lauku saraksta
#          #Ierakstu tās masīvā ['user','role',utt]
#          my_fields=current_fields
#          tables=[]
#          my_fields.each_with_index{|value,key|
#            value[:fields].each{|value2|
#              tables<<value2[:table] unless tables.include?(value2[:table])
#            } if value[:type]=='list'
#          }
#          @relations_polimorphic.each{|key,value|
#            table_name=key.sub(/_remote_list/,"")
#            name=table_name.pluralize # like phone or email
#            obj=table_name.camelize.constantize
#            # @object.send(name).delete_all
#            old_objects=@object.send(name)
#            new_objects=[]
#            if value.respond_to?("each")
#              value.each{|ridx,row|       #ridx=0.3434624362346 and row={:number_1=>1111,name_2=>asdf}
#                if row.respond_to?("each")
#                  row_objects={}
#                  updatable=false
#                  updatable_id=0
#                  row.each{|col_name,cell_value|      #like number_1 and number_1_hidden
#                    if !((col_name=~/_hidden/)!=nil)  # pārbauda vai nav hidden lauks kas nosaka vai ir rediģēts
#                      existing=row.key?(col_name+'_hidden') #pārbauda vai lauks ir jāupdeito
#                      updatable_id=row[col_name+'_hidden'] if existing                      #vecais id
#                      updatable=updatable || existing
#                      if cell_value  && cell_value.size>0                      #tukšos igonorēju bet ja tas jau eksistējis tad tiks dzēsts
#                        col=col_name.sub(/_[0-9]{1,}/,"") #from asdf_1111 to asdf
#                        row_objects[col.to_sym]=cell_value
#                      end
#                    end
#                  }
#                  unless row_objects.empty?
#                    if updatable
#                      new_object=obj.find(updatable_id)
#                      new_object.update_attributes(row_objects)
#                    else
#                      new_object=obj.create(row_objects)
#                      # new_object.save!
#                      @object.send(name)<<new_object
#                    end
#                    new_objects<<new_object
#                  end
#                end
#              }
#            end
#            dif_objects=old_objects-new_objects #iegūstu tos kas bijuši pirms tam bet nu nav (dzēsti)
#            dif_objects.each{|d_obj|
#              d_obj.destroy
#              @object.send(name).delete(d_obj)
#            }
#            tables.delete(table_name)
#          }
#          #Dzēšu visus tos kuriem nav bijis neviens ieraksts tādēļ parametros tie neuzrādījās
#          tables.each{|table|
#            dif_objects=@object.send(table.pluralize)
#            dif_objects.each{|d_obj|
#              d_obj.destroy
#              @object.send(table.pluralize).delete(d_obj)
#            }
#          }
#          @relations={}
#        end
#      end
      #Funkcija apstrādā 1 pret n saiti, kas tiek saņemta ja ir izmantoti 'checkbox'
      #elements ievades formā, kur tekošajam elementam var tikt piesaistīti vairāki cita
      #moduļa elementi
      def handle_has_many_relation
        @config[:tabs].each{|tab|
          tab_fields(tab).each{|field|
            if field[:type].to_sym==:checkboxgroup && my_params[tab[:object]||:object] && my_params[tab[:object]||:object][field[:field]]
              remote_object=object.reflect_on_association(field[:field]).klass
              my_params[tab[:object]||:object][field[:field]].collect!{|id| remote_object.find_by_id(id)}.compact!
            end
          }
        }
      end
    end #module end
  end
end