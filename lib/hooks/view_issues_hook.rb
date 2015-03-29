module RedmineHelpdeskGPG
	module Hooks
		class ViewIssuesHook < Redmine::Hook::ViewListener
			render_on :view_issues_edit_notes_bottom, :partial => 'issues/gpg_send_response'
			render_on :view_issues_show_details_bottom, :partial => 'issues/gpg_ticket_data'
			
			def view_issues_form_details_bottom(context={ })
				stylesheet_link_tag(:helpdesk_gpg, :plugin => 'redmine_contacts_helpdesk_gpg')
			end
			
		end
	end
end
