Rails.configuration.to_prepare do
  require 'patches/helpdeskmailer_patch'
  require 'patches/helpdeskcontroller_patch'
  require 'patches/issue_patch'
  require 'patches/journal_patch'
end

#require_dependency 'gpgkeys'
require 'hooks/view_issues_hook'
require 'hooks/view_layouts_hook'
require 'hooks/view_journals_hook'

module HelpDeskGPG

	def self.settings() Setting[:plugin_redmine_contacts_helpdesk_gpg] ? Setting[:plugin_redmine_contacts_helpdesk_gpg] : {} end

	def self.keyrings_dir
		self.settings[:gpg_keyrings_dir]
	end

	def self.keyserver
		self.settings[:gpg_keyserver]
	end

	class Helper

		def self.engineInfos
			_res = []
			GPGME::Engine.info.each do |inf|
				_res.push("protocol='#{inf.instance_variable_get(:@protocol)}', @file_name='#{inf.instance_variable_get(:@file_name)}', @version='#{inf.instance_variable_get(:@version)}'")
			end
			_res
		end # self.engineInfos

		def self.keystoresize
			ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
			GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
			_ctx = GPGME::Ctx.new()
			_pub = _ctx.keys(nil, false)
			_priv = _ctx.keys(nil, true)
			_ctx.release
			return [_pub.length, _priv.length]
		end # self.keystoresize
		
		def self.keystoresizeP(proto) ### test: get values according to protocol
			ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
			GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
			_ctx = GPGME::Ctx.new({:protocol => proto})
			_pub = _ctx.keys(nil, false)
			_priv = _ctx.keys(nil, true)
			_ctx.release
			return [_pub.length, _priv.length]
		end
		
		def self.privateKeysSelectOptions
			_priv = GPGME::Key.find(:secret)
			_options = []
			for k in _priv do
				_label = "0x#{k.primary_subkey.fingerprint[-8 .. -1]} &lt;#{k.primary_uid.email}&gt;".html_safe
				_options.push([_label, k.primary_subkey.fingerprint])
			end
			_options
		end # self.privateKeysSelectOptions
		
		def self.shortenFingerprint(fpr)
			fpr[-8 .. -1]
		end # self.shortenFingerprint

		def self.sendDefaultsSelectOptions
			[[(I18n.translate :label_no_key), ''],
			 [(I18n.translate :label_gpg_action_sign), '1'],
			 [(I18n.translate :label_gpg_action_encrypt), '2'],
			 [(I18n.translate :label_gpg_action_both), '3']
			]
		end # sendDefaultsSelectOptions

		def self.sendMailSignedByDefault(project)
			HelpdeskSettings[:gpg_send_default_action, project.id].to_i & 1 > 0
		end #sendMailSignedByDefault

		def self.sendMailEncryptedByDefault(project)
			HelpdeskSettings[:gpg_send_default_action, project.id].to_i & 2 > 0
		end #sendMailEncryptedByDefault

	end # class Helper

end # module HelpDeskGPG