class UserBroker < ApplicationRecord
  # A user needs to create broker(s) account(s) in order to register investment
  # operations.
  #
  # The UserBroker model associates a User with a Broker.

  # Associations
  belongs_to :user
  belongs_to :broker
  has_many :transactions

  # Validations
  validates :user, presence: true
  validates :broker, presence: true
  validates :name, presence: true
end
