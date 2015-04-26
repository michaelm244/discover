hashedURLMap = (() ->
  map = {}

  reservedKeys = ["user_id", "timeDataSent", "version"]

  isReservedKey = (key) ->
    for i in [0..reservedKeys.length-1] by 1
      if key == reservedKeys[i]
        return true

    return false
  

  hashCode = (str) ->
    hash = 0
    if str.length == 0
      return hash

    for i in [0..str.length-1] by 1
      char = str.charCodeAt(i)
      hash = ((hash<<5)-hash)+char
      hash = hash & hash

    hash

  stripParameters = (url) ->
    url.split("?")[0]


  prepareURL = (url) ->
    url = stripParameters(url)
    url = new URL(url)

    afterDomain = url.href.split(url.host)[1]
    hashedAfterDomain = hashCode(afterDomain)

    hashedDomain = hashCode(url.host)

    afterProtocol = url.href.split(url.protocol + "//")[1]
    afterSlashArr = afterProtocol.split("/")
    hash = "/"
    if afterSlashArr[1]
      hash += hashCode(afterSlashArr.slice(1).join('/'))

    finalURL = url.protocol + "//" + hashedDomain + "/" + hashedAfterDomain
    return finalURL

  # loop through localStorage
  for index in [0..localStorage.length-1] by 1
    key = localStorage.key index

    continue if isReservedKey key

    continue if key.indexOf("chrome") == 0 || key.indexOf("file") == 0 || key.indexOf("about") == 0

    splitArr = key.split("/")

    # remove last element (random characters) from splitArr
    splitArr.splice(-1, 1)

    strippedKey = splitArr.join("/")
    map[prepareURL(strippedKey)] = strippedKey

  map
)()

Suggestion = Backbone.Model.extend
  initialize: ->
    console.log "Suggestion created!"


Suggestions = Backbone.Collection.extend
  model: Suggestion
  id: localStorage.user_id
  initialize: (data) ->
    for i in [0..data.length-1] by 1
      currValues = data[i]
      tempSuggestion = new Suggestion currValues
      @add tempSuggestion


SuggestionView = Backbone.View.extend
  model: Suggestion
  className: 'suggestion well'

  initialize: ->
    @recommend_yes_clicked = false
    @shared_yes_clicked = false

  template: _.template $("#suggestion_template").html()
  events:
    'click .recommend_question .yes': 'recommendYesClicked'
    'click .recommend_question .no': 'recommendNoClicked'
    'click .shared_question .yes': 'sharedYesClicked'
    'click .shared_question .no': 'sharedNoClicked'

  recommendYesClicked: () ->
    console.log "Yes clicked!"
    @sendResponse "recommend", "yes"
    @$el.find(".recommend_question .yes").addClass("active")
    @$el.find(".recommend_question .yes span").show()

    if !@recommend_yes_clicked
      # remove glypicon and active from no button
      @$el.find(".recommend_question .no").removeClass("active")
      @$el.find(".recommend_question .no span").hide()

    @recommend_yes_clicked = true
    @$el.find(".shared_question").css "display", "block"


  recommendNoClicked: () ->
    console.log "No clicked!"
    @sendResponse "recommend", "no"
    @$el.find(".recommend_question .no").addClass("active")
    @$el.find(".recommend_question .no span").show()

    if @recommend_yes_clicked
      # remove glypicon and active from yes button
      @$el.find(".recommend_question .yes").removeClass("active")
      @$el.find(".recommend_question .yes span").hide()

    @recommend_yes_clicked = false

  sharedYesClicked: () ->
    console.log "Yes shared clicked"
    @sendResponse "shared", "yes"
    @$el.find(".shared_question .yes").addClass("active")
    @$el.find(".shared_question .yes span").show()

    if !@shared_yes_clicked
      # remove glypicon and active from no button
      @$el.find(".shared_question .no").removeClass("active")
      @$el.find(".shared_question .no span").hide()


    @shared_yes_clicked = true


  sharedNoClicked: () ->
    console.log "No shared clicked"
    @sendResponse "shared", "no"
    @$el.find(".shared_question .no").addClass("active")
    @$el.find(".shared_question .no span").show()

    if @shared_yes_clicked
      # remove glypicon and active from yes button
      @$el.find(".shared_question .yes").removeClass("active")
      @$el.find(".shared_question .yes span").hide()


    @shared_yes_clicked = false

  sendResponse: (question, answer) ->
    data = @model.attributes
    data.question = question
    data.answer = answer
    $.post("http://104.131.5.95:9292/feedback", data).done (response) ->
      console.log "got response from feedback"
      console.log response

  render: () ->
    @$el.html @template(@model.attributes)
    @


SuggestionViews = Backbone.View.extend
  el: "#suggestions_container"
  render: ->
    console.log "suggestion views render called"
    for index in [0 .. @collection.length - 1] by 1
      suggestionModel = @collection.at index
      console.log "in each loop"
      tempSuggestionView = new SuggestionView({model: suggestionModel})
      @$el.append tempSuggestionView.render().el

user_id = localStorage["user_id"]

inWhiteList = (elem, whitelist) ->
  for i in [0..whitelist.length-1] by 1
    return true if whitelist[i] == elem
  false

filterData = (data, whitelistSites) ->
  filteredData = []
  for i in [0..data.length-1] by 1
    entry = data[i]
    url = hashedURLMap[entry["url"]]
    entry["actualURL"] = url
    urlObj = new URL(url)
    hostname = urlObj.host
    hostname = hostname.substring(4) if hostname.startsWith("www.")
    passChecks = inWhiteList(hostname, whitelistSites) && urlObj.href != urlObj.origin
    filteredData.push entry if passChecks
  filteredData




$.ajax("http://104.131.5.95:9292/suggested_sites/"+user_id).done (data) ->
  $.ajax("http://104.131.5.95:9292/whitelist_sites").done (siteData) ->
    $("#loader").hide()
    whitelistSites = JSON.parse siteData
    parsedData = JSON.parse data
    filteredData = filterData parsedData, whitelistSites
    daCollection = new Suggestions filteredData
    daViews = new SuggestionViews {collection: daCollection}
    daViews.render()
