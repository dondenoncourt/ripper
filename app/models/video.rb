class Video < ActiveRecord::Base
  establish_connection :riff
  self.table_name = 'video'
end
