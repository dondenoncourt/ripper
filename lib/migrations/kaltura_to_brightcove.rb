require 'open-uri'
require 'brightcove-api'
require 'work_queue'
require 'active_record'

cds = {
    adapter: 'mysql2',
    encoding: 'utf8',
    reconnect: true,
    database: 'thedbjvcwecombo',
    username: 'mastercarrasaldo',
    password: 'Blue843853',
    # host: 'jukinvideodevelopment-don.ckoljqgt1piq.us-east-1.rds.amazonaws.com'
    host: 'jukinvideodevelopment2.ckoljqgt1piq.us-east-1.rds.amazonaws.com'
}

riff = {
    adapter: 'postgresql',
    database: 'jukinvideo',
    username: 'newjukin',
    password: 'JHsc9tekvj',
    reconnect: true,
    port: 5432,
    # host: 'localhost',
    host: "newjukindev.cdrlveumgn4e.us-west-1.rds.amazonaws.com"
}

class ExpChannelData < ActiveRecord::Base
  def riff_video
    Video.find_by entry_id: entry_id
    end
end
ExpChannelData.establish_connection(cds)
class ExpKalturaVideo < ActiveRecord::Base
  self.primary_key = :kaltura_video_id
  has_one :exp_channel_data, foreign_key: :field_id_303
  def self.with_channel_data
    # need a dummy where to force load to work (as it uses a LEFT JOIN and where forces a row)
    ExpKalturaVideo.eager_load(:exp_channel_data).where("exp_channel_data.entry_id IS NOT NULL")
  end

  def updated_time
    Time.at(updated_at)
  end
end
ExpKalturaVideo.establish_connection(cds)


class Video < ActiveRecord::Base; self.table_name = 'video'; end
Video.establish_connection(riff)

video_formats = {
    'video/avi' => 'avi', # Covers most Windows-compatible formats including .avi and .divx[16]
    'video/mp4' => 'mp4', # MP4 video; Defined in RFC 4337
    'video/ogg' => 'ogg', # Ogg Theora or other video (with audio); Defined in RFC 5334
    'video/quicktime' => 'mov', # QuickTime video; Registered[17]
    'video/webm' => 'webm', # WebM Matroska-based open media format
    'video/x-matroska' => 'matroska', # Matroska open media format
    'video/x-ms-wmv' => 'wmv', # Windows Media Video; Documented in Microsoft KB 288102
    'video/x-flv' => 'flv' # Flash video (FLV files)
}
brightcove_write_token = 'UrtRUKydo_-euJRWBvFRmVh6Fme2vi9RuT9bLvEu9cmrN_3UUSoSFg..'
bucket_name = 'jukinvideo_unit_tests'
work_queue = WorkQueue.new 2

module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

suppress_warnings do
  puts " Videos count: #{Video.count}"
  puts " Videos with brightcove_video_id: #{Video.where.not(brightcove_video_id: nil).count}"
  kaltura_videos_to_process = ExpKalturaVideo.with_channel_data.where("updated_at > ? ", Time.now.to_i-10.days).order('updated_at ASC').limit(233)
  puts " ExpKalturaVideos to process: #{kaltura_videos_to_process.count}"

  # TODO: do based on updated_at and some kind of saved timestamp
  #       if it exists in Video, next? or maybe go ahead and replace in S3, which means delete in Brightcove and add again
  # CdsDataAccessService::getAllCdsEntryIds suggest that only channel_titles with channel_videos get to RIFF:
  # SELECT t.entry_id as entryId FROM exp_channel_titles t JOIN exp_channel_videos v ON t.entry_id = v.entry_id ORDER BY t.entry_id DESC
  # a problem may be that if there is a exp_kaltura_video there may not be a exp_channel_video

  kaltura_videos_to_process.each do |kaltura_video|

    entry_id = kaltura_video.exp_channel_data.entry_id
    video = kaltura_video.exp_channel_data.riff_video
    if video.nil?
      # puts "\n>>>>>>>>> NO VIDEO for kaltura_video.id: #{kaltura_video.id} with: entry_id: #{kaltura_video.exp_channel_data.entry_id} -- skipping"
      next
    end
    next if !video.brightcove_video_id.nil?
    riff_video_id = video.id

    print "#{kaltura_video.id}:#{kaltura_video.exp_channel_data.entry_id}, "

    work_queue.enqueue_b do
      kaltura_video_name = "kaltura#{kaltura_video.id}"
puts "Kaltura download: #{kaltura_video.name} : #{kaltura_video.download_url}"
      meta = nil
      File.open("tmp/#{kaltura_video_name}",'wb') do |saved_file|
        open(kaltura_video.download_url, "rb") do |read_file|
          meta = read_file.meta
          saved_file.write(read_file.read)
        end
      end
      name_with_suffix = "#{kaltura_video_name}.#{video_formats[meta['content-type']]}"
      File.rename "tmp/#{kaltura_video_name}", "tmp/#{name_with_suffix}"

      full_path = "#{Dir.pwd}/tmp/#{name_with_suffix}"
      s3 = AWS::S3.new
puts "S3 upload: #{full_path}"
      s3.buckets[bucket_name].objects[name_with_suffix].write(Pathname.new(full_path))

      brightcove = Brightcove::API.new(brightcove_write_token)
puts "Brightcove transfer: #{full_path}"
      response = brightcove.post_file('create_video', full_path,
                    create_multiple_renditions: true,
                    video: {referenceId: riff_video_id, shortDescription: "#{kaltura_video.description[0..249]}", name: "#{name_with_suffix}"}
      )
      if response['error'] != nil
        puts "ERROR: POST of #{name_with_suffix} error: #{response.to_s}"
        # raise ArgumentError, response['error']
        next
      end
      puts response
      brightcove_video_id = response['result'].to_i
      riff_video = Video.where(entry_id: entry_id).first
      if riff_video != nil
        riff_video.brightcove_video_id = brightcove_video_id
        riff_video.master_s3_uri = "/#{bucket_name}/#{name_with_suffix}"
        riff_video.save
      end
      puts "brightcove_video_id set to #{brightcove_video_id}"

      # puts response # which has the brightcove_video_id
      File.delete full_path

      puts "push thumbnail: #{kaltura_video.thumbnail_url}"
      brightcove = Brightcove::API.new('UrtRUKydo_-euJRWBvFRmVh6Fme2vi9RuT9bLvEu9cmrN_3UUSoSFg..')
      response = brightcove.post('add_image',
        thumbnail_json = {
          image: {
            type:"THUMBNAIL", #type:"VIDEO_STILL",
            resize: "false", displayName: "#{kaltura_video_name}",
            remoteUrl: "#{kaltura_video.thumbnail_url}"
          },
          video_id: brightcove_video_id
        }
      )
      if response['error'] != nil
        puts "WARNING: thumbnail update of #{name_with_suffix} failed: #{response.to_s}"
      end
      # puts response

    end # enqueue

  end # read each

  work_queue.join

end # suppress_warnings

puts ">>>>>>>>>>>>> Kaltura to Brightcove migration completed "