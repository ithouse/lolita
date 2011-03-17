module Lolita
	module Hooks
		# Lolita::Hooks.component("lolita/list").before

		class Component < Lolita::Hooks::Base

			define_callback :before,:after,:replace_with
			
			def initialize(name)

			end

		end
	end
end