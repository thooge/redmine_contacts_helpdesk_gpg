require 'gpgkeys'

class GpgkeysController < ApplicationController

	unloadable
	layout 'admin'
	before_filter :require_admin
	##before_filter :require_admin, :except => :show
	##before_filter :find_key, :only => [:show, :edit, :update, :destroy]

	def initialize
		super()
		GpgKeys.initGPG
	end
	
	def index
		# logger.info "Gpgkeys#index, params=#{params}"
		@limit = per_page_option

		@keys = GpgKeys.visible(params)
		@sec_fingerprints = GpgKeys.sec_fingerprints
		
		@keys = @keys.sort_by { | key | key.primary_uid.uid }
		
		@key_count = @keys.count
		@key_pages = Paginator.new @key_count, @limit, params['page']
		@offset ||= @key_pages.offset

		render :layout => !request.xhr?
	end # index
	
	def create
		# Cannot really create a key here. But we can import from file... 
		render :action => 'new'
	end # create
	
	def refresh
		# refresh keys from key server
		GpgKeys.refresh_keys
		flash[:notice] = t(:msg_gpg_keys_updated)
		redirect_to action: 'index'
	end # refresh
	
	def expire
		# remove all expired keys
		_cnt = GpgKeys.remove_expired_keys
		flash[:notice] = t(:msg_gpg_keys_expired, cnt: _cnt)
		redirect_to action: 'index'
	end # expire
	
	def destroy
		# what a strong word for simply removing a key form local storage :/
		GpgKeys.removeKey(params[:id])
		redirect_to params[:back_url]
	end # destroy
	
	def import
		# params include:
		# "attachments"=>{
		#	 "1"=>{"filename"=>"test.txt", "description"=>"", "token"=>"3.5eb63bbbe01eeed093cb22bb8f5acdc3"}, "dummy"=>{"file"=>""}
		# }
		_cnt = GpgKeys.import_keys(params)
		flash[:notice] = t(:msg_gpg_keys_imported, pub: _cnt[0], priv: _cnt[1])
		redirect_back_or_default(gpgkeys_path)
	end # import	

end
