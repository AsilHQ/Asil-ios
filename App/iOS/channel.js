if (!Array.prototype.last) {
  Array.prototype.last = function () {
    return this[this.length - 1];
  };
}

const restrictionImageUrl = "http://localhost:8080/assets/images/img_do_not_enter.jpeg";
const loadingImageUrl = "http://localhost:8080/assets/images/loading.gif";
const cautionImageUrl = "http://localhost:8080/assets/images/caution.png";
let isSubscriptionClicked = false;
let isElementClicked = false;
let channels = {};
let length = 0;

let allChannels =
  ytInitialData.contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents[0].itemSectionRenderer.contents.map(
    (e) => {
      return {
        id: e.channelListItemRenderer.channelId,
        name: e.channelListItemRenderer.title.runs[0].text,
        isUnsubscribed: false,
        thumbnail: `https:${e.channelListItemRenderer.thumbnail.thumbnails[0].url}`,
        isHaram: false,
      };
    }
  );
allChannels = allChannels ?? [];
function check_gender(response_gender, gender) {
  if (response_gender == 1) return true;
  if (response_gender == 4) return true; //Kids items are halal for both male and female.
  return response_gender == gender;
}

function check_mode(response_mode, mode) {
  switch (mode) {
    case 2:
      return true;
    case 3:
      return response_mode == 3 || response_mode == 1;
    case 1:
      return response_mode === 1;
    default:
      return false;
  }
}

function can_see(response) {
  return (
    check_gender(response.permissible_for.value, gender) &&
    check_mode(response.practicing_level.value, mode)
  );
}

function canSeee(responsee) {
  if (responsee["type"]) {
    return true;
  }
  return can_see(responsee);
}

(async () => {

  const channelIds = allChannels.map((e) => e.id);
  const res = await fetch(
    "https://api.kahf.ai/api/v1/channels?ids[]=" + channelIds.join("&ids[]="),

    {
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    }
  );

  const response = await res.json();
  // console.log("------LOL-------");
  // console.log(JSON.stringify(response));
  window.webkit.messageHandlers.logHandler.postMessage("hophop");
  for (const element of allChannels) {
    // console.log(href);
    window.webkit.messageHandlers.logHandler.postMessage(JSON.stringify(response));
    const fIndex = response.data?.findIndex((el) => element.id.includes(el.id));
    if (fIndex > -1) {
      if (response.data[fIndex] == 404) {
        element["isHaram"] = false;
      } else if (response.data[fIndex].is_halal) {
        if (canSeee(response)) {
          element["isHaram"] = false;
        } else {
          element["isHaram"] = true;
        }
      } else if (response.data[fIndex] == "loading") {
        element["isHaram"] = false;
      } else {
        element["isHaram"] = true;
      }
    }
  }
  window.webkit.messageHandlers.getChannelsHandler.postMessage(allChannels);
})();
