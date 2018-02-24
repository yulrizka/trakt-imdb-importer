require 'oauth2'
require 'csv'

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
csv = CSV.read(ARGV[0], headers: true)

nbatch = 20
total_record = csv.count

i = 0
uploaded = 0
csv.each_slice(20) do |batch|

  movies = []
  shows = []

  batch.each do |row|
    entry = {
      "rated_at" => Time.parse(row["Date Added"]).strftime("%FT%T"),
      "rating"   => row["Your Rating"],
      "title"    => row["Title"],
      "year"     => row["Year"],
      "ids"      => {
        "imdb"   => row["Const"]
      }
    }

    ((row["Title Type"] == "tvSeries" || row["Title Type"] == "tvMiniSeries") ?  shows : movies).push entry
  end
  
  request = {
    body: {movies: movies, shows:shows}.to_json,
    headers: headers
  }

  # synchronize ratings
  response_ratings = token.post('sync/ratings', request)

  # synchronize watched
  response_history = token.post('sync/history', request)

  if response_ratings && response_ratings.status == 201 && response_history && response_history.status == 201
    # success
    batch.each do |entry|
      puts "#{entry['Const']} - #{entry['Year']} #{entry['Title']} -> #{entry['Your Rating']}"
    end
  else
    puts "There is some error while sync data"
    puts "sync ratings resposne: #{response_ratings.status}, sync history response: #{response_history.status}"
  end

  i += 1
  uploaded += batch.count
  puts "Uploaded #{uploaded}, #{(1.0 * i * nbatch / total_record * 100).to_i} %"
end
