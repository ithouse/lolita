class Category < ActiveRecord::Base
  include Lolita::Configuration
  has_many :posts

  lolita do
    list do
      list(:posts) do
        column :comments do
          list do
            column :body
          end
        end
      end
    end
  end
end
