# encoding: UTF-8
require 'test_helper'
class TaggingTest < ActiveSupport::TestCase 
    fixtures :tags
    fixtures :taggings
    
    test "Redirection to redundant tagging is avoided" do
      tagging1 = taggings(:t1)
      tagging2 = taggings(:t2)
      TaggingServices.change_tag tagging1.tag_id, tagging2.tag_id
      assert_empty Tagging.where(id: tagging1.id), "Redirecting tag to existing tag didn't destroy tagging"
    end

end