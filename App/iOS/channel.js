if (!Array.prototype.last) {
  Array.prototype.last = function () {
    return this[this.length - 1];
  };
}

const restrictionImageUrl =
  "http://localhost:8080/assets/images/img_do_not_enter.jpeg";
const loadingImageUrl = "http://localhost:8080/assets/images/loading.gif";
const cautionImageUrl = "http://localhost:8080/assets/images/caution.png";

let isSubscriptionClicked = false;
let isElementClicked = false;

let channels = {};
let length = 0;

async function canSeee(responsee) {
  const apiGender = responsee["permissible_for"];
  const apiMode = responsee["practicing_level"];
  // console.log(mode);
  // console.log(gender);
  if (apiGender["value"] == gender || apiGender["value"] == 1) {
    if (mode == 2) {
      return true;
    } else if (mode == 3) {
      return apiMode["value"] == 3 || apiMode["value"] == 1;
    } else if (mode == 1) {
      return apiMode["value"] == 1;
    }
  } else if (apiGender["value"] == -4 && gender != 4) {
    return true;
  }
  return false;
}

async function getParamsBasedOnResponse(response) {
          
  if (response == 404) {
    return {
      imageUrl: cautionImageUrl,
      action: "",
    };
  } else if (response?.is_halal) {
    if (await canSeee(response)) {
      return {
        action: "",
      };
    } else {
      return {
        imageUrl: "http://localhost:8080/assets/images/img_do_not_enter.jpeg",
        action: "none",
      };
    }
  } else if (response == "loading") {
    return {
      imageUrl: loadingImageUrl,
      action: "none",
    };
  } else {
    return {
      imageUrl: "http://localhost:8080/assets/images/img_do_not_enter.jpeg",
      action: "none",
    };
  }
}

new MutationObserver(async (mutationList, observer) => {
  const channelList = document.querySelectorAll("div.compact-media-item");
  if (channelList.length) {
    length = channelList.length;
    for (let index = 0; index < channelList.length; index++) {
      const element = channelList[index];
      const metadata = element.querySelector(
        "a.compact-media-item-metadata-content"
      );
      const href = metadata.getAttribute("href");
      if (!channels[href]) {
        channels[href] = {
          isUnsubscribed: false,
          thumbnail: `https:${element.querySelector("img")?.lazyData}`,
          name: metadata?.children?.item(0)?.textContent,
          subscribers: metadata?.children?.item(1)?.children?.item(0)
            ?.textContent,
          videos: metadata?.children?.item(1)?.children?.item(1)?.textContent,
          isHaram: false,
        };
      }
    }
    // console.log(JSON.stringify(channels));
  }

  const channelListOpt = document.querySelectorAll("a.channel-list-item-link");
  if (channelListOpt.length) {
    length = channelListOpt.length;
    for (let index = 0; index < channelListOpt.length; index++) {
      const element = channelListOpt[index];
      const href = element.getAttribute("href");
      if (!channels[href]) {
        channels[href] = {
          isUnsubscribed: false,
          thumbnail: `https:${element.querySelector("img")?.lazyData}`,
          name: element?.children?.item(1)?.textContent,
          isHaram: false,
        };
      }
    }
  }
}).observe(document, {
  childList: true,
  subtree: true,
});

setTimeout(() => {
  if (Object.keys(channels).length == 0) {
    window.webkit.messageHandlers.logHandler.postMessage("getChannels");
  }
}, 5000);

const id = setInterval(async () => {
 
  let channelsLength = Object.keys(channels).length;
  if (channelsLength != 0) {
    if (channelsLength == length) {
      clearInterval(id);
      const channelIds = Object.keys(channels).map((key) => {
        let id = key.split("/").last();
        if (id.startsWith("@")) {
          id = id.replace("@", "");
        }
        return id;
      });
      const res = await fetch(
        "https://api.kahf.ai/api/v1/channels?ids[]=" +
          channelIds.join("&ids[]="),

        {
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        }
      );

      const response = await res.json();
      for (const href of Object.keys(channels)) {
        const fIndex = response.data?.findIndex(
          (el) =>
            href.toLowerCase().includes(el.id) ||
            href.toLowerCase().includes(el["custom_url"]?.toLowerCase()) ||
            href.toLowerCase().includes(el["title"]?.toLowerCase())
        );
        if (fIndex > -1) {
        try {
          const { imageUrl } = await getParamsBasedOnResponse(response.data[fIndex]);
          channels[href]["isHaram"] = imageUrl == "http://localhost:8080/assets/images/img_do_not_enter.jpeg";
        } catch (error) {
          // Handle the error here
          const errorMessage = error.toString();
          window.webkit.messageHandlers.logHandler.postMessage(errorMessage);
        }
        }
      }
      window.webkit.messageHandlers.getChannelsHandler.postMessage(channels);
      // console.log(JSON.stringify(channels));
    }
  }
}, 1000);
