module Extensions
  module Cms
    module Extended
      protected 

#      def  handle_external_object_relations
#        #Ja ir nepieciešamie parametri lai veidotu saistību
#        #tie ir tikai tad ja lietotājs ir pārvaldnieks 'e_manager' loma
#        if params[:extended_objects]
#          #eju cauri visiem parametriem kur key='News' bet value ir yes/no 0/1 utt
#
#          params[:extended_objects].each{|key,value|
#            if key.to_s.include?('_base')
#              extended=key.to_s.sub(/_base/,"").to_sym
#              new=params[:extended_objects][extended] ? true : false
#
#              # extended=key.to_sym
#              # new=value!=0 # ir atķeksēts saistīt vai nē
#              #Ja sesijā eksistē arī tāds objekts tad rīkojos tālāk
#              if session[:external_objects][extended] && session[:external_objects][extended][:id]
#                #Speciāl gadījumi -2 un -1 visas mājas un visas pārvaldnieka mājas
#                if session[:external_objects][extended][:id].to_i==-2 || session[:external_objects][extended][:id].to_i==-1
#                  #jaunais gadījums ir tā kad sameklē pārvaldnieka lomu un to saista klāt
#                  #bet saistītā objekta id vietā, tas ir piemēram House.id ir speciālie skaitļi (negatīvi)
#                  #šajā gadījumā -1 vai -2, kas norāda uz visām mājām vai konkrētā e_pārvaldnieka mājām
#                  #tika pievienots lietotāja id lauks kurā tad norāda lietotāju pēc kura tad arī var notiekt kuras ir viņa mājas
#                  #emanager_role=Role.find_by_name('e_manager').id
#                  if session[:external_objects][extended][:id].to_i==-2
#                    exo=ExternalObject.find_by_extendable_and_extended(@config[:object_name],@object.id,extended,session[:external_objects][extended][:id])
#                  else
#                    exo=ExternalObject.find(:first,
#                      :conditions=>["extendable_type=? and extendable_id=? and extended_id=? and extended_type=? and user_id=?",
#                        @config[:object_name].camelize,@object.id,session[:external_objects][extended][:id],extended.to_s.camelize,session[:user].id]
#                    )
#                  end
#                  if !exo
#                    if new
#                      #Gadījumā ja ir piesaistīts visām mājām vai kam citam tad ņoņem visas saistības
#                      clear_all_externals if session[:external_objects][extended][:id]==-2
#                      ExternalObject.create(:extendable_type=>@config[:object_name].camelize,:extendable_id=>@object.id,
#                        :extended_type=>extended.to_s.camelize,:extended_id=>session[:external_objects][extended][:id],:user_id=>session[:external_objects][extended][:id].to_i==-2 ? nil : session[:user].id)
#                    end
#                  else
#                    #ja eksistē objekts un nav tas jāpiesaista tad dzēš
#                    if !new
#                      exo.destroy()
#                      ExternalObject.delete(exo.id)
#                    end
#                  end
#                elsif session[:external_objects][extended][:id].to_i==-3
#                  #Izdzēšu visas sasaistes
#                  clear_all_externals
#                else
#                  #Ja izvēlēta viena konkrēta māja vai cits saistītais objekts, tad piesaista tā
#                  #lomu un pašu šim jaunizveidotajam objektam un viss
#                  role=Role.find(:first,:conditions=>"name='"+extended.to_s+"_"+session[:external_objects][extended][:id]+"'")
#                  if role
#                    exo=ExternalObject.find(:first,
#                      :conditions=>["extendable_type=? and extendable_id=? and extended_id=? and extended_type=? and role_id=?",
#                        @config[:object_name].camelize,@object.id,session[:external_objects][extended][:id],extended.to_s.camelize,role.id]
#                    )
#                  end
#                  #Vienas mājas gadījumā scenārijs ir līdzīgs taču tikai vienai mājai
#                  #TODO varbūt ir iespējams optimizēt kodu lai nebūtu visām un vienai mājai atsevišķi jāraksta
#                  if !exo
#                    if new
#                      ExternalObject.create(:extendable_type=>@config[:object_name].camelize,:extendable_id=>@object.id,
#                        :extended_type=>extended.to_s.camelize,:extended_id=>session[:external_objects][extended][:id],:role_id=>role.id)
#                    end
#                  else
#                    if !new
#                      exo.destroy()
#                      ExternalObject.delete(exo.id)
#                    end
#                  end
#                end
#              end
#            end
#          }
#        end
#      end
    end #module end
  end
end