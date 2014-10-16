require 'aws-sdk'
require 'open3'

class WatermarkController < ApplicationController
  include RipperHelper

  protect_from_forgery

  # POST /watermark/:bucket_name/:s3_video_key.fmt?ajax_key=hzsdLMiP4QZHnAoMwiNKQZD9J
  # to test from console:
  #     app.post '/ripper/watermark/jukinvideo_unit_tests/--don_test.mp4', {'ajax_key' => 'hzsdLMiP4QZHnAoMwiNKQZD9J'}
  def create
    filename = "#{params[:s3_video_key]}.#{params[:format]}"
    s3 = AWS::S3.new
    bucket = s3.buckets[params[:bucket_name]] # 'jukinvideo_unit_tests'
    if !bucket.exists?
      render json: {error: "S3 bucket called #{params[:bucket_name]} does not exist"}, status: 404
      return
    end
    video_to_watermark = bucket.objects[filename]
    if !video_to_watermark.exists?
      render json: {error: "S3 bucket called #{params[:bucket_name]} with key: #{filename} does not exist"}, status: 404
      return
    end
    File.open("#{Dir.pwd}/tmp/#{filename}", 'wb') do |file|
      video_to_watermark.read do |chunk|
        file.write(chunk)
      end
    end
    watermark_video filename
    watermarked_filename =  "#{params[:s3_video_key]}_wm.#{params[:format]}"
    bucket.objects[watermarked_filename].write(Pathname.new("#{Dir.pwd}/tmp/#{watermarked_filename}"))
    File.delete "#{Dir.pwd}/tmp/#{watermarked_filename}"
    File.delete "#{Dir.pwd}/tmp/#{filename}"
    render json: {error: nil}, status: 200
  end
  # PUT /ripper/1
  def update
    render text: 'put request #{params[:id]}'
  end

  # DELETE /ripper/1
  def destroy
    render text: 'delete request #{params[:id]}'
  end

end