require 'test_helper'
require 'json'

class BrightCoveControllerTest < ActionController::TestCase
  test "should pull from S3" do
    s3_video_key = '--don_test.mp4'
    bucket_name = 'jukinvideo_unit_tests'
    post :pullFromS3, {s3_video_key: s3_video_key, bucket_name: bucket_name}, json: true
    assert_response :success
    puts "@response.body"
    json = JSON.parse @response.body
    assert json['error'] == nil
    assert json['result'].is_a? Numeric
  end

end
