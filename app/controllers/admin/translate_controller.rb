class Admin::TranslateController < Managed
  allow :role=>"system_admin", :all=>[:init_translations]

  def init_translations
    if request.xhr?
      translated={}
      Admin::Translate.js_translations.each{|key,value|
        translated[key]=t(value)
      }
      render :json=>translated,:layout=>false
    else
      render :nothing=>true
    end
  end
  def change_language_only
    @object_name=controller
    Globalize::Locale.set("#{params[:locale]}-#{params[:locale]=='en' ? "US" : params[:locale].upcase}")
    list
  end

  def translation_text
    @translation = Globalize::ViewTranslation.find(get_id)
    render :text => @translation.text || ""
  end

  def set_translation_text
    result=""
    params[:translation].each{|id,value|
      translation=Globalize::ViewTranslation.find(id)
      translation.update_attributes(:text=>value)
      result=value
    }if params[:translation] && params[:translation].is_a?(Hash)
    render :text=>result
  end

  private
  def config
    {
      :partials=>{
        :top=>["admin/translate/head"]
      },
      :object=>'globalize/view_translation',
      :overwrite=>true,
      :parent_name=>'admin/translate',
      :filter=>['built_in IS NULL AND language_id=?',Globalize::Locale.language.id],
      :filter_fields=>['tr_key','text'],
      :list=>{
        :sort_column=>'tr_key',
        :sort_direction=>'asc'
      }
    }
  end
end
