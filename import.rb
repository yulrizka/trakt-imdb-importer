require 'oauth2'
require 'csv'
require 'json'
require 'facets/hash/except'

##
# Configuration
##

# enter "Client ID" and "Client Secret" here to avoid typing it multiple time
client_id = nil
client_secret = nil

if ARGV.count < 1
  puts
  puts "  use ruby import.rb imdb-filename.csv"
  puts
  exit 1
end

if client_id.nil?
  print "Client ID : "
  client_id = STDIN.gets.chomp
end

if client_secret.nil?
  print "Client Secret : "
  client_secret = STDIN.gets.chomp
end

##
# Generate Session token
##
client =  OAuth2::Client.new(client_id, client_secret, :token_url => '/oauth/token', :site =>'https://api-v2launch.trakt.tv')


## GET access token and ask user to copy
auth_url = client.auth_code.authorize_url(:redirect_uri => 'urn:ietf:wg:oauth:2.0:oob')

puts
puts "Open in browser:"
puts auth_url
puts
print "OAuth Authorization Code : "
auth_token = STDIN.gets.chomp

token = client.auth_code.get_token(auth_token, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob')

headers = {
  'trakt-api-version' =>  '2',
  'trakt-api-key' =>  client_id,
  'Content-Type' => 'application/json'
}

##
# Read from IMDB csv output and send in batch of 20 entries
##
csv = CSV.parse(File.read(ARGV[0]).scrub, headers: true)

headers = headers ? headers : {}

nbatch = 20
total_record = csv.count

i = 0
uploaded = 0
csv.each_slice(20) do |batch|

  movies = []
  shows = []
  episodes = []

  batch.each do |row|
    entry = {
      "rated_at" => Time.parse(row["Date Added"]).strftime("%FT%T"),
      "watched_at" => Time.parse(row["Date Added"]).strftime("%FT%T"),
      "rating"   => row["Your Rating"],
      "title"    => row["Title"],
      "year"     => row["Year"],
      "ids"      => {
        "imdb"   => row["Const"]
      }
    }

    case row["Title Type"]
    when "tvSeries", "tvMiniSeries"
      shows.push entry
    when "movie", "tvMovie"
      movies.push entry
    when "tvEpisode"
      episodes.push entry
    else
      puts "Unhandled #{row["Title Type"]}"
    end
  end

  ratings_request = {
    body: {
      movies: movies.map{|e| e.except("watched_at")},
      shows: shows.map{|e| e.except("watched_at")},
      episodes: episodes.map{|e| e.except("watched_at")},
    }.to_json,
    headers: headers
  }
  history_request = {
    body: {
      movies: movies.map{|e| e.except("rated_at", "rating")},
      # Do NOT include shows in history request because it will mark all episodes as watched on a single
      # date, which is likely not a desired outcome.
      # shows: shows.map{|e| e.except("rated_at", "rating")},
      episodes: episodes.map{|e| e.except("rated_at", "rating")},
    }.to_json,
    headers: headers
  }

  # synchronize ratings
  response_ratings = token.post('sync/ratings', ratings_request)

  # synchronize watched
  response_history = token.post('sync/history', history_request)

  if response_ratings && response_ratings.status == 201 && response_history && response_history.status == 201
    # success
    batch.each do |entry|
      puts "#{entry['Const']} - #{entry['Year']} #{entry['Title']} -> #{entry['Your Rating']}"
    end
  else
    puts "There was an error while syncing data"
    puts "sync ratings resposne: #{response_ratings.status}, sync history response: #{response_history.status}"
  end

  i += 1
  uploaded += batch.count
  puts "Uploaded #{uploaded}, #{(1.0 * i * nbatch / total_record * 100).to_i} %"
end
