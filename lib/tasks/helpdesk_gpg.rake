
namespace :redmine do
  namespace :plugins do
    namespace :helpdesk_gpg do

	require_dependency File.dirname(__FILE__) +'/../gpgkeys.rb'
	
	desc <<-END_DESC
Update all keys in keystore from public keyserver

Examples:

  rake redmine:plugins:helpdesk_gpg:refresh_keys RAILS_ENV="production"
END_DESC

	task :refresh_keys => :environment do
		GpgKeys.initGPG
		_k = GpgKeys.find_all_keys
		puts "found #{_k.count} keys"
		GpgKeys.refresh_keys
		puts "done..."
	end

	
	desc <<-END_DESC
Remove all expired keys from keystore

Examples:

  rake redmine:plugins:helpdesk_gpg:remove_expired_keys RAILS_ENV="production"
END_DESC

	task :remove_expired_keys => :environment do
		GpgKeys.initGPG
		GpgKeys.remove_expired_keys
	end

      
    end  
  end
end
