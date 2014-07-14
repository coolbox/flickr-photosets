require 'sinatra'
require 'json'
require 'net/http'
require 'uri'

class App < Sinatra::Base
  configure { set :server, :puma }

  use Rack::Deflater

  get '/photoset/:photoset' do
    content_type :text

    # Photoset
    photoset_id = params[:photoset]

    if !photoset_id.nil?
      # Flickr API Extras docs:
      # http://librdf.org/flickcurl/api/flickcurl-searching-search-extras.html
      url = "https://api.flickr.com/services/rest/?method=flickr.photosets.getPhotos&api_key=#{ENV['FLICKR_API_KEY']}&photoset_id=#{photoset_id}&extras=url_o&per_page=500&format=json&nojsoncallback=1"
      response = Net::HTTP.get_response(URI.parse(url))
      images = JSON.parse(response.body)

      codes = ""
      images["photoset"]["photo"].each_with_index do |photo, index|
        if index == 0
          codes += "<p>"
          codes +=  "\n"
        end

        codes += "<img src='#{photo["url_m"]}' width='100%' alt='#{photo["title"]}' border='0'>"
        codes +=  "\n"

        if images["photoset"]["photo"].length == (index + 1)
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

  get '/runkeeper' do
    content_type :json
    response['Access-Control-Allow-Origin'] = "*"
    code = params["code"]

    url = "https://runkeeper.com/apps/token?redirect_uri=#{ENV['REDIRECT_URI']}&grant_type=authorization_code&client_id=#{ENV['RUNKEEPER_CLIENT_ID']}&client_secret=#{ENV['RUNKEEPER_CLIENT_SECRET']}&code=#{code}"
    uri = URI.parse(url)

    # Shortcut
    response = Net::HTTP.post_form(uri, {})

    json_response = JSON.parse(response.body)
    access_token = json_response["access_token"]

    p access_token

    uri = URI.parse("https://api.runkeeper.com/profile")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Bearer #{access_token}"

    response = http.request(request)
    hash = {}
    hash[:token ] = access_token
    hash[:response] = JSON.parse(response.body)
    hash.to_json
  end

  get '/fitnessActivities' do
    content_type :json
    response['Access-Control-Allow-Origin'] = "*"

    access_token = params["token"]
    request['Authorization'] = 'Bearer ' + access_token
    uri = URI.parse("https://api.runkeeper.com/fitnessActivities?pageSize=500&has_path=true&start_time=S")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = 'Bearer ' + access_token

    response = http.request(request)
    json_response = JSON.parse(response.body)
    ids = []

    start_date = DateTime.new(2013, 01, 01) #2013
    end_date = DateTime.new(2014, 01, 01) #2014

    # Reverse them so we get them chronologically
    json_response["items"].reverse.each do |activity|
      # 2013 activities only
      activity_start_date = Date.parse(activity["start_time"])
      if activity_start_date > start_date && activity_start_date < end_date
        ids << activity["uri"].split('/').last if activity["has_path"]
      end
    end
    p ids
    ids.to_json
  end

  get '/fitnessActivities/:id' do
    content_type :json
    response['Access-Control-Allow-Origin'] = "*"

    access_token = params["token"]
    request['Authorization'] = 'Bearer ' + access_token
    uri = URI.parse("https://api.runkeeper.com/fitnessActivities/" + params[:id] )
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = 'Bearer ' + access_token

    response = http.request(request)
    response.body

  end

  get '/stravaActivities' do
    content_type :json
    response['Access-Control-Allow-Origin'] = "*"

    access_token = params["token"]
    request['Authorization'] = 'Bearer ' + access_token
    page_no = params["page"] || 1
    uri = URI.parse("https://www.strava.com/api/v3/athlete/activities?per_page=200&page=#{page_no}&after=1356998400&before=1388534400")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = 'Bearer ' + access_token

    response = http.request(request)
    json_response = JSON.parse(response.body)
    polylines = []

    json_response.each do |activity|
      puts activity
      next unless activity["map"]["summary_polyline"]
      hash = {}
      hash["summary_polyline"] = activity["map"]["summary_polyline"]
      hash["distance"] = activity["distance"]
      hash["time"] = activity["start_date"]
      polylines << hash
    end
    polylines.to_json
  end

  get '/' do
    erb(:index)
  end

  get '/designs' do
    erb(:designs)
  end

  get '/myprint' do
    erb(:myprint)
  end

  get '/design' do
    erb(:design, :layout => :design_layout)
  end

  get '/complete' do
    erb(:complete, :layout => :logged_in_layout)
  end

  post '/saveImage' do
    content_type :json
    response['Access-Control-Allow-Origin'] = "*"

    AWS::S3::Base.establish_connection!(
      access_key_id:     ENV["AMAZON_ACCESS_KEY_ID"],
      secret_access_key: ENV["AMAZON_SECRET_ACCESS_KEY"]
    )

    filename = params[:dataFilename]
    file = params[:data][:tempfile]
    AWS::S3::S3Object.store(filename, open(file), 'sisu-prints', :access => :public_read)

    hash = {
      success: true,
      filename: filename
    }
    hash.to_json
  end

  get '/faqs' do
    erb(:faqs, :layout => :logged_in_layout)
  end
end