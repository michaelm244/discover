// Generated by CoffeeScript 1.9.1
(function() {
  var Suggestion, SuggestionView, SuggestionViews, Suggestions, filterData, hashedURLMap, inWhiteList, user_id;

  hashedURLMap = (function() {
    var hashCode, index, isReservedKey, j, key, map, prepareURL, ref, reservedKeys, splitArr, stripParameters, strippedKey;
    map = {};
    reservedKeys = ["user_id", "timeDataSent", "version"];
    isReservedKey = function(key) {
      var i, j, ref;
      for (i = j = 0, ref = reservedKeys.length - 1; j <= ref; i = j += 1) {
        if (key === reservedKeys[i]) {
          return true;
        }
      }
      return false;
    };
    hashCode = function(str) {
      var char, hash, i, j, ref;
      hash = 0;
      if (str.length === 0) {
        return hash;
      }
      for (i = j = 0, ref = str.length - 1; j <= ref; i = j += 1) {
        char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash;
      }
      return hash;
    };
    stripParameters = function(url) {
      return url.split("?")[0];
    };
    prepareURL = function(url) {
      var afterDomain, afterProtocol, afterSlashArr, finalURL, hash, hashedAfterDomain, hashedDomain;
      url = stripParameters(url);
      url = new URL(url);
      afterDomain = url.href.split(url.host)[1];
      hashedAfterDomain = hashCode(afterDomain);
      hashedDomain = hashCode(url.host);
      afterProtocol = url.href.split(url.protocol + "//")[1];
      afterSlashArr = afterProtocol.split("/");
      hash = "/";
      if (afterSlashArr[1]) {
        hash += hashCode(afterSlashArr.slice(1).join('/'));
      }
      finalURL = url.protocol + "//" + hashedDomain + "/" + hashedAfterDomain;
      return finalURL;
    };
    for (index = j = 0, ref = localStorage.length - 1; j <= ref; index = j += 1) {
      key = localStorage.key(index);
      if (isReservedKey(key)) {
        continue;
      }
      if (key.indexOf("chrome") === 0 || key.indexOf("file") === 0 || key.indexOf("about") === 0) {
        continue;
      }
      if (key.indexOf("view-source:") === 0) {
        continue;
      }
      splitArr = key.split("/");
      splitArr.splice(-1, 1);
      strippedKey = splitArr.join("/");
      map[prepareURL(strippedKey)] = strippedKey;
    }
    return map;
  })();

  Suggestion = Backbone.Model.extend({
    initialize: function() {
      return console.log("Suggestion created!");
    },
    fetchAnswers: function() {
      var ajaxObj;
      ajaxObj = $.ajax("http://104.131.5.95:9292/feedback?url=" + (this.get("url")) + "&user_id=" + localStorage.user_id);
      ajaxObj.done((function(_this) {
        return function(data) {
          var parsedData;
          console.log("got data");
          console.log(data);
          parsedData = JSON.parse(data);
          return _this.set({
            "recommend_yes_clicked": parsedData[0],
            "shared_yes_clicked": parsedData[1]
          });
        };
      })(this));
      return ajaxObj;
    }
  });

  Suggestions = Backbone.Collection.extend({
    model: Suggestion,
    id: localStorage.user_id,
    initialize: function(data) {
      var currValues, i, j, ref, results, tempSuggestion;
      results = [];
      for (i = j = 0, ref = data.length - 1; j <= ref; i = j += 1) {
        currValues = data[i];
        tempSuggestion = new Suggestion(currValues);
        results.push(this.add(tempSuggestion));
      }
      return results;
    }
  });

  SuggestionView = Backbone.View.extend({
    model: Suggestion,
    className: 'suggestion well',
    initialize: function() {},
    template: _.template($("#suggestion_template").html()),
    events: {
      'click .recommend_question .yes': 'recommendYesClicked',
      'click .recommend_question .no': 'recommendNoClicked',
      'click .shared_question .yes': 'sharedYesClicked',
      'click .shared_question .no': 'sharedNoClicked'
    },
    changeState: function(questionClassName, answerClassName) {
      var answerBoolVal, oppositeClassName, questionVal;
      this.$el.find(questionClassName + " " + answerClassName).addClass("active");
      this.$el.find(questionClassName + " " + answerClassName + " span").show();
      oppositeClassName = answerClassName === ".yes" ? ".no" : ".yes";
      this.$el.find(questionClassName + " " + oppositeClassName).removeClass("active");
      this.$el.find(questionClassName + " " + oppositeClassName + " span").hide();
      answerBoolVal = answerClassName === ".yes" ? true : false;
      questionVal = questionClassName === ".recommend_question" ? "recommend_yes_clicked" : "shared_yes_clicked";
      return this.model.set({
        questionVal: answerBoolVal
      });
    },
    recommendYesClicked: function() {
      console.log("Yes clicked!");
      this.sendResponse("recommend", "yes");
      this.changeState(".recommend_question", ".yes");
      return this.$el.find(".shared_question").show();
    },
    recommendNoClicked: function() {
      console.log("No clicked!");
      this.sendResponse("recommend", "no");
      this.changeState(".recommend_question", ".no");
      return this.$el.find(".shared_question").hide();
    },
    sharedYesClicked: function() {
      console.log("Yes shared clicked");
      this.sendResponse("shared", "yes");
      this.changeState(".shared_question", ".yes");
      return this.shared_yes_clicked = true;
    },
    sharedNoClicked: function() {
      console.log("No shared clicked");
      this.sendResponse("shared", "no");
      this.changeState(".shared_question", ".no");
      return this.shared_yes_clicked = false;
    },
    sendResponse: function(question, answer) {
      var data;
      data = this.model.attributes;
      data.question = question;
      data.answer = answer;
      return $.post("http://104.131.5.95:9292/feedback", data).done(function(response) {
        console.log("got response from feedback");
        return console.log(response);
      });
    },
    render: function() {
      this.$el.html(this.template(this.model.attributes));
      if (this.model.get("recommend_yes_clicked")) {
        this.changeState(".recommend_question", ".yes");
      }
      if (this.model.get("shared_yes_clicked")) {
        this.changeState(".shared_question", ".yes");
      }
      return this;
    }
  });

  SuggestionViews = Backbone.View.extend({
    el: "#suggestions_container",
    insertElem: function(collectionView, view) {
      return collectionView.$el.append(view.render().el);
    },
    render: function() {
      var index, j, ref, results, suggestionModel, tempSuggestionView;
      console.log("suggestion views render called");
      results = [];
      for (index = j = 0, ref = this.collection.length - 1; j <= ref; index = j += 1) {
        suggestionModel = this.collection.at(index);
        console.log("in each loop");
        tempSuggestionView = new SuggestionView({
          model: suggestionModel
        });
        console.log(suggestionModel);
        results.push(suggestionModel.fetchAnswers().done(this.insertElem(this, tempSuggestionView)));
      }
      return results;
    }
  });

  user_id = localStorage["user_id"];

  if (typeof String.prototype.startsWith !== 'function') {
    String.prototype.startsWith = function(str) {
      return this.indexOf(str) === 0;
    };
  }

  inWhiteList = function(elem, whitelist) {
    var i, j, ref;
    for (i = j = 0, ref = whitelist.length - 1; j <= ref; i = j += 1) {
      if (whitelist[i] === elem) {
        return true;
      }
    }
    return false;
  };

  filterData = function(data, whitelistSites) {
    var entry, error, filteredData, hostname, i, j, passChecks, ref, url, urlObj;
    filteredData = [];
    for (i = j = 0, ref = data.length - 1; j <= ref; i = j += 1) {
      entry = data[i];
      url = hashedURLMap[entry["url"]];
      entry["actualURL"] = url;
      try {
        urlObj = new URL(url);
        hostname = urlObj.host;
        if (hostname && typeof hostname === "string") {
          if (hostname.startsWith("www.")) {
            hostname = hostname.substring(4);
          }
          passChecks = inWhiteList(hostname, whitelistSites) && urlObj.pathname !== "/";
          if (passChecks) {
            filteredData.push(entry);
          }
        }
      } catch (_error) {
        error = _error;
        console.log(error);
        console.log("could not parse the url " + url);
      }
    }
    return filteredData;
  };

  $.ajax("http://104.131.5.95:9292/suggested_sites/" + user_id).done(function(data) {
    return $.ajax("http://104.131.5.95:9292/whitelist_sites").done(function(siteData) {
      var daCollection, daViews, filteredData, parsedData, whitelistSites;
      $("#loader").hide();
      whitelistSites = JSON.parse(siteData);
      parsedData = JSON.parse(data);
      filteredData = filterData(parsedData, whitelistSites);
      daCollection = new Suggestions(filteredData);
      daViews = new SuggestionViews({
        collection: daCollection
      });
      return daViews.render();
    });
  });

}).call(this);
