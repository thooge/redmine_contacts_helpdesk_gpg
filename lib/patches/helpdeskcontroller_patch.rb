require_dependency 'helpdesk_controller'

module RedmineHelpdeskGPG
	module Patches
		module HelpdeskControllerPatch

			def self.included(base) # :nodoc:
				base.send(:include, InstanceMethods)

				base.class_eval do
					unloadable # Send unloadable so it will not be unloaded in development

				# store also settings for gpg encryption/signature
				alias_method_chain :set_settings, :gpg
				alias_method_chain :set_settings_param, :gpg
				end
			end # self.included

			module InstanceMethods
			
				def set_settings_with_gpg
					set_settings_param(:gpg_decrypt_key)
					set_settings_param(:gpg_decrypt_key_password)

					set_settings_param(:gpg_sign_key)
					set_settings_param(:gpg_sign_key_password)

					set_settings_param(:gpg_send_default_action)
					
					set_settings_without_gpg # call original method
				end #def set_settings_gpg

				def set_settings_param_with_gpg(param)
					if param == :gpg_decrypt_key_password || param == :gpg_sign_key_password
					  ContactsSetting[param, @project.id] = params[param] if params[param] && !params[param].blank?
					else
					  set_settings_param_without_gpg(param)
					end
				end # set_settings_param_with_gpg
				
			end # module InstanceMethods
		
		end #module HelpdeskControllerPatch
	end # module Patches
end # module RedmineHelpdeskGPG

unless HelpdeskController.included_modules.include?(RedmineHelpdeskGPG::Patches::HelpdeskControllerPatch)
	HelpdeskController.send(:include, RedmineHelpdeskGPG::Patches::HelpdeskControllerPatch)
end
