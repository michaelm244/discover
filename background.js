var Timer =  {
  time: null,
  startTime: null,
  tempTime: null,
  interval: null,
  running: null,

  initialize: function() {
    this.time = 0;
    this.running = false;
    this.tempTime = 0;
  },

  increment: function() {
    this.time += 100;
    this.tempTime += 100;
    console.log("in increment");
    var diff = (new Date().getTime() - this.startTime) - this.tempTime;
    this.interval = window.setTimeout(this.increment.bind(this), (100 - diff));
  },

  start: function() {
    if(!this.running) {
      this.startTime = new Date().getTime();
      this.tempTime = 0;
      this.running = true;
      console.log("starting");
      this.interval = window.setTimeout(this.increment.bind(this), 100);
    }
  },

  getTime: function() {
    return this.time;
  },

  stop: function() {
    window.clearTimeout(this.interval);
    this.running = false;
  },

  clearTime: function() {
    this.time = 0;
  }
};

var Discover = {
  domainRegex: /^https?\:\/\/([^\/?#]+)(?:[\/?#]|$)/i,
  currentURL: null,
  currWidth: null,
  currHeight: null,
  focusedWindowId: null,
  checkDataSendInterval: 1000 * 60 * 5, // 5 minutes
  sendStatsInterval: 1000 * 60 * 60 * 24, // 24 hours
  serverIp: "104.131.5.95:9292",
  dataPath: "/data_post",

  randomChars: function()
  {
      var text = "";
      var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

      for( var i=0; i < 10; i++ )
          text += possible.charAt(Math.floor(Math.random() * possible.length));

      return text;
  },

  sendStats: function() {
    console.log("sending stats!!");
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      console.log("state changed. new ready state: " + xhr.readyState);
      if (xhr.readyState == 4) {
        console.log("ready state is 4, status is: " + xhr.status);
      }
    };
    var serverAddress = "http://" + this.serverIp + this.dataPath;
    xhr.open("POST", serverAddress, true);
    xhr.send(JSON.stringify(localStorage));
    var timeNow = Date.now();
    localStorage.timeDataSent = ""+timeNow;
  },

  checkToSendStats: function() {
    console.log("checking to send stats!");
    var timeNow = Date.now();
    var lastSaved = parseInt(localStorage.timeDataSent,10);
    var diff = timeNow - lastSaved;
    if (diff > this.sendStatsInterval) {
      this.sendStats();
    }
  },

  updateStats: function() {
    if(this.currentURL) {
      console.log("yo im in update stats here's the url: " + this.currentURL);

      Timer.stop();
      // calculate time difference from start time
      var timeSpent = Timer.getTime();
      var seconds = timeSpent / 1000;

      var that = this;

      var randomString = this.randomChars();

      if(this.currentURL.charAt(this.currentURL.length-1) != "/") {
        this.currentURL += "/";
      }

      var keyURL = this.currentURL + randomString;
      var visitObject = {
        time: seconds,
        width: that.currWidth,
        height: that.currHeight
      }
      var stringJSON = JSON.stringify(visitObject);
      localStorage[keyURL] = stringJSON;
    }

    Timer.clearTime();
    // update stuff for the new tab
    chrome.tabs.query({active: true, windowId: this.focusedWindowId},
    function(tabArr) {
      if(tabArr) {
        var currTab = tabArr[0];
        that.currentURL = that.prepareURL(currTab.url);
        that.currWidth = currTab.width;
        that.currHeight = currTab.height;
        console.log("updating current URL to: "+that.currentURL);
        Timer.start();
      }
    });

  },

  initialize: function() {
    console.log("initializing");

    var currVersion = chrome.app.getDetails().version;
    var prevVersion = localStorage['version'];
    if(currVersion != prevVersion) {
      localStorage.clear();
      localStorage['version']= currVersion;
    }

    if(!localStorage.user_id) {
      localStorage.user_id = Math.random().toString(36).substring(7);
    }

    if(!localStorage.timeDataSent) {
      var now = Date.now();
      localStorage.timeDataSent = ""+now;
    }

    Timer.initialize();

    var that = this;
    // setting up focused window id
    chrome.windows.getLastFocused(function(currWindow) {
      console.log("got last focused!");
      console.log(currWindow);
      that.focusedWindowId = currWindow.id;

      // finding the first selected tab and setting stuff up
      chrome.tabs.query({active: true, windowId: currWindow.id},
      function(tabArr) {
        if(tabArr) {
          var currTab = tabArr[0];
          that.currentURL = that.prepareURL(currTab.url);
          that.currWidth = currTab.width;
          that.currHeight = currTab.height;
          console.log("url from func: " + that.prepareURL(currTab.url));
          Timer.start();
        }
      });
    });

    chrome.tabs.onActivated.addListener(
    function(info) {
      console.log("activated tab changed!");
      console.log("windowId is "+info.windowId+" and focusedWindowId is "+that.focusedWindowId);
      if(info.windowId == that.focusedWindowId) {
        console.log("and it's the right window");
        // now let's end current tracking and switch
        that.updateStats();
      }
    });

    chrome.extension.onRequest.addListener(
    function(request, sender, sendResponse) {
      if (request.action == "sendStats") {
        this.sendStats();
      }
    });

    chrome.windows.onFocusChanged.addListener(
    function(windowId) {
      console.log("focused window changed!!");
      console.log("id: "+windowId);
      if(windowId != chrome.windows.WINDOW_ID_NONE) {
        Timer.start();
        that.focusedWindowId = windowId;
        chrome.tabs.query({active: true, windowId: that.focusedWindowId},
        function(tabArr) {
          if(tabArr) {
            // now we need to end the current tracking and
            // switch to a new one
            that.updateStats();
          }
        });
      }
      else {
        // we're in another window, so pause the timer
        Timer.stop();
      }
    });

    chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
      if(changeInfo.status == "complete" && tab.active) {
        console.log("active tab has been fully loaded, updating");
        that.updateStats();
      }
    });

    chrome.idle.queryState(60, this.checkIdleTime);
    chrome.idle.onStateChanged.addListener(this.checkIdleTime);

    // try to send stats every 5 minutes
    window.setInterval(this.checkToSendStats.bind(this), this.checkDataSendInterval);

  },

  checkIdleTime: function(newState) {
    if(newState == "idle" || newState == "locked") {
      Timer.pause();
    }
    else if(newState == "active") {
      Timer.start();
    }
  },

  prepareURL: function(url) {
    url = this.stripParameters(url);
    url = new URL(url);
    var afterProtocol = url.href.split(url.protocol + "//")[1];
    var afterSlashArr = afterProtocol.split("/");
    var hash = "/";
    if(afterSlashArr[1]) {
      hash += this.hashCode(afterSlashArr.slice(1).join('/'));
    }
    var finalURL = url.protocol + "//" + url.hostname + hash;
    return finalURL;
  },

  hashCode: function(str){
    var hash = 0;
    if (str.length == 0) return hash;
    for (i = 0; i < str.length; i++) {
      char = str.charCodeAt(i);
      hash = ((hash<<5)-hash)+char;
      hash = hash & hash;
    }
    return hash;
  },

  stripParameters: function(url) {
    return url.split("?")[0];
  }
};

// starting the app
setTimeout(function() {
  Discover.initialize();
}, 5000);