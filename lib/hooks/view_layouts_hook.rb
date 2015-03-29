module RedmineHelpdeskGPG
	module Hooks
		class ViewsLayoutsHook < Redmine::Hook::ViewListener
			def view_layouts_base_html_head(context={})
				return stylesheet_link_tag(:helpdesk_gpg, :plugin => 'redmine_contacts_helpdesk_gpg')
			end
		end
	end
end