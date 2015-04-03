hashedURLMap = (() ->
  map = {}

  reservedKeys = ["user_id", "timeDataSent", "version"]

  isReservedKey = (key) ->
    for i in [0..reservedKeys.length-1] by 1
      if(key == reservedKeys[i]) return true

    return false
  

  hashCode = (str) ->
    hash = 0
    if (str.length == 0) return hash

    for i in [0..str.length-1] by 1
      char = str.charCodeAt(i)
      hash = ((hash<<5)-hash)+char
      hash = hash & hash

    hash

  stripParameters = (url) ->
    url.split("?")[0]


  prepareURL: (url) ->
    url = stripParameters(url)
    url = new URL(url)

    var afterDomain = url.href.split(url.host)[1]
    var hashedAfterDomain = hashCode(afterDomain)

    var hashedDomain = hashCode(url.host)


    var afterProtocol = url.href.split(url.protocol + "//")[1]
    var afterSlashArr = afterProtocol.split("/")
    var hash = "/"
    if(afterSlashArr[1]) {
      hash += hashCode(afterSlashArr.slice(1).join('/'))
    }
    var finalURL = url.protocol + "//" + hashedDomain + "/" + hashedAfterDomain
    return finalURL

  # loop through localStorage
  for index in [0..localStorage.length-1] by 1
    key = localStorage[localStorage.key(index)]

    continue if isReservedKey key

    continue if(key.indexOf("chrome") == 0 || key.indexOf("file") == 0)

    splitArr = key.split("/")

    # remove last element (random characters) from splitArr
    splitArr.splice(-1, 1)

    strippedKey = splitArr.join("/")
    map[prepareURL(strippedKey)] = strippedKey

  map
)()

Suggestion = Backbone.Model.extend
  initialize: ->
    @sync


Suggestions = Backbone.Collection.extend
  model: Suggestion
  id: localStorage.user_id
  initialize: (data) ->
    for i in [0..data.length-1] by 1
      currValues = 
        hashedURL: data[i][0]
        actualURL: hashedURLMap[data[i][0]]
        time: data[i][1]["time"]
        visits: data[i][1]["visits"]
      tempSuggestion = new Suggestion {hashedURL: data[i][0], actualURL: hashedURLMap[data[i][0]]}
      @add tempSuggestion








