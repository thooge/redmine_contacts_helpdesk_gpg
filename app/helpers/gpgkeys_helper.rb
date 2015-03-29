module GpgkeysHelper
	
	def main_uid(key)
		key.primary_uid.uid
	end
	
	def key_image(key)
		_pair = @sec_fingerprints.include? key.subkeys[0].fingerprint
		_pair ? 'gpg_keypair' : 'gpg_pubkey'
	end
	
	def key_trust(key)
		if key.expired
			'expired'
		elsif key.subkeys[0].trust == :revoked
			'revoked'
		else
			'trusted'
		end
	end
	
	def key_to_string(key)
		# select subkeys (without primary subkey) in order to render key's details nicely
		_subkeys = key.instance_variable_get(:@subkeys)
		_subkeys = _subkeys[1, _subkeys.length]
		render :partial => 'gpgkey_details',
				:locals => {:primary_subkey => key.subkeys[0], :uids => key.instance_variable_get(:@uids), :subkeys => _subkeys}
	end
	
	def short_fingerprint(key)
		key.subkeys[0].fingerprint[-8 .. -1]
	end
	
end