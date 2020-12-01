# Trakt IMDB importer

[Trakt.tv](http://trakt.tv/) is a service where you can subscribe, rate, comments movies or TV shows. It also have integration with some multimedia app such as XBMC, KODI, etc. 

This script will import ratings from IMDB csv output and import it to Trakt.tv using their v2 API via OAuth.

The script is realtively simple < 106 lines of code. You can modify it according to your needs: 

* If you have some time out problem, you might want to reduce the batch (currently 20 shows/movies) per batch.
* You could also filter out TV Shows if you don't want to include them. Just modify the request 

Warning: The author doesn't guarantee anything including the outcome of the running the script. use at your own risk!.

## Getting IMDB csv file.

1. Login to IMDB
2. Form "Your Name" drop down, select "Your Lists"
3. Select "Your Ratings" list
4. At the bottom of the page there is link "Export this list"
5. Save the file on your computer

## Using the script

### installing

clone the repository

**Make sure you have ruby * bundler installed**

Most osx already came with ruby installed. to check 

    $ ruby -v

to install [bundler](http://bundler.io/)

    $ gem install bundler 

    # or with sudo

    $ sudo gem install bundler


after bundler is install, download dependency with

    $ bundle

### Create Trakt.tv application

In order to use OAUTH, you need to create an application on trakt.tv

1. Go to  [Create Application on trakt.tv](https://trakt.tv/oauth/applications/new)
2. Enter Name & Description as you wish
3. Enter Redirect uri: `urn:ietf:wg:oauth:2.0:oob`
4. Tick checking & scrobble
5. Copy "Client ID" & "Client Secret"

### Run the application

suppose you have the csv file name 'ratings-imdb.csv' in the same directory as the project

execute 

    $ bundle exec ruby import.rb ratings-imdb.csv

1. it will ask for "Client ID" and "Client Secreet" you obtain erlier. Copy paste (and enter) for each value
2. It will then ask you to open link in the browser. Login with your account and authorize the app.
3. Copy the "OAUTH AUTHORIZATION CODE" to the terminal
4. It will then post all the reatings & history (mark as watched) data from IMDB to trakt.
