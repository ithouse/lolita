# coding:utf-8
Factory.define :"media/google_map" do |f|
  f.lat rand*180*(rand(2)==1 ? -1 : 1)
  f.lng rand*180*(rand(2)==1 ? -1 : 1)
  f.description "kaut kāds punkts kartē"
end
