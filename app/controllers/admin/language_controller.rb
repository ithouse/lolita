class Admin::LanguageController < Managed
  allow
  private

  def config
    {
      :tabs=>[
        {:type=>:content,:fields=>:default,:in_form=>true,:opened=>true}
      ],
      :list=>{
        :sort_column=>'is_base_locale',
        :sort_direction=>'asc',
        :options=>[:edit,:destroy],
      },
      :fields=>[
        {:type=>:text,:field=>:globalize_languages_id},
        {:type=>:checkbox,:field=>:is_base_locale}
      ]
    }
  end
end