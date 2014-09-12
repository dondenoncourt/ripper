# == Schema Information
#
# Table name: video
#
#  video_id                  :integer          not null, primary key
#  version                   :integer          not null
#  author                    :string(255)
#  author_id                 :integer
#  cds_contract_field_id     :string(20)
#  cds_contract_file_id      :string(20)
#  channel_id                :integer
#  clip_within_compilation   :boolean          not null
#  date                      :datetime
#  date_created              :datetime         not null
#  description               :text
#  download_url              :text
#  duration                  :binary
#  duration_str              :string(20)
#  entry_id                  :integer          not null
#  hash_id                   :string(255)
#  img_url                   :string(1024)
#  last_updated              :datetime
#  manual_video_source       :text
#  original_source_notes     :text
#  original_video_meta       :text
#  platform_id               :string(128)
#  platform_video_id         :string(25)
#  site_id                   :integer
#  tags                      :string(255)
#  title                     :string(255)
#  user_name                 :string(100)
#  video_order               :integer
#  video_url                 :string(1024)     not null
#  views                     :integer
#  filmed_date               :string(50)
#  location                  :string(100)
#  original_publishing_date  :datetime
#  people_in_the_video       :string(100)
#  publishing_description    :string(255)
#  publishing_title          :string(100)
#  story_notes               :text
#  edited_footage_format     :string(255)      default("SD"), not null
#  has_multiple_angles       :boolean          default(FALSE), not null
#  master_footage_format     :string(255)      default("SD"), not null
#  ripped_footage_format     :string(255)      default("SD"), not null
#  will_not_have_master      :boolean          default(FALSE), not null
#  ripped_s3_uri             :string(255)
#  edited_s3_uri             :string(255)
#  master_s3_uri             :string(255)
#  youtube_last_updated_date :datetime
#  youtube_updated           :string(255)      default("NA"), not null
#  dislikes                  :integer
#  likes                     :integer
#  comments                  :integer
#  favorites                 :integer
#  brightcove_video_id       :integer
#

class Video < ActiveRecord::Base
  self.table_name = 'video'
end
