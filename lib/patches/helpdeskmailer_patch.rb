require 'gpgme'
require 'mail-gpg'
require 'gpgkeys'
require_dependency 'helpdesk_mailer'
require_dependency 'redmine_contacts_helpdesk_gpg'

module RedmineHelpdeskGPG
	module Patches

		module HelpdeskMailerPatch

			attr_writer :email

			def self.included(base) # :nodoc:
				base.send(:include, InstanceMethods)

				base.class_eval do
					unloadable # Send unloadable so it will not be unloaded in development
					
					# incoming mail; check for gpg encryption/signature prior to handling mail by helpdesk
					alias_method_chain :receive, :gpg
					# still incoming mail; store gpg params for new issue or reply to an issue
					alias_method_chain :receive_issue, :gpg
					alias_method_chain :receive_issue_reply, :gpg
					# outgoing mail; set options for gpg encryption/signature
					alias_method_chain :issue_response, :gpg
					alias_method_chain :initial_message, :gpg

				end
			end # self.included
			
			module InstanceMethods
			
				# checks for encrypted/signed mail then proceeds with the receiving process
				def receive_with_gpg(email)
					initGPGSettings
					@gpg_received_options = {:encrypted => false, :signed => false}
					# logger.info "receive_with_gpg: email.from_addrs is '#{email.from_addrs}'"
					_sender_email = email.from_addrs.first.to_s.strip
					if email.encrypted?
						# logger.info "receive_with_gpg: do I have a key for decrypting? '#{HelpdeskSettings[:gpg_decrypt_key, target_project]}"
						_decrypted = email.decrypt(verify: true, password: HelpdeskSettings[:gpg_decrypt_key_password, target_project])
						@gpg_received_options[:encrypted] = true
						@gpg_received_options[:signed] = _decrypted.signature_valid?
						# logger.info "receive_with_gpg: Mail was encrypted"
						# logger.info "receive_with_gpg: signature(s) valid: #{_decrypted.signature_valid?}"
						# logger.info "receive_with_gpg: message signed by: #{_decrypted.signatures.map{|sig|sig.from}.join("\n")}"
						email = Mail.new(_decrypted)
					elsif email.signed?
						_have_key = GpgKeys.checkAndOptionallyImportKey(_sender_email)
						if _have_key
							_verified = email.verify
							# logger.info "receive_with_gpg: signature(s) valid: #{_verified.signature_valid?}"
							# logger.info "receive_with_gpg: message signed by: #{_verified.signatures.map{|sig|sig.from}.join("\n")}"
							@gpg_received_options[:signed] = _verified.signature_valid?
							email = Mail.new(_verified) if _verified.signature_valid?
						else
							# logger.info "receive_with_gpg: could not find key for: #{_sender_email}"
						end
					else 
						logger.info "receive_with_gpg: Mail was not signed nor encrypted"
					end
					return receive_without_gpg(email) # call original method
				end #def receive_with_gpg
				
				
				def receive_issue_with_gpg
					# an issue has been received; store gpg journal
					_res = receive_issue_without_gpg
					saveGpgJournal(_res, @gpg_received_options)
					return _res
				end # def receive_issue_with_gpg
				
				def receive_issue_reply_with_gpg(issue_id)
					# an issue (a reply to one) has been received; store gpg journal
					_res = receive_issue_reply_without_gpg(issue_id)
					saveGpgJournal(_res, @gpg_received_options)
					return _res
				end # def receive_issue_reply
				
				# A response is about to be issued. Might want to set gpg encryption/signing params
				def issue_response_with_gpg(contact, journal, params)
					initGPGSettings
					_gpg_journal_options = {:encrypted => false, :signed => false}
					_gpg_options = {}
					setGPGOptionsFromParams(journal.issue.project, params, _gpg_journal_options, _gpg_options)
					
					# logger.info "issue_response_with_gpg: set gpg options: #{_gpgOptions}"
					mail gpg: _gpg_options unless _gpg_options.empty?
					saveGpgJournal(journal, _gpg_journal_options)
					
					# finally let helpdesk compose the mail and send it (including any gpg options set)
					return issue_response_without_gpg(contact, journal, params)
					
				end #def issue_response_with_gpg

				# A new ticket has been created and a mail is to be sent to customer. Might want to set gpg encryption/signing params
				def initial_message_with_gpg(contact, issue, params)
					initGPGSettings
					_gpg_journal_options = {}
					_gpg_options = {}
					setGPGOptionsFromParams(issue.project, params, _gpg_journal_options, _gpg_options)

					# let helpdesk compose the mail and send it (including any gpg options set)
					mail gpg: _gpg_options unless _gpg_options.empty?
					_result = initial_message_without_gpg(contact, issue, params)
					# save journal if no error occurred
					saveGpgJournal(issue, _gpg_journal_options)
					return _result
				end #def issue_response_with_gpg
				
				## private methods
				private
				
				def initGPGSettings
					ENV.delete('GPG_AGENT_INFO')
					ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
					GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
				end # initGPGSettings

				def setGPGOptionsFromParams(project, params, gpg_journal_options, gpg_options)
					# first set any gpg option for the mail
					# shall we encrypt the message?
					if params[:helpdesk][:gpg_do_encrypt]
						#logger.info "issue_response_with_gpg: We shall encrypt the mail"
						# do we have keys for all recipients?
						_receivers = []
						_receivers += params[:helpdesk][:to_address].split(',') if params[:helpdesk][:to_address]
						_receivers += params[:helpdesk][:cc_list].split(',') if params[:helpdesk][:cc_list]
						_receivers += params[:helpdesk][:bcc_list].split(',') if params[:helpdesk][:bcc_list]
						_missing_keys = GpgKeys.missingKeysForEncryption(_receivers)
						if _missing_keys.empty? # all keys are available :)
							gpg_options[:encrypt] = true
							gpg_journal_options[:encrypted] = true
						else
							raise MailHandler::MissingInformation.new("Cannot encrypt message. No public key for #{_missing_keys}")
						end
					end
					if params[:helpdesk][:gpg_do_sign] ## shall we sign the message?
						#logger.info "issue_response_with_gpg: We shall sign the mail with passphrase '#{HelpdeskSettings[:gpg_sign_key_password, journal.issue.project]}'"
						gpg_options[:sign_as] = HelpdeskSettings[:gpg_sign_key, project]
						gpg_options[:password] = HelpdeskSettings[:gpg_sign_key_password, project]
						gpg_journal_options[:signed] = true
					end
				end #def setGPGOptionsFromParams

				def saveGpgJournal(ref, options)
					if options[:signed] || options[:encrypted] then
						# logger.info "saveGpgJournal: Creating GpgJournal for #{ref.class}(#{ref.id}): s:#{options[:signed]},e:#{options[:encrypted]}"
						item = GpgJournal.new(:was_signed => options[:signed], :was_encrypted => options[:encrypted])
						if ref.instance_of?(Issue)
							item.issue = ref
						end
						if ref.instance_of?(Journal)
							item.journal = ref
						end
						item.save
					end
				end

			end # module InstanceMethods
			
		end #module HelpdeskMailerPatch
	end # module Patches
end # module RedmineHelpdeskGPG

unless HelpdeskMailer.included_modules.include?(RedmineHelpdeskGPG::Patches::HelpdeskMailerPatch)
	HelpdeskMailer.send(:include, RedmineHelpdeskGPG::Patches::HelpdeskMailerPatch)
end