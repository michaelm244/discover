###hashedURLMap = (() ->
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


  prepareURL: (url) ->
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
    key = localStorage[localStorage.key(index)]

    continue if isReservedKey key

    continue if key.indexOf("chrome") == 0 || key.indexOf("file") == 0

    splitArr = key.split("/")

    # remove last element (random characters) from splitArr
    splitArr.splice(-1, 1)

    strippedKey = splitArr.join("/")
    map[prepareURL(strippedKey)] = strippedKey

  map
)()
###

Suggestion = Backbone.Model.extend
  initialize: ->
    console.log "Suggestion created!"


Suggestions = Backbone.Collection.extend
  model: Suggestion
  id: localStorage.user_id
  initialize: () ->
    data = '[["https://1336620259/-1865884866",{"time":85.4,"visits":2}],["http://-1461647955/-329857453",{"time":105.7,"visits":1}],["https://1336620259/-1498644975",{"time":109.8,"visits":1}],["https://1336620259/1932163536",{"time":118,"visits":2}],["https://1336620259/515659514",{"time":122.7,"visits":2}],["https://1161408131/873697920",{"time":123.8,"visits":7}],["http://-1461647955/-1221313457",{"time":127.7,"visits":3}],["https://908730519/-1127123183",{"time":127.79999999999998,"visits":10}],["http://859740285/47",{"time":128.8,"visits":1}],["https://-12310945/1458473472",{"time":132.8,"visits":4}],["https://908730519/-1478544918",{"time":134.29999999999998,"visits":8}],["http://-1461647955/1968165150",{"time":138.6,"visits":1}],["https://1336620259/-384157168",{"time":141.3,"visits":3}],["https://1336620259/-1561714229",{"time":142.4,"visits":2}],["http://-1461647955/-2012476131",{"time":166.6,"visits":1}],["https://1336620259/-500442110",{"time":169.89999999999998,"visits":10}],["https://1336620259/-721592843",{"time":181.2,"visits":3}],["https://1336620259/-1602218541",{"time":186.1,"visits":2}],["https://1672584528/2029063872",{"time":188.6,"visits":1}],["https://1336620259/-719678335",{"time":190,"visits":2}],["https://1336620259/-1142839436",{"time":190.7,"visits":7}],["https://1336620259/986053840",{"time":191.5,"visits":1}],["http://-1461647955/-722880546",{"time":192.3,"visits":3}],["https://1336620259/260165802",{"time":194,"visits":1}],["http://-1461647955/-1700963008",{"time":194.4,"visits":1}],["https://1336620259/-1966037326",{"time":194.7,"visits":1}],["http://-1461647955/-336024429",{"time":198,"visits":3}],["https://1336620259/547760829",{"time":209.20000000000002,"visits":5}],["https://1336620259/-191643119",{"time":212.9,"visits":3}],["https://1336620259/-2118968265",{"time":220.8,"visits":4}],["https://2081003886/151460490",{"time":227.39999999999998,"visits":6}],["http://-1461647955/1311909330",{"time":231.7,"visits":1}],["https://1336620259/972691373",{"time":232.79999999999998,"visits":5}],["https://597092302/-1625101360",{"time":244.70000000000002,"visits":8}],["http://943491918/-1747151015",{"time":252.6,"visits":3}],["https://972008222/-1894467180",{"time":255.20000000000002,"visits":5}],["https://1336620259/904055070",{"time":255.8,"visits":1}],["https://1336620259/289700045",{"time":257,"visits":8}],["https://1336620259/952629178",{"time":258,"visits":1}],["http://685702956/-1916170151",{"time":258.6,"visits":5}],["http://-1461647955/354018746",{"time":260.4,"visits":1}],["http://-1461647955/-680832966",{"time":260.8,"visits":1}],["http://-1461647955/-1500030145",{"time":263.3,"visits":2}],["https://1672584528/1046703345",{"time":265,"visits":2}],["https://1336620259/-325565481",{"time":265.6,"visits":2}],["http://-1967263584/1403190920",{"time":268.5,"visits":1}],["https://1336620259/-1657307767",{"time":270.3,"visits":6}],["https://1336620259/913452306",{"time":274.4,"visits":2}],["http://-1461647955/-1998837599",{"time":279.29999999999995,"visits":10}],["https://1336620259/-1472280034",{"time":279.9,"visits":2}],["http://-1461647955/-1339303439",{"time":290.5,"visits":1}],["https://534699487/407227082",{"time":294.5,"visits":2}],["https://1336620259/-1385623072",{"time":297.3,"visits":2}],["http://-1461647955/1094174396",{"time":305.4,"visits":1}],["http://-1461647955/1166536885",{"time":308.9,"visits":1}],["http://-1461647955/-1325031935",{"time":311.79999999999995,"visits":2}],["https://1336620259/589278621",{"time":326.99999999999994,"visits":4}],["https://-492966685/777008044",{"time":333,"visits":4}],["http://-1461647955/1323101069",{"time":335.3,"visits":1}],["https://671244258/-1283234390",{"time":335.4,"visits":1}],["https://1336620259/902848432",{"time":337.7,"visits":2}],["https://1336620259/-1807819726",{"time":339,"visits":3}],["https://-1291551832/807984089",{"time":344.5,"visits":8}],["https://1336620259/132592556",{"time":346.9,"visits":1}],["https://1336620259/-349037938",{"time":347.5,"visits":1}],["https://1336620259/1160131078",{"time":353.79999999999995,"visits":3}],["https://1336620259/2083954729",{"time":355.20000000000005,"visits":3}],["http://-1461647955/332235519",{"time":366.2,"visits":1}],["http://-1461647955/332735667",{"time":387,"visits":4}],["https://908730519/1115333472",{"time":400.3,"visits":9}],["http://-1461647955/2068160176",{"time":417.59999999999997,"visits":5}],["https://1336620259/-9193114",{"time":423,"visits":1}],["https://1336620259/-849557772",{"time":449.8,"visits":1}],["https://1336620259/1233735586",{"time":473.2,"visits":1}],["https://1336620259/40202260",{"time":488.5,"visits":2}],["https://1336620259/1430760977",{"time":489.4,"visits":3}],["https://1336620259/-331477467",{"time":544.1,"visits":3}],["https://1336620259/-877436553",{"time":570.5000000000002,"visits":9}],["https://1336620259/-1173196801",{"time":595.5999999999999,"visits":4}],["https://1336620259/-1736020500",{"time":608.5000000000001,"visits":3}],["https://534699487/1426549144",{"time":673.3000000000001,"visits":4}],["https://1336620259/2104102466",{"time":685.3,"visits":5}],["https://1336620259/2043823847",{"time":689.2,"visits":8}],["https://1336620259/382828935",{"time":758.3000000000001,"visits":9}],["http://1981678958/295941377",{"time":799.5,"visits":7}],["http://-1461647955/-1417710568",{"time":836.3000000000001,"visits":8}],["https://1336620259/-906028957",{"time":871.3,"visits":8}],["http://-1461647955/1308648331",{"time":887.4000000000001,"visits":4}],["https://1336620259/-787382951",{"time":969.0000000000001,"visits":3}],["https://1336620259/-1607527021",{"time":1023.1,"visits":1}],["http://191390384/1462819722",{"time":1206.7,"visits":2}],["https://1336620259/-109667193",{"time":1376.3000000000002,"visits":5}],["https://-30401708/-150984200",{"time":40672.4,"visits":3}]]'
    data = JSON.parse data
    for i in [0..data.length-1] by 1
      ###
      currValues = 
        hashedURL: data[i][0]
        actualURL: hashedURLMap[data[i][0]]
        time: data[i][1]["time"]
        visits: data[i][1]["visits"]
      ###
      tempSuggestion = new Suggestion {hashedURL: "hashedURL", actualURL: "https://google.com/#{i}/"}
      @add tempSuggestion


SuggestionView = Backbone.View.extend
  model: Suggestion
  template: _.template $("#suggestion_template").html()
  events:
    'click .yes': 'yesClicked'
    'click .no': 'noClicked'

  yesClicked: () ->
    alert "Yes clicked!"

  noClicked: () ->
    alert "No clicked!"

  render: () ->
    @$el.html @template(@model.attributes)
    @


SuggestionViews = Backbone.View.extend
  el: "#suggestions_container"
  render: ->
    console.log "suggesiton views render called"
    for index in [0 .. @collection.length - 1] by 1
      suggestionModel = @collection.at index
      console.log "in each loop"
      tempSuggestionView = new SuggestionView({model: suggestionModel})
      @$el.append tempSuggestionView.render().el


daCollection = new Suggestions
daViews = new SuggestionViews {collection: daCollection}
daViews.render()




