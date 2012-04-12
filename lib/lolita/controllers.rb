require 'lolita/controllers/internal_helpers'
require 'lolita/controllers/url_helpers'
require 'lolita/controllers/component_helpers'
require 'lolita/controllers/authentication_helpers'

require 'lolita/controllers/sinatra_helpers'
require 'lolita/controllers/sinatra_url_helpers'
require 'lolita/controllers/rails_helpers'

Lolita::Hooks::NamedHook.add(:components)
Lolita::Hooks.components.class_eval{
  add_hook :before,:after,:around
}