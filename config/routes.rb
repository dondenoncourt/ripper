Rails.application.routes.draw do
  post '/bright_cove/:riff_video_id/:bucket_name/:s3_video_key', to: 'bright_cove#pullFromS3'
  get  '/bright_cove/transfer_from_kaltura',                     to: 'bright_cove#transfer_from_kaltura'

  resources :ripper
  post '/ripper/watermark/:bucket_name/:s3_video_key', to: 'ripper#watermark'
  post '/ripper/:platform/:s3_video_key/:bucket_name', to: 'ripper#create'
end
