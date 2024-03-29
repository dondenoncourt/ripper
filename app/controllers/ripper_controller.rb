require 'aws-sdk'
require 'open3'

class RipperController < ApplicationController
  include RipperHelper

  protect_from_forgery except: :create
  before_filter :check_ajax_secret_key!, except: [:index, :show, :new]

  def index
    render text: 'index request'
  end

  # GET /ripper/1
  def show
    render text: "get show request #{params[:id]}"
  end

  # GET /ripper/new
  # GET /ripper/new.json
  def new
    render text: "get new request"
  end

  # GET /ripper/1/edit
  def edit
    render text: "get edit request #{params[:id]}"
  end

  # POST /ripper/:s3_video_key/:bucket_name
  # POST /ripper/:s3_video_key/:bucket_name?no_audio=true
  def create
    download_template = Dir.pwd+"/tmp/#{params[:platform]}%(id)s.%(ext)s"
    begin
      # note, streaming std/err out is possible and explained in  http://blog.bigbinary.com/2012/10/18/backtick-system-exec-in-ruby.html
      logger.info  "youtube-dl -o '#{download_template}' https://www.youtube.com/watch?v=#{params[:s3_video_key]}"
      Open3.popen3("youtube-dl -o '#{download_template}' https://www.youtube.com/watch?v=#{params[:s3_video_key]}") do |stdin, stdout, stderr, wait_thr|
        logger.info "stdout: #{stdout.read}"
        standard_error = stderr.read
        if standard_error.size > 0
          raise ArgumentError, standard_error
        end
      end

      # get the generated file name so we upload to S3 with the correct suffix
      filename_with_audio = Dir.entries(Pathname.new("#{Dir.pwd}/tmp")).select {|f| !File.directory?(f) && f =~ /#{params[:s3_video_key]}/}[0]
      file_ext = File.extname(filename_with_audio)

      filename_no_audio = "#{params[:platform]}#{params[:s3_video_key]}_no_audio#{file_ext}"

      s3 = AWS::S3.new
      bucket = s3.buckets[params[:bucket_name]] # 'jukinvideo_unit_tests'
      if !bucket.exists?
        raise ArgumentError, "S3 bucket called #{params[:bucket_name]} does not exist"
      end

      bucket.objects[filename_with_audio].write(Pathname.new("#{Dir.pwd}/tmp/#{filename_with_audio}"))

      # if no_audio strip out sound tracks
      if params[:no_audio] && params[:no_audio] == 'true'
        ffmpeg = "ffmpeg -i tmp/#{filename_with_audio} -vcodec copy -an -y tmp/#{filename_no_audio}"
        logger.info ffmpeg
        Open3.popen3(ffmpeg) do |stdin, stdout, stderr, wait_thr|
          logger.info "stdout: #{stdout.read}"
        end
        logger.info "File.delete tmp/#{params[:platform]}#{params[:s3_video_key]}#{file_ext}"
        bucket.objects[filename_no_audio].write(Pathname.new("#{Dir.pwd}/tmp/#{params[:platform]}#{params[:s3_video_key]}_no_audio#{file_ext}"))
        File.delete "tmp/#{filename_no_audio}"
      end

      File.delete "tmp/#{filename_with_audio}"

      render json: {success: "#{params[:platform]}#{filename_with_audio} uploaded to S3 in #{params[:bucket_name]}"}
    rescue Exception => e
      logger.info e.to_s
      render json: {error: 'internal-server-error', exception: "#{e.class.name} : #{e.message}"}, status: 422
    end
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
