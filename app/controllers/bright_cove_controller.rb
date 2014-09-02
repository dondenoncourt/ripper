require 'aws-sdk'
require 'net/http'
require 'brightcove-api'

class BrightCoveController < ApplicationController
  # POST /brightcove {s3_video_key: s3_video_key, bucket_name: bucket_name}
  def pullFromS3
    s3 = AWS::S3.new
    bucket = s3.buckets[params[:bucket_name]]
    if !bucket.exists?
      raise ArgumentError, "S3 bucket called #{params[:bucket_name]} does not exist"
    end
    obj = bucket.objects[params[:s3_video_key]]
    if !obj.exists?
      raise ArgumentError, "S3 bucket called #{params[:bucket_name]} with key: #{params[:s3_video_key]} does not exist"
    end

    File.open("./tmp/#{params[:s3_video_key]}", 'wb') do |file|
      obj.read do |chunk|
        file.write(chunk)
      end
    end

    brightcove = Brightcove::API.new(ENV['brightcove_write_token'])
    response = brightcove.post_file('create_video', "./tmp/#{params[:s3_video_key]}",
                                    create_multiple_renditions: true,
                                    video: {shortDescription: "#{params[:s3_video_key]}", name: "#{params[:s3_video_key]}"})
    if response['error'] != nil
      raise ArgumentError, response['error']
    end
    render json: response
  end
end
