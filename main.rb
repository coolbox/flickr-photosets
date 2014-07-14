require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'flickraw'

class App < Sinatra::Base
  configure { set :server, :puma }

  use Rack::Deflater
  
  get '/' do
    erb(:index)
  end

  get '/photoset/:photoset' do
    content_type :text

    # Init Flickr
    FlickRaw.api_key       = ENV["FLICKR_API_KEY"]
    FlickRaw.shared_secret = ENV["FLICKR_SHARED_SECRET"]
    flickr.access_token    = ENV["FLICKR_ACCESS_TOKEN"]
    flickr.access_secret   = ENV["FLICKR_ACCESS_SECRET"]

    # Photoset
    photoset_id = params[:photoset]

    if !photoset_id.nil?
      images = flickr.photosets.getPhotos(photoset_id: photoset_id, extras: "url_o")
      
      codes = ""
      images["photo"].each_with_index do |photo, index|
        if index == 0
          codes += "<p>"
          codes +=  "\n"
        end

        codes += "<img src='#{photo["url_o"]}' width='100%' alt='#{photo["title"]}' border='0'>"
        codes +=  "\n"

        if images["photo"].length == (index + 1)
          codes += "</p>"
        else
          codes += "<br />"
          codes +=  "\n"
        end
      end

      # Copy to clipboard
      # Doesn't seem to work on Heroku.
      # IO.popen('pbcopy', 'w') { |f| f << codes }

      # Output just incase
      p codes
    else
      p "No photoset id."
    end
  end
end