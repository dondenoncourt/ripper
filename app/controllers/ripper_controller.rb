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
      Open3.popen3("youtube-dl -o '#{download_template}' https://www.youtube.com/watch?v=#{params[:s3_video_key]}") do |stdin, stdout, stderr, wait_thr|
        logger.info "stdout: #{stdout.read}"
        standard_error = stderr.read
        if standard_error.size > 0
          raise ArgumentError, standard_error
        end
      end

      # get the generated file name so we upload to S3 with the correct suffix
      filename = Dir.entries(Pathname.new("#{Dir.pwd}/tmp")).select {|f| !File.directory?(f) && f =~ /#{params[:s3_video_key]}/}[0]
      file_ext = File.extname(filename)


      # if no_audio strip out sound tracks
      if params[:no_audio] && params[:no_audio] == 'true'
        ffmpeg = "ffmpeg -i tmp/#{params[:s3_video_key]}#{file_ext} -vcodec copy -an -y tmp/#{params[:s3_video_key]}_no_audio#{file_ext}"
        logger.info ffmpeg
        Open3.popen3(ffmpeg) do |stdin, stdout, stderr, wait_thr|
          logger.info "stdout: #{stdout.read}"
        end
        logger.info "File.delete tmp/#{params[:s3_video_key]}#{file_ext}"
        File.delete "tmp/#{params[:s3_video_key]}#{file_ext}"
        logger.info "File.rename tmp/#{params[:s3_video_key]}_no_audio#{file_ext}, tmp/#{params[:s3_video_key]}#{file_ext}"
        File.rename "tmp/#{params[:s3_video_key]}_no_audio#{file_ext}", "tmp/#{params[:s3_video_key]}#{file_ext}"
      end
      s3 = AWS::S3.new
      bucket = s3.buckets[params[:bucket_name]] # 'jukinvideo_unit_tests'
      if !bucket.exists?
        raise ArgumentError, "S3 bucket called #{params[:bucket_name]} does not exist"
      end
      bucket.objects[filename].write(Pathname.new("#{Dir.pwd}/tmp/#{filename}"))
      File.delete "#{Dir.pwd}/tmp/#{filename}"
      render json: {success: "#{filename} uploaded to S3 in #{params[:bucket_name]}"}
    rescue Exception => e
      logger.info e.to_s
      render json: {error: 'internal-server-error', exception: "#{e.class.name} : #{e.message}"}, status: 422
    end
  end

  # to test from console:
  # app.post '/ripper/watermark/jukinvideo_unit_tests/--don_test.mp4', {'ajax_key' => 'hzsdLMiP4QZHnAoMwiNKQZD9J'}
  def watermark
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
