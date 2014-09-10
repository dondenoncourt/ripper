require 'aws-sdk'
require 'net/http'
require 'brightcove-api'

class BrightCoveController < ApplicationController
  protect_from_forgery except: :pullFromS3
  before_filter :check_ajax_secret_key!, except: [:index, :show]

  # POST /brightcove/bucket_name/video_object_key.mp4
  def pullFromS3
    s3_video_key = "#{params[:s3_video_key]}.#{params[:format]}"
    s3 = AWS::S3.new
    bucket = s3.buckets[params[:bucket_name]]
    if !bucket.exists?
      raise ArgumentError, "S3 bucket called #{params[:bucket_name]} does not exist"
    end
    obj = bucket.objects[s3_video_key]
    if !obj.exists?
      raise ArgumentError, "S3 bucket called #{params[:bucket_name]} with key: #{s3_video_key} does not exist"
    end

    remote_attempts = 1..4

    for i in remote_attempts
      begin
        File.open("./tmp/#{s3_video_key}", 'wb') do |file|
          obj.read do |chunk|
            file.write(chunk)
          end
        end
        break
      rescue
        if i < remote_attempts.max
          s3 = AWS::S3.new
          bucket = s3.buckets[params[:bucket_name]]
          obj = bucket.objects[s3_video_key]
          next
        end
        raise
      end
    end

    brightcove = Brightcove::API.new(ENV['brightcove_write_token'])
    for i in remote_attempts
      begin
        response = brightcove.post_file('create_video', "./tmp/#{s3_video_key}",
                                        create_multiple_renditions: true,
                                        video: {shortDescription: "#{s3_video_key}", name: "#{s3_video_key}"})
        break
      rescue
        next if i < remote_attempts.max
        raise
      end
    end
    if response['error'] != nil
      raise ArgumentError, response['error']
    end
    render json: response
  end
end
