class UserClassifier < ApplicationRecord

  # self.icon = 'list'

  class_attribute :colorable
  self.colorable = false

  before_save :set_key

  scope :active, -> { where(is_active: true).order(:position) }

  def self.api_sync_json_options
    { except: [:value],
      include: {
        translations: {
          only: [:locale, :value]
        }
      },
      methods: :type }
  end

  def to_s
    value
  end

  def translations_attributes
    translations.map do |t|
      { locale: t.locale, value: t.value }
    end
  end

  private

  def set_key
    return if key
  end
end

# == Schema Information
#
# Table name: user_classifiers
#
#  id         :integer          not null, primary key
#  type       :string
#  is_system  :boolean          default(FALSE)
#  is_active  :boolean          default(TRUE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color      :string
#  position   :integer          not null
#  key        :string
#
