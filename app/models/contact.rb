class Contact < ApplicationRecord
  validates :name, length: { minimum: 2 }, allow_blank: true
  validates :member_id, format: { with: /\d{5}/, message: "must be five digits" }, allow_blank: true
end
