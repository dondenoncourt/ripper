Rails.application.routes.draw do
  post '/bright_cove/:bucket_name/:s3_video_key', to: 'bright_cove#pullFromS3'

  resources :ripper
  post '/ripper/:youtube_id/:bucket_name', to: 'ripper#create'
end
