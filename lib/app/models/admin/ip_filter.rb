class Admin::IpFilter < Cms::Manager
  set_table_name :admin_ip_filters
  attr_writer :start_address
  attr_writer :end_address
  
  def self.must_filter?
    self.find(:first,:conditions=>["active=?",true]) ? true : false
  end

  def start_address
    @attributes['start_address']
  end

  def end_address
    @attributes['end_address']
  end
  
  def update_attributes! attributes={}
    sql = ActiveRecord::Base.connection();
    begin
      sql.execute "SET autocommit=0";
      sql.begin_db_transaction
      sql_time=Time.now.strftime("%Y:%m:%d %H:%M:%S")
      statement="UPDATE admin_ip_filters SET "
      update_columns=[]
      update_columns<<"`name`='#{attributes[:name].to_s.gsub(/'/,"\'")}'" if attributes.has_key?(:name)
      update_columns<<"`start_address`=INET_ATON('#{attributes[:start_address]}')" if attributes.has_key?(:start_address)
      update_columns<<"`end_address`=#{attributes[:end_address] ? "INET_ATON('#{attributes[:end_address]}')" : ""}" if attributes.has_key?(:end_address)
      update_columns<<"`active`=#{attributes[:active]==false || attributes[:active].to_i==0 ? 0 : 1}" if attributes.has_key?(:active)
      update_columns<<"`updated_at`='#{sql_time}'"
      if update_columns.size>1
        attributes.each{|key,value|
          self.send("#{key}=",value)
        }
        self.updated_at=Time.now
        statement="#{statement}#{update_columns.join(",")}"
        
      end
      sql.update(statement)
      sql.commit_db_transaction
      #return Admin::IpFilter.find_by_id(self.id)
    rescue=>e
      raise ActiveRecord::RecordNotSaved
      sql.rollback_db_transaction
    end
  end
  
  def save! 
    sql = ActiveRecord::Base.connection();
    begin
      sql.execute "SET autocommit=0";
      sql.begin_db_transaction
      sql_time=Time.now.strftime("%Y:%m:%d %H:%M:%S")
      statement="INSERT INTO admin_ip_filters (`name`,`start_address`,#{self.end_address ? "`end_address`," : ""}`active`,`created_at`,`updated_at`)
         VALUES('#{self.name.to_s.gsub(/'/,"\'")}',INET_ATON('#{self.start_address}'),#{self.end_address ? "INET_ATON('#{self.end_address}')," : ""}#{self.active ? 1 : 0},'#{sql_time}','#{sql_time}' )"
      id=sql.insert(statement)
      sql.commit_db_transaction
      #return Admin::IpFilter.find_by_id(id)
    rescue=>e
      raise ActiveRecord::RecordNotSaved
      sql.rollback_db_transaction
    end
  end
  
  def self.is_trusted?(ip)
    found=self.find(:first,:conditions=>["active=1 AND ((INET_ATON(?)=start_address OR INET_ATON(?)=end_address) OR (INET_ATON(?)>start_address AND INET_ATON(?)<end_address))",ip,ip,ip,ip])
    found ? true : false
  end

  protected
  
end
