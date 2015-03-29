class GpgJournal < ActiveRecord::Base
	unloadable
	belongs_to :issue
	belongs_to :journal

   
	def helpdesk_ticket
		journal.issue.helpdesk_ticket    
	end   
end
