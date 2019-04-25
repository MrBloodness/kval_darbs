class DocumentRegisterCategory < UserClassifier
  attr_accessor :allowed_users

  after_create :set_allowed_users

  def self.reset_filters!
    DocumentRegistersFilter.scopes.reject! do |a|
      a.name.to_s.include?("category_")
    end
    ordered_by_position_asc.each do |category|
      next unless ClassifierPermission.available?(category)
      DocumentRegistersFilter.scopes << Scope.new(
        "category_#{category.id}", { label: category.value })
    end
  end

  private

  def set_allowed_users
    User.where(id: allowed_users).find_each do |user|
      user.classifier_permissions.create(user_classifier: self)
    end
  end
end
