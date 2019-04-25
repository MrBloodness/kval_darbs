class ClassifierPermission < ApplicationRecord
  belongs_to :user
  belongs_to :user_classifier

  class_attribute :configurable_classifiers
  self.configurable_classifiers = [
    # DocumentRegisterCategory
  ]

  def self.available?(classifier)
    find_by(user_classifier_id: classifier.id, user_id: User.current.id)
  end
end
