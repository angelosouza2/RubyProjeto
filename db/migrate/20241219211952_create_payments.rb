class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.string :name
      t.string :email
      t.decimal :amount
      t.string :status
      t.string :transaction_id

      t.timestamps
    end
  end
end
