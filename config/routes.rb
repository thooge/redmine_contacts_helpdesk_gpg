match 'gpgkeys.import', :to => 'gpgkeys#import'
match 'gpgkeys.refresh', :to => 'gpgkeys#refresh'
match 'gpgkeys.expire', :to => 'gpgkeys#expire'
match 'gpgkeys/query', :to => 'gpgkeys#query'

match 'gpgkeys', :to => 'gpgkeys#index'
match 'gpgkeys/', :to => 'gpgkeys#index'
match 'gpgkeys/all', :to => 'gpgkeys#index'
match 'gpgkeys/new', :to => 'gpgkeys#create'
match 'gpgkeys/filter', :to => 'gpgkeys#index'
match 'gpgkeys.delete/:id', :to => 'gpgkeys#destroy'

resource :gpgkeys
