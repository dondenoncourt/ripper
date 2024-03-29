require 'test_helper'

class RipperControllerTest < ActionController::TestCase
  test "should fail with no secret key" do
    begin
      post :create, {platform: 'youtube', s3_video_key: 'YQjrz23DUuA', bucket_name: 'jukinvideo_unit_tests'}
      assert false
    rescue
      assert true
    end
  end
  test "post with valid youtube id and bucket name should be successful" do
    post :create, {platform: 'youtube', s3_video_key: 'YQjrz23DUuA', bucket_name: 'jukinvideo_unit_tests', ajax_key: ENV['ajax_secret_key']}
    assert_response :success
  end

  test "post with valid youtube id and bucket name and no audio should be successful" do
    post :create, {platform: 'youtube', s3_video_key: 'YQjrz23DUuA', bucket_name: 'jukinvideo_unit_tests', no_audio: 'true', ajax_key: ENV['ajax_secret_key']}
    assert_response :success
  end

  test "post with invalid youtube id should fail" do
    post :create, {platform: 'youtube', s3_video_key: 'bogus', bucket_name: 'jukinvideo_unit_tests', ajax_key: ENV['ajax_secret_key']}, json: true
    json = ActiveSupport::JSON.decode @response.body
    puts ActiveSupport::JSON.decode @response.body
    assert json['exception'] =~ /Not Found/
    assert json['exception'] =~ /ArgumentError/
  end

  test "post with valid youtube id but invalid bucket should fail" do
    post :create, {platform: 'youtube', s3_video_key: 'YQjrz23DUuA', bucket_name: 'bogus_bucket_name', ajax_key: ENV['ajax_secret_key']}, json: true
    json = ActiveSupport::JSON.decode @response.body
    assert json['exception'] =~ /does not exist/
  end
end
