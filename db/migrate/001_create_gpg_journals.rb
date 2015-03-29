class CreateGpgJournals < ActiveRecord::Migration
	def change
		create_table :gpg_journals do |t|
			t.references :issue
			t.references :journal
			t.boolean :was_signed
			t.boolean :was_encrypted
		end
		add_index :gpg_journals, [:issue_id, :journal_id]
	end
  
end
