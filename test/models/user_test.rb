# == Schema Information
#
# Table name: users
#
#  id               :integer          not null, primary key
#  name             :string
#  surname          :string
#  occupation_id    :integer
#  state_id         :integer
#  department_id    :integer
#  employed_since   :date
#  salary           :decimal(6, 2)
#  avatar_file_name :string
#  email            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
