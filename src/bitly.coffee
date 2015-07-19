# Description:
#   Shorten URLs with bit.ly & expand detected bit.ly URLs
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_BITLY_ACCESS_TOKEN
#
# Commands:
#   hubot (bitly|shorten) (me) <url> - Shorten the URL using bit.ly
#   hubot save <url> - Shorten the URL using bit.ly and saves it to the bit.ly profile
#   hubot stats <url> - Returns the clicks in the last day
#   hubot expand http://bit.ly/[hash] - looks up the real url
#
# Author:
#   sleekslush
#   drdamour
#   johnwyles
#   jordanwalsh23

module.exports = (robot) ->
  robot.respond /(bitly|shorten)\s?(me)?\s?(.+)$/i, (msg) ->
    msg
      .http("https://api-ssl.bitly.com/v3/shorten")
      .query
        access_token: process.env.HUBOT_BITLY_ACCESS_TOKEN
        longUrl: msg.match[3]
        format: "json"
      .get() (err, res, body) ->
        response = JSON.parse body
        msg.send if response.status_code is 200 then response.data.url else response.status_txt

  robot.respond /save\s?(.+)$/i, (msg) ->
    msg
      .http("https://api-ssl.bitly.com/v3/user/link_save")
      .query
        access_token: process.env.HUBOT_BITLY_ACCESS_TOKEN
        longUrl: msg.match[1]
      .get() (err, res, body) ->
        response = JSON.parse body
        if response.status_code is 200
          msg.send "Link created: #{response.data.link_save.link}"
        else if response.status_txt is "LINK_ALREADY_EXISTS"
            msg.send "Link already there: #{response.data.link_save.link}"
        else 
          msg.send "#{response.status_txt}"

  robot.respond /expand\s?(https?:\/\/(bit\.ly|yhoo\.it|j\.mp|pep\.si|amzn\.to)\/[0-9a-z\-]+)/i, (msg) ->
    msg.send "Matched: #{msg.match[1]}"
    msg
      .http("https://api-ssl.bitly.com/v3/expand")
      .query
        access_token: process.env.HUBOT_BITLY_ACCESS_TOKEN
        shortUrl: msg.match[1]
      .get() (err, res, body) ->
        parsedBody = JSON.parse body
        if parsedBody.status_code is not 200
          msg.send "Lookup failed #{response.status_txt}"
          return

        msg.send "#{m.short_url} is #{m.long_url}" for m in parsedBody.data.expand

  robot.respond /stats\s?(.+)$/i, (msg) ->
    msg
      .http("https://api-ssl.bitly.com/v3/link/clicks")
      .query
        access_token: process.env.HUBOT_BITLY_ACCESS_TOKEN
        link: msg.match
      .get() (err, res, body) ->
        response = JSON.parse body
        if response.status_code is 200
          msg.send "The link has been clicked #{response.data.link_clicks} times in the last #{response.data.unit}" 
        else 
          msg.send "An error occurred #{response.status_txt}"

