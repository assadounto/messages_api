class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.string  :subject,  null: false
      t.string  :sender,   null: false
      t.text    :body,     null: false

      t.integer :status,                null: false, default: 0  
      t.integer :classification                                 

      t.integer :classification_attempts, null: false, default: 0
      t.text    :last_error
      t.datetime :classified_at

      t.timestamps
    end

    add_index :messages, :status
    add_index :messages, :classification
    add_index :messages, :created_at
  end
end
