require 'open3'
require 'streamio-ffmpeg'

module RipperHelper
  def watermark_video(filename)
    file_ext = File.extname(filename)
    file_prefix = filename.gsub(file_ext, '')
    movie = FFMPEG::Movie.new("#{Dir.pwd}/tmp/#{filename}")
    movie.video_stream =~ /(\d\d\d*)x(\d\d\d*)/
    watermark_height = 200
    if $1
      height = $1
      case height.to_i
        when 2000..5000
          watermark_height = 600
        when 1500..2000
          watermark_height = 400
        when 1000..1500
          watermark_height = 300
      end
    end
    ffmpeg = "ffmpeg -i #{Dir.pwd}/tmp/#{filename} -i #{Dir.pwd}/app/assets/images/Watermark-JukinVideo-#{watermark_height}.png -filter_complex \"overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2\" -codec:a copy ./tmp/#{file_prefix}_wm#{file_ext}"
    puts ffmpeg
    Open3.popen3(ffmpeg) do |stdin, stdout, stderr, wait_thr|
      puts "stdout: #{stdout.read}"
    end

  end
end
