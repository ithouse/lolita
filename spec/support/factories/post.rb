Factory.define(:post, :class=>Post) do |f|
	f.title Faker::Lorem.sentence
  f.association :category
end
