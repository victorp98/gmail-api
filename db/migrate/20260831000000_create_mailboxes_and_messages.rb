class CreateMailboxesAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :mailboxes do |t|
      t.string :email, null: false
      t.integer :history_sequence, null: false, default: 0
      t.timestamps
    end
    add_index :mailboxes, :email, unique: true

    create_table :messages do |t|
      t.references :mailbox, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :thread_id, null: false
      t.integer :history_id, null: false
      t.text :raw, null: false
      t.json :labels, null: false, default: []
      t.datetime :received_at, null: false
      t.timestamps
    end
    add_index :messages, [ :mailbox_id, :external_id ], unique: true
    add_index :messages, [ :mailbox_id, :history_id ]
  end
end
