class Payment < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true
  validates :amount, presence: true
  validates :status, presence: true
  validates :transaction_id, presence: true
end
