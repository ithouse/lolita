Factory.define :"admin/user" do |f|
  f.sequence(:login){|n| "user_#{n}"}
  f.sequence(:email){|n| "user_#{n}@example.com"}
  f.password "123123"
  f.password_confirmation "123123"
end