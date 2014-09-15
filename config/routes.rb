Rails.application.routes.draw do
  post '/bright_cove/:riff_video_id/:bucket_name/:s3_video_key', to: 'bright_cove#pullFromS3'

  resources :ripper
  post '/ripper/:platform/:image_key/:bucket_name', to: 'ripper#create'
end
