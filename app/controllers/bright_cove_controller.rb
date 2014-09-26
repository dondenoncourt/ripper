require 'aws-sdk'
require 'net/http'
require 'brightcove-api'

class BrightCoveController < ApplicationController
  protect_from_forgery except: :pullFromS3
  before_filter :check_ajax_secret_key!, except: [:index, :show]

  # POST /brightcove/riff_video_id/bucket_name/video_object_key.mp4
  def pullFromS3
    s3_video_key = "#{params[:s3_video_key]}.#{params[:format]}"
    riff_video_id = params[:riff_video_id]
    s3 = AWS::S3.new
    bucket = s3.buckets[params[:bucket_name]]
    if !bucket.exists?
      raise ArgumentError, "S3 bucket called #{params[:bucket_name]} does not exist"
    end
    obj = bucket.objects[s3_video_key]
    if !obj.exists?
      raise ArgumentError, "S3 bucket called #{params[:bucket_name]} with key: #{s3_video_key} does not exist"
    end

    Spawnling.new do
      logger.info "File.open(./tmp/#{s3_video_key}, 'wb'"
      File.open("./tmp/#{s3_video_key}", 'wb') do |file|
        obj.read do |chunk|
          file.write(chunk)
        end
      end
      logger.info "s3 #{s3_video_key} pulled locally"

      brightcove = Brightcove::API.new(ENV['brightcove_write_token'])
      logger.info "brightcove.post_file #{s3_video_key} #{riff_video_id}"
      response = brightcove.post_file('create_video', "./tmp/#{s3_video_key}",
          create_multiple_renditions: true,
          video: {referenceId: riff_video_id, shortDescription: s3_video_key, name: s3_video_key})
      File.delete "#{Dir.pwd}/tmp/#{s3_video_key}"
      if response['error'] != nil
        logger.error "POST of #{s3_video_key} #{riff_video_id} error: #{response.to_s}"
        # TODO send error email as this is a background process and we can't return the error in the HTTP response
        raise ArgumentError, response['error']
      end
      video = Video.find(riff_video_id)
      video.brightcove_video_id = response['result']
      video.save
    end # Spawnling
    render json: {result: 'OK'}
  end

  def transfer_from_kaltura
    launch_command = " ruby  '#{Dir.pwd}/lib/migrations/kaltura_to_brightcove.rb'  & "
    system launch_command
    render text: launch_command
  end
end
