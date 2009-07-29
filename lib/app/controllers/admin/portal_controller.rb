class Admin::PortalController < Managed
  allow :role=>Admin::Role.admin

  private

  def config
    {
      :tabs=>[{:type=>:content,:in_form=>true,:fields=>:default,:opened=>true}],
      :list=>{
        :partial=>:default,
        :sortable=>true,
        :options=>[:edit,:destroy],
        :columns=>[
          {:link=>true,:field=>:domain,:width=>400,:default=>true,:sortable=>true},
          {:field=>:root,:width=>80,:sortable=>false}
        ]
      },
      :fields=>[
        {:type=>:text,:field=>:domain,:html=>{:maxlength=>255}},
        {:type=>:checkbox,:field=>:root}
      ]
    }
  end
end
