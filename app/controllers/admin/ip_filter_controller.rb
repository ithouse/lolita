class Admin::IpFilterController < Managed
  allow Admin::Role.admin

  private

  def after_edit
    @object=Admin::IpFilter.find_by_sql("SELECT id,active,name,created_at,updated_at,INET_NTOA(start_address) AS start_address,INET_NTOA(end_address) as end_address FROM admin_ip_filters WHERE id=#{@object.id}").first
  end

  def config
    {
      :tabs=>[{:type=>:content,:in_form=>true,:opened=>true,:fields=>:default}],
      :fields=>[
        {:type=>:text,:field=>:name,:html=>{:maxlenght=>255}},
        {:type=>:text,:field=>:start_address},
        {:type=>:text,:field=>:end_address},
        {:type=>:checkbox,:field=>:active}
      ],
      :list=>{
        :select=>"id,active,name,created_at,updated_at,INET_NTOA(start_address) AS start_address,INET_NTOA(end_address) as end_address ",
        :partial=>:default,
        :columns=>[
          {:field=>:name,:link=>true,:default=>true},
          {:field=>:start_address},
          {:field=>:end_address},
          {:field=>:active}
        ],
        :sortable=>true,
        :sort_column=>"start_address",
        :sort_direction=>"asc",
        :options=>[:destroy]
      }
    }
  end
end
