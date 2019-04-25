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

require 'test_helper'

class UserClassifierTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
