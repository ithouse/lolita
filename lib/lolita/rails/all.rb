require 'lolita/mapping'
require 'lolita/rails'
require 'lolita/modules'

Lolita::Hooks::NamedHook.add(:components)
Lolita::Hooks.components.class_eval{
  add_hook :before,:after,:around
}