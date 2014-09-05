require 'aws-sdk'
require 'net/http'
require 'brightcove-api'

class BrightCoveController < ApplicationController
  protect_from_forgery except: :pullFromS3

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

    File.open("./tmp/#{s3_video_key}", 'wb') do |file|
      obj.read do |chunk|
        file.write(chunk)
      end
    end

    brightcove = Brightcove::API.new(ENV['brightcove_write_token'])
    response = brightcove.post_file('create_video', "./tmp/#{s3_video_key}",
                                    create_multiple_renditions: true,
                                    video: {shortDescription: "#{s3_video_key}", name: "#{s3_video_key}"})
    if response['error'] != nil
      raise ArgumentError, response['error']
    end
    render json: response
  end

  # TODO replace video_id and remoteUrl and displayName
  def thumbnail
    json = {
        image: {
          type:"THUMBNAIL", #type:"VIDEO_STILL",
          resize: "false", displayName:"display name",
          remoteUrl: "http://cdnbakmi.kaltura.com/p/1321751/sp/132175100/thumbnail/entry_id/0_x1eiecb5/version/0"
        },
        video_id: 3767122068001
    }
    brightcove = Brightcove::API.new('UrtRUKydo_-euJRWBvFRmVh6Fme2vi9RuT9bLvEu9cmrN_3UUSoSFg..')
    response = brightcove.post('add_image', json)
    render json: response
  end

end
