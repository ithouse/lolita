require 'managed_callbacks'
ActionController::Base.send(:include, Lolita::ManagedCallbacks)
