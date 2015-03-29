module RedmineHelpdeskGPG
	module Patches
		module IssuePatch

			def self.included(base)
				base.send(:include, InstanceMethods)
				base.class_eval do
					unloadable # Send unloadable so it will not be unloaded in development
					has_one :gpg_journal, :dependent => :destroy # declare relation to gpg_journal
					accepts_nested_attributes_for :gpg_journal
				end
			end

			module InstanceMethods
				# any instance methods we want to add?
				# if not: also delete "base.send(:include, InstanceMethods)"
			end

		end
	end
end

unless Issue.included_modules.include?(RedmineHelpdeskGPG::Patches::IssuePatch)
  Issue.send(:include, RedmineHelpdeskGPG::Patches::IssuePatch)
end
