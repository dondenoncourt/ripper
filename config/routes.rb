Rails.application.routes.draw do
  post 'bright_cove/pullFromS3'

  resources :ripper
  post '/ripper/:youtube_id/:bucket_name', to: 'ripper#create'
end
