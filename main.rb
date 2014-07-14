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
    FlickRaw.api_key = "c454fcc23bb577254855c70d5b04e53f"
    FlickRaw.shared_secret = "85c0d7f0b6a8f769"
    flickr.access_token = "72157645272349609-5cd243ab5ff0a23e"
    flickr.access_secret = "152c2607d9c7cc0c"

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