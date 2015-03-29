module RedmineHelpdeskGPG
	module Patches
		module JournalPatch

			def self.included(base) # :nodoc:
				base.send(:include, InstanceMethods)
				base.class_eval do
					unloadable # Send unloadable so it will not be unloaded in development
					has_one :gpg_journal, :dependent => :destroy # declare relation to gpg_journal
				end
			end

			module InstanceMethods

				def was_signed?
					self.gpg_journal && self.gpg_journal.was_signed?
				end

				def was_encrypted?
					self.gpg_journal && self.gpg_journal.was_encrypted?
				end

			end

		end
	end
end

unless Journal.included_modules.include?(RedmineHelpdeskGPG::Patches::JournalPatch)
  Journal.send(:include, RedmineHelpdeskGPG::Patches::JournalPatch)
end
