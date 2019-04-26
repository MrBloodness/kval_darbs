class User < ApplicationRecord

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, :name, :surname, presence: true
  # validate :validates_password_confirmation
  validates :password, length: { in: 8..128 },
    on: [:update, :create],
    allow_blank: true

  private

  def validates_password_confirmation
    if password && password != password_confirmation
      errors.add(:password_confirmation, :should_math_with_password_field)
    end
  end
end
