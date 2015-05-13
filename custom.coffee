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

    continue if key.indexOf("view-source:") == 0

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

  fetchAnswers: ->
    ajaxObj = $.ajax("http://104.131.5.95:9292/feedback?url=#{@.get("url")}&user_id=#{localStorage.user_id}")
    ajaxObj.done (data) =>
      console.log "got data"
      console.log data
      parsedData = JSON.parse data
      @.set({"recommend_yes_clicked": parsedData[0], "shared_yes_clicked": parsedData[1]})
    ajaxObj


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

  template: _.template $("#suggestion_template").html()
  events:
    'click .recommend_question .yes': 'recommendYesClicked'
    'click .recommend_question .no': 'recommendNoClicked'
    'click .shared_question .yes': 'sharedYesClicked'
    'click .shared_question .no': 'sharedNoClicked'

  changeState: (questionClassName, answerClassName) ->
    @$el.find("#{questionClassName} #{answerClassName}").addClass("active")
    @$el.find("#{questionClassName} #{answerClassName} span").show()

    oppositeClassName = if answerClassName == ".yes" then ".no" else ".yes"

    @$el.find("#{questionClassName} #{oppositeClassName}").removeClass("active")
    @$el.find("#{questionClassName} #{oppositeClassName} span").hide()

    answerBoolVal = if answerClassName == ".yes" then true else false
    questionVal = if questionClassName == ".recommend_question" then "recommend_yes_clicked" else "shared_yes_clicked"
    @model.set({questionVal: answerBoolVal})

  recommendYesClicked: () ->
    console.log "Yes clicked!"
    @sendResponse "recommend", "yes"
    
    @changeState ".recommend_question", ".yes"

    @$el.find(".shared_question").show()


  recommendNoClicked: () ->
    console.log "No clicked!"
    @sendResponse "recommend", "no"
    
    @changeState ".recommend_question", ".no"

    @$el.find(".shared_question").hide()

  sharedYesClicked: () ->
    console.log "Yes shared clicked"
    @sendResponse "shared", "yes"
    
    @changeState ".shared_question", ".yes"

    @shared_yes_clicked = true


  sharedNoClicked: () ->
    console.log "No shared clicked"
    @sendResponse "shared", "no"
    
    @changeState ".shared_question", ".no"

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
    if @model.get("recommend_yes_clicked")
      @changeState ".recommend_question", ".yes"

    if @model.get("shared_yes_clicked")
      @changeState ".shared_question", ".yes"
    @


SuggestionViews = Backbone.View.extend
  el: "#suggestions_container"

  insertElem: (collectionView, view) ->
    collectionView.$el.append view.render().el

  render: ->
    console.log "suggestion views render called"
    for index in [0 .. @collection.length - 1] by 1
      suggestionModel = @collection.at index
      console.log "in each loop"
      tempSuggestionView = new SuggestionView({model: suggestionModel})
      console.log suggestionModel
      suggestionModel.fetchAnswers().done @insertElem(@, tempSuggestionView)

user_id = localStorage["user_id"]

if typeof String.prototype.startsWith != 'function'
  String.prototype.startsWith =  (str) ->
    return this.indexOf(str) == 0

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
    try
      urlObj = new URL(url)
      hostname = urlObj.host
      if hostname and typeof hostname == "string"
        hostname = hostname.substring(4) if hostname.startsWith("www.")
        passChecks = inWhiteList(hostname, whitelistSites) && urlObj.pathname != "/"
        filteredData.push entry if passChecks
    catch error
      console.log error
      console.log "could not parse the url #{url}"
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
