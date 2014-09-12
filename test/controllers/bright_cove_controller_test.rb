require 'test_helper'
require 'json'

class BrightCoveControllerTest < ActionController::TestCase
  test "should fail with no secret key" do
    begin
      post :pullFromS3, {s3_video_key: 's3_video_key', bucket_name: 'bucket_name', riff_video_id: '123', format: 'mp4'}, json: true
      assert false
    rescue
      assert true
    end
  end
  test "should pull from S3" do
    s3_video_key = '--don_test' # .mp4
    # s3_video_key = '7vqhrPx8CcQ' # .mp4 this guy is very big
    bucket_name = 'jukinvideo_unit_tests'
    post :pullFromS3,
         {s3_video_key: s3_video_key, bucket_name: bucket_name, format: 'mp4', riff_video_id: '123', ajax_key: ENV['ajax_secret_key']},
         json: true
    assert_response :success
    puts "@response.body"
    json = JSON.parse @response.body
    # assert json['error'] == nil
    # assert json['result'].is_a? Numeric
  end

end
