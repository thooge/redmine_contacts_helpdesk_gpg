match 'gpgkeys.import', :to => 'gpgkeys#import', via: [:get, :post]
match 'gpgkeys.refresh', :to => 'gpgkeys#refresh', via: [:get, :post]
match 'gpgkeys.expire', :to => 'gpgkeys#expire', via: [:get, :post]
match 'gpgkeys/query', :to => 'gpgkeys#query', via: [:get, :post]

match 'gpgkeys', :to => 'gpgkeys#index', via: [:get, :post]
match 'gpgkeys/', :to => 'gpgkeys#index', via: [:get, :post]
match 'gpgkeys/all', :to => 'gpgkeys#index', via: [:get, :post]
match 'gpgkeys/new', :to => 'gpgkeys#create', via: [:get, :post]
match 'gpgkeys/filter', :to => 'gpgkeys#index', via: [:get, :post]
match 'gpgkeys.delete/:id', :to => 'gpgkeys#destroy', via: [:get, :post]

resource :gpgkeys
