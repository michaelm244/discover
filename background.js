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
  focusedWindowId: null,
  checkDataSendInterval: 1000 * 60 * 5, // 5 minutes
  sendStatsInterval: 1000 * 60 * 60 * 24, // 24 hours
  serverIp: "104.131.5.95:9292",
  dataPath: "/data_post",

  handleXHRStateChange: function() {
    console.log("xhr state changed cuh");
  },

  sendStats: function() {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = this.handleXHRStateChange;
    xhr.open("POST", this.serverIp + this.dataPath, true);
    xhr.send(JSON.stringify(localStorage));
  },

  checkToSendStats: function() {
    var timeNow = Date.now();
    var lastSaved = parseInt(localStorage.timeDataSent,10);
    var diff = timeNow - lastSaved;
    if (diff > this.sendStatsInterval) {
      sendStats();
    }
  },

  updateStats: function() {
    if(this.currentURL) {
      console.log("yo im in update stats here's the domain: " + this.currentURL);

      Timer.stop();
      // calculate time difference from start time
      var timeSpent = Timer.getTime();
      var seconds = timeSpent / 1000;

      // get current site data from local storage or init it
      var currentSiteData;
      if(localStorage[this.currentURL]) {
        currentSiteData = JSON.parse(localStorage[this.currentURL]);
      }
      else {
        currentSiteData = {"visits":[]};
      }

      // insert this visit
      currentSiteData.visits.push(seconds);

      localStorage[this.currentURL] = JSON.stringify(currentSiteData);
    }

    Timer.clearTime();
    var that = this;
    // update stuff for the new tab
    chrome.tabs.query({active: true, windowId: this.focusedWindowId},
    function(tabArr) {
      if(tabArr) {
        var currTab = tabArr[0];
        that.currentURL = that.stripParameters(currTab.url);
        console.log("updating current URL to: "+that.currentURL);
        Timer.start();
      }
    });

  },

  initialize: function() {
    console.log("initializing");
    if(!localStorage.data) {
      localStorage.data = JSON.stringify({});
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
          that.currentURL = that.stripParameters(currTab.url);
          console.log("url from func: " + that.stripParameters(currTab.url));
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
      console.log("a tab has been updated!");
      if(changeInfo.status == "complete" && tab.active) {
        that.updateStats();
      }
    });

    chrome.idle.queryState(60, this.checkIdleTime);
    chrome.idle.onStateChanged.addListener(this.checkIdleTime);

    // try to send stats every 5 minutes
    window.setInterval(this.checkToSendStats, this.checkDataSendInterval);

  },

  checkIdleTime: function(newState) {
    if(newState == "idle" || newState == "locked") {
      Timer.pause();
    }
    else if(newState == "active") {
      Timer.start();
    }
  },

  // TODO
  domainIsIgnored: function(domain) {
    return false;
  },

  stripParameters: function(url) {
    return url.split("?")[0];
  }
};

// starting the app
setTimeout(function() {
  Discover.initialize();
}, 5000);