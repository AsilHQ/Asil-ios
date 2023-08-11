async function sha1(str) {
  const buffer = new TextEncoder().encode(str);
  return crypto.subtle.digest("SHA-1", buffer).then((hash) => {
    return Array.from(new Uint8Array(hash))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  });
}

function getCookieValue(cookieName) {
    var cookies = document.cookie.split(';');
    
    for (var i = 0; i < cookies.length; i++) {
        var cookie = cookies[i].trim();
        
        if (cookie.indexOf(cookieName + '=') === 0) {
            return cookie.substring(cookieName.length + 1);
        }
    }
    
    return "";
}

/*async function get_sapisid() {
  const cookie = await window.flutter_inappwebview.callHandler("getCookie");
  return cookie || "";
}*/

async function generate_authorization_key() {
  var sapisid = getCookieValue('SAPISID');
  const date = Math.floor(new Date().getTime() / 1e3);
  const key = await sha1(`${date} ${sapisid} https://www.youtube.com`);
  return `SAPISIDHASH ${date}_${key}`;
}

async function unsubscribe_channel() {
  const authorization = await generate_authorization_key();
  const innertubeapikey = ytcfg.d().INNERTUBE_API_KEY;
  const url = `https://www.youtube.com/youtubei/v1/subscription/unsubscribe?key=${innertubeapikey}&prettyPrint=false`;
  const body = {
      context: {
        client: {
          hl: "en",
          deviceMake: "",
          deviceModel: "",
          clientName: "WEB",
          clientVersion: "2.20230201.01.00",
          osName: "X11",
          osVersion: "",
          originalUrl: `https://www.youtube.com/channel/${channel_ids[0]}`,
          screenPixelDensity: 1,
          platform: "DESKTOP",
          clientFormFactor: "UNKNOWN_FORM_FACTOR",
          browserName: "Chrome",
          screenWidthPoints: window.innerWidth,
          screenHeightPoints: window.innerHeight,
          userInterfaceTheme: "USER_INTERFACE_THEME_LIGHT",
          connectionType: "CONN_CELLULAR_4G",
          mainAppWebInfo: {
            graftUrl: `https://www.youtube.com/channel/${channel_ids[0]}`,
            pwaInstallabilityStatus: "PWA_INSTALLABILITY_STATUS_CAN_BE_INSTALLED",
            webDisplayMode: "WEB_DISPLAY_MODE_BROWSER",
            isWebNativeShareAvailable: false,
          },
        },
        user: { lockedSafetyMode: false },
        request: {
          useSsl: true,
          internalExperimentFlags: [],
          consistencyTokenJars: [],
        },
      },
      channelIds: channel_ids,
    };
  const response = await fetch(url, {
    method: "POST",
    headers: {
      authorization,
      "Content-Type": "application/json",
      "x-origin": "https://www.youtube.com",
    },
    body: JSON.stringify(body),
  });
  window.webkit.messageHandlers.logHandler.postMessage(JSON.stringify(body));
  window.webkit.messageHandlers.logHandler.postMessage(JSON.stringify(navigator));
  const res = await response.json();
  window.webkit.messageHandlers.logHandler.postMessage(JSON.stringify(res));
  if (!response.ok) {
    window.webkit.messageHandlers.getUnsubscribedChannelsHandler.postMessage(haramChannel);
  }
  window.webkit.messageHandlers.getUnsubscribedChannelsHandler.postMessage(haramChannel);
}
unsubscribe_channel();
