class Location < ActiveRecord::Base
  WIKI_TAGS=["map"]
  belongs_to :mappable,  :polymorphic => true
end