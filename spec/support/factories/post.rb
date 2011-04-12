Factory.define(:post, :class=>Post) do |f|
	f.title Faker::Lorem.sentence
  f.association :category
  f.after_create do |record|
    record.tags << Factory.create(:tag)
    record.save
  end
end
