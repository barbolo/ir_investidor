class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :rememberable,
         :trackable, :validatable
  (devise :recoverable, :confirmable, :lockable) if Rails.env.production?
end
