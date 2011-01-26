Lolita.add_module :rest, :route=>true, :path=>File.expand_path(File.join(__FILE__,'..','modules'))
Lolita.default_module=:rest


#Lolita.add_module :pictures
# Lolita.use(:blogs)
# Lolita.use(:threads)
# Lolita.use :lolita-devise-admins
# require 'lolita-devise-users'
# /lolita/admins
# /lolita/admin/1/edit
#Lolita.add_module :statistic, :route=>true
# lolita/questions/statistic => lolita/statistic/index
# lolita_modules :statistic
# Lolita.mapping[:posts].to.lolita.modules.each do |m|
#   lolita_rest
#   lolita_statistic -> lolita/questions/statistic
#   lolita_gallery -> lolita/questions/add_image
#Lolita.mount :blog, :route=>true # lolita/blog

