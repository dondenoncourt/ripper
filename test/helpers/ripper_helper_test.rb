require 'test_helper'

class RipperHelperTest < ActionView::TestCase

  test "should add a watermarked file" do
    aws_access_key_id = 'AKIAJMQ5TKXQLCVL5HJA'
    aws_secret_access_key = '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'
    s3 = AWS::S3.new access_key_id: aws_access_key_id, secret_access_key: aws_secret_access_key
    bucket_name = 'jukinvideo_unit_tests'
    s3_video_key = '--don_test.mp4' # better call saul
    File.delete("#{Dir.pwd}/tmp/--don_test.mp4") if File.exists?("#{Dir.pwd}/tmp/--don_test.mp4")
    File.delete("#{Dir.pwd}/tmp/--don_test_wm.mp4") if File.exists?("#{Dir.pwd}/tmp/--don_test_wm.mp4")
    bucket = s3.buckets[bucket_name]
    obj = bucket.objects[s3_video_key]
    File.open("./tmp/#{s3_video_key}", 'wb') do |file|
      obj.read do |chunk|
        file.write(chunk)
      end
    end
    watermark(s3_video_key)
    assert File.exists?("#{Dir.pwd}/tmp/--don_test_wm.mp4")
  end
end
