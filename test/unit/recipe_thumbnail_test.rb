# encoding: UTF-8
require 'test_helper'
class RecipeThumbnailTest < ActiveSupport::TestCase 
  fixtures :recipes
  
  test "Bad pic URL gets bad_url thumbnail" do
    bpr = recipes(:badpicrcp)
    bpr.perform
    success = bpr.save
    assert_nil recipes(:badpicrcp).thumbnail, "Recipe with bad pic url should get nil thumbnail"
  end
  
  test "Save success with good pic URL" do
    success = recipes(:goodpicrcp).save
    assert success, "Recipe with good pic should be saved"
  end
  
end
