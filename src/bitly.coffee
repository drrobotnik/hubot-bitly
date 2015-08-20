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
# URLS:
#   /bitly/shorten?longUrl=<url> - Shorten the URL using bit.ly
#
# Author:
#   sleekslush
#   drdamour
#   johnwyles
#   jordanwalsh23
#   maxbeatty

qs = require "querystring"

BITLY_API = "https://api-ssl.bitly.com/v3/"

get = (msg, cmd, q, cb) ->
  q.access_token = process.env.HUBOT_BITLY_ACCESS_TOKEN
  msg
    .http(BITLY_API + cmd + qs.stringify(q))
    .get() (err, res, body) ->
      return cb err if err

      try
        cb null, JSON.parse body
      catch e
        cb e

errMsg = (err) -> "Trouble with Bitly API: #{err.message}"

module.exports = (robot) ->
  robot.router.get "/bitly/shorten", (req, res) ->
    try
      longUrl = qs.parse(req.url).longUrl

      get robot, "shorten", {
        longUrl: longUrl
        format: "json"
      }, (err, resp) ->
        if err
          res.statusCode = 500
          res.end err.message
        else
          if resp.status_code is 200
            res.end resp.data.url
          else
            res.statusCode = resp.status_code
            res.end resp.status_txt
    catch e
      res.statusCode = 400
      res.end e.message

  robot.respond /(bitly|shorten)\s?(me)?\s?(.+)$/i, (msg) ->
    get msg, "shorten", {
      longUrl: msg.match[3]
      format: "json"
    }, (err, res) ->
      return msg.send errMsg(err) if err

      msg.send if res.status_code is 200 then res.data.url else res.status_txt

  robot.respond /save\s?(.+)$/i, (msg) ->
    get msg, "user/link_save", {
      longUrl: msg.match[1]
    }, (err, res) ->
      return msg.send errMsg(err) if err

      if res.status_code is 200
        msg.send "Link created: #{res.data.link_save.link}"
      else if res.status_txt is "LINK_ALREADY_EXISTS"
        msg.send "Link already there: #{res.data.link_save.link}"
      else
        msg.send "#{res.status_txt}"

  robot.respond /expand\s?(https?:\/\/(bit\.ly|yhoo\.it|j\.mp|pep\.si|amzn\.to)\/[0-9a-z\-]+)/i, (msg) ->
    msg.send "Expanding short URL: #{msg.match[1]}"

    get msg, "expand", {
      shortUrl: msg.match[1]
    }, (err, res) ->
      return msg.send errMsg(err) if err

      if res.status_code is 200
        msg.send "#{m.short_url} is #{m.long_url}" for m in res.data.expand
      else
        msg.send "Lookup failed #{res.status_txt}"

  robot.respond /stats\s?(.+)$/i, (msg) ->
    get msg, "link/clicks", {
      link: msg.match
    }, (err, res) ->
      return msg.send errMsg(err) if err

      if res.status_code is 200
        msg.send "The link has been clicked #{res.data.link_clicks} times in the last #{res.data.unit}"
      else
        msg.send "An error occurred #{res.status_txt}"
