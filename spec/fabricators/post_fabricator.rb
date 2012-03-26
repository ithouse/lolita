Fabricator(:post) do 
  title{Faker::Lorem.sentence}
  category
end
