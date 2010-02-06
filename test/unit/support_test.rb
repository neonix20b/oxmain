require 'test_helper'

class SupportTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Support.new.valid?
  end
end
