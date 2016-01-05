# Description:
#   Where ... in the world ... is ... Carmen San Diego?
#
# Commands:
#   hubot I'm [in|at] /location/
#   hubot Where is /user/?

request = require 'request'

module.exports = (robot) ->

  robot.respond /(?:I\'m|I am) (?:in|at) (.*)/i, (msg) ->
    location = msg.match[1]
    user = robot.brain.userForName(msg.message.user.name)
    if !user?
      user = robot.brain.usersForFuzzyName(msg.message.user.name)[0]

    geocoder = require('node-geocoder')('google', 'http')
    geocoder.geocode location, (err, res) ->
      if res.length && 'latitude' of res[0] && 'longitude' of res[0]
        lat = res[0]["latitude"]
        lng = res[0]["longitude"]

        user.location = "#{lat},#{lng}"
        options =
          url: "https://maps.googleapis.com/maps/api/timezone/json?location=#{user.location}&timestamp=#{(new Date).getTime()/1000}"
          method: "GET"
          headers: { "Accept": "application/json" }
          json: true

        request options, (err, resp, body) ->
          user.tz = body["timeZoneId"]
          msg.send "Great, #{user.name}! I have you at #{user.location}. I've set your time zone to #{user.tz}."
      else
        msg.send "Sorry, I don't know where '#{location}' is. (Error message: #{err})"


  robot.respond /Where is (\w+)/i, (msg) ->
    username = msg.match[1].trim() || msg.message.user.mention_name
    console.log("'#{username}'")
    user = robot.brain.userByNameOrMention(username)
    if user
      if user.location
        mapUrl   = "http://maps.google.com/maps/api/staticmap?markers=" +
                    user.location +
                    "&size=400x400&maptype=roadmap" +
                    "&sensor=false" +
                    "&format=png&zoom=7" # So hipchat knows it's an image
        url      = "https://www.google.com/maps/place/#{user.location}/@#{user.location},7z"

        msg.send mapUrl
        msg.send url
      else
        msg.send "I don't know where #{username} is..."
    else
      msg.send "I'm not sure who that is..."
