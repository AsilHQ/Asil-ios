function sendMessage(message) {
    console.log(message);
    try {
        window.__firefox__.execute(function($) {
            let postMessage = $(function(message) {
                $.postNativeMessage('$<message_handler>', {
                    "securityToken": SECURITY_TOKEN,
                    "state": message
                });
            });

            postMessage(message);
        });
    }
    catch {}
}

class YoutubeFiltrationQueue {
  constructor() {
    this.elements = {};
    this.head = 0;
    this.tail = 0;
  }
  enqueue(element) {
    this.elements[this.tail] = element;
    this.tail++;
  }
  dequeue() {
    const item = this.elements[this.head];
    delete this.elements[this.head];
    this.head++;
    return item;
  }
  peek() {
    return this.elements[this.head];
  }
  get length() {
    return this.tail - this.head;
  }
  get isEmpty() {
    return this.length === 0;
  }
}

const apiQueue = new YoutubeFiltrationQueue();
let mode;
let gender;
let metaData;

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
  sendMessage("can_see")
  return (
    check_gender(response.permissible_for.value, gender) &&
    check_mode(response.practicing_level.value, mode)
  );
}

async function canSeee(responsee) {
  if (responsee["type"]) {
    return true;
  }
  return can_see(responsee);
}

let timerId;
let apiRequestCount = 0;
let email;
let token;

const throttle = () => {
  if (!timerId) {
    apiQueue.peek()();
    apiQueue.dequeue();
    timerId = setTimeout(() => {
      apiRequestCount = 0;
      clearTimeout(timerId);
      timerId = null;
    }, 500);
  }
};

setInterval(() => {
  if (!apiQueue.isEmpty) {
    throttle();
  }
}, 0);

window.apiResponses = {};
window.globalCallbackFunction = function(newHref, metadata, object) {
    window.apiResponses[newHref] = {
        ...object,
        type: "recommended",
        metaData: metadata,
    };
    for (let index = 0; index < videoList.length; index++) {
      const thumbnail = videoList[index].children?.item(0);
      const href = thumbnail?.getAttribute("href");
      if (href === newHref) {
        updateMediaItem(videoList[index]);
        break;
      }
    }
};
window.videoList = {};
const imageUrls = {};
const restrictionImageUrl = "http://localhost:8080/assets/images/img_do_not_enter.jpeg";
const loadingImageUrl = "http://localhost:8080/assets/images/loading.gif";
const cautionImageUrl = "http://localhost:8080/assets/images/caution.png";


setInterval(() => {
  if (document.getElementsByClassName("ytp-ad-text").length > 0) {
    const video = document.getElementsByClassName(
      "video-stream html5-main-video"
    )[0];
    video.play();
    video.pause();
    video.currentTime = video.duration;
  }
}, 200);

function updateElementsWhenNecessary(
  imageElement,
  imageUrl,
  elementsToBeActionable = [],
  action
) {
  if (imageElement?.getAttribute("src") == imageUrl) {
    return;
  }
  elementsToBeActionable.forEach((element) => {
    element.style.pointerEvents = action;
  });
  imageElement?.removeAttribute("src");
  imageElement?.setAttribute("src", imageUrl);
}

async function getParamsBasedOnResponse(response) {
  if (response == 404) {
    return {
      imageUrl: cautionImageUrl,
      action: "",
    };
  } else if (response?.is_halal || response?.type) {
    if (await canSeee(response)) {
      return {
        action: "",
      };
    } else {
      return {
        imageUrl: restrictionImageUrl,
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
      imageUrl: restrictionImageUrl,
      action: "none",
    };
  }
}

function updateFeaturedVideo() {
  const element = document.querySelector("ytm-channel-featured-video-renderer");
  const a = element?.children?.item(0);
  const image = a?.children?.item(0)?.children?.item(1);
  const href = a?.getAttribute("href");
  const updateView = async () => {
    const response = apiResponses[href];
    const { imageUrl, action } = await getParamsBasedOnResponse(response);
    if (imageUrl) {
      if (imageUrl == restrictionImageUrl) {
        element?.remove();
      } else {
        updateElementsWhenNecessary(
          image,
          imageUrl == cautionImageUrl ? imageUrls[href] : imageUrl,
          [a],
          action
        );
        updateCautionView(imageUrl, image, a);
      }
    } else {
      if (a.style.pointerEvents == "none") {
        a.style.pointerEvents = "";
        image?.removeAttribute("src");
        image?.setAttribute("src", imageUrls[href]);
      }
      if (response.type) {
        if (image.getAttribute("src") != response.metaData.thumbnail) {
          image?.removeAttribute("src");
          image?.setAttribute("src", response.metaData.thumbnail);
        }
        if (a.href !== response.url) {
          apiResponses[response.url] = response;
          a.href = response.url;
        }
        const title = a.querySelector("h3.details");
        if (title && title.children.item(0).textContent !== response.title) {
          title.textContent = response.title;
        }
      }
    }
  };

  if (href && !apiResponses[href]) {
    apiResponses[href] = "loading";
    let ogImage = image?.lazyData?.sources?.find((el) =>
      el["url"].includes("mqdefault")
    );
    sendMessage(ogImage);
    sendMessage("ogImage");
    ogImage = ogImage ?? image?.lazyData?.sources[0];
    imageUrls[href] = ogImage?.url;
    const cUrl = document.querySelector("ytm-c4-tabbed-header-renderer")?.data?.channelId;
    updateApiResponse([href], [cUrl], updateView);
  } else {
    updateView();
  }
}

function updateCardVideo() {
  const cardVideo = document.querySelector("a.watch-card-hero-video-endpoint");
  const href = cardVideo?.getAttribute("href");
  const image = cardVideo?.children?.item(0)?.children?.item(0);
  const updateView = async () => {
    const response = apiResponses[href];
    const { imageUrl, action } = await getParamsBasedOnResponse(response);
    if (imageUrl) {
      if (imageUrl == restrictionImageUrl) {
        cardVideo?.parentElement?.parentElement?.remove();
      } else {
        updateElementsWhenNecessary(
          image,
          imageUrl == cautionImageUrl ? imageUrls[href] : imageUrl,
          [cardVideo],
          action
        );
        updateCautionView(imageUrl, image, cardVideo);
      }
    } else {
      if (cardVideo.style.pointerEvents == "none") {
        cardVideo.style.pointerEvents = "";
        image?.removeAttribute("src");
        image?.setAttribute("src", imageUrls[href]);
      }
      if (response.type) {
        if (image.getAttribute("src") != response.metaData.thumbnail) {
          image?.removeAttribute("src");
          image?.setAttribute("src", response.metaData.thumbnail);
        }
        if (cardVideo.href !== response.url) {
          apiResponses[response.url] = response;
          cardVideo.href = response.url;
        }
        const title = cardVideo.querySelector(
          "h2.watch-card-single-hero-title"
        );
        if (title && title.children.item(0).textContent !== response.title) {
          title.textContent = response.title;
        }
        const sub = cardVideo?.children?.item(1)?.children?.item(1);
        const textContent = `${response.channel.title} • ${response.metaData.views} • ${response.published_at}`;
        if (sub.textContent !== textContent) {
          sub.textContent = textContent;
        }
        const timeLine = cardVideo.querySelector(
          "span.yt-core-attributed-string"
        );
        if (timeLine.textContent !== response.metaData["timeline"]) {
          timeLine.textContent = response.metaData["timeline"];
        }
      }
    }
  };

  if (href && !apiResponses[href]) {
    apiResponses[href] = "loading";
    let ogImage = image?.lazyData?.sources?.find((el) =>
      el["url"].includes("mqdefault")
    );
    ogImage = ogImage ?? image?.lazyData?.sources[0];
    imageUrls[href] = ogImage?.url;
    const cUrl = cardVideo?.baseURI.split("/");
    updateApiResponse(
        [href],
        [cUrl.find((el) => el.startsWith("@"))],
        updateView
    );
  } else {
    updateView();
  }
}

async function updateCompactVideo(node) {
  const thumbnail = node?.children?.item(0);
  const image = thumbnail.children?.item(0)?.children?.item(1);
  const details = node?.children?.item(1)?.children?.item(0);
  const href = thumbnail?.getAttribute("href");
  const response = apiResponses[href];
  const { imageUrl, action } = await getParamsBasedOnResponse(response);
  // console.log(href, " ------ ", imageUrl);
  if (imageUrl) {
    if (imageUrl == restrictionImageUrl) {
      node.parentElement?.remove();
    } else {
      updateElementsWhenNecessary(
        image,
        imageUrl == cautionImageUrl ? imageUrls[href] : imageUrl,
        [thumbnail, details],
        action
      );
      updateCautionView(imageUrl, image, thumbnail, false);
    }
  } else {
    if (thumbnail.style.pointerEvents == "none") {
      thumbnail.style.pointerEvents = "";
      details.style.pointerEvents = "";
      image?.removeAttribute("src");
      image?.setAttribute("src", imageUrls[href]);
    }
    if (response.type) {
      if (image.getAttribute("src") != response.metaData.thumbnail) {
        image?.removeAttribute("src");
        image?.setAttribute("src", response.metaData.thumbnail);
      }
      if (thumbnail.href !== response.url) {
        apiResponses[response.url] = response;
        thumbnail.href = response.url;
      }
      if (details.href !== response.url) {
        details.href = response.url;
      }
      const title = details.querySelector("h4.compact-media-item-headline");
      if (title && title.children.item(0).textContent !== response.title) {
        title.textContent = response.title;
      }
      const sub = details?.children?.item(1);
      const textContent = `${response.channel.title} • ${response.metaData.views} • ${response.published_at}`;
      if (sub.textContent !== textContent) {
        sub.textContent = textContent;
      }
      const timeLine = node.querySelector("span.yt-core-attributed-string");
      if (timeLine.textContent !== response.metaData["timeline"]) {
        timeLine.textContent = response.metaData["timeline"];
      }
    }
  }
}

let compactItemLength = 0;
function updateCompactVideoList() {
  let compactVideoList = document.querySelectorAll("div.compact-media-item");
  if (!compactVideoList.length) {
    compactVideoList = document.querySelectorAll("ytm-video-card-renderer.horizontal-card-list-card");
  }

  const updateView = () => {
    for (let index = 0; index < compactVideoList.length; index++) {
      updateCompactVideo(compactVideoList[index]);
    }
  };

  if (compactItemLength != compactVideoList.length) {
    // console.log(compactVideoList.length);
    compactItemLength = compactVideoList.length;
    const hrefs = [];
    const chrefs = [];
    for (let index = 0; index < compactVideoList.length; index++) {
      const thumbnail = compactVideoList[index]?.children?.item(0);
      const image = thumbnail.children?.item(0)?.children?.item(1);
      const href = thumbnail?.getAttribute("href");
      if (!apiResponses[href]) {
        hrefs.push(href);
        const cUrl = document.querySelector("ytm-c4-tabbed-header-renderer")?.data?.channelId;
        chrefs.push(cUrl);
        apiResponses[href] = "loading";
        let ogImage = image?.lazyData?.sources?.find((el) =>
          el["url"].includes("mqdefault")
        );
        ogImage = ogImage ?? image?.lazyData?.sources[0];
        imageUrls[href] = ogImage?.url;
      }
    }
    updateApiResponse(hrefs, chrefs, updateView);
  } else {
    updateView();
  }
}

let mediaItemLength = 0;
function updateMediaItemList() {
  videoList = document.getElementsByTagName("ytm-media-item");

  const updateView = () => {
    for (let index = 0; index < videoList.length; index++) {
      updateMediaItem(videoList[index]);
    }
  };

  if (mediaItemLength != videoList.length) {
    // console.log(videoList.length);
    mediaItemLength = videoList.length;
    const hrefs = [];
    const chrefs = [];
    for (let index = 0; index < videoList.length; index++) {
      const thumbnail = videoList[index]?.children?.item(0);
      const href = thumbnail?.getAttribute("href");
      const image = thumbnail?.children?.item(0)?.children?.item(1);
      const channelInfo = videoList[index]?.children ?.item(videoList[index].children.length - 1)?.children?.item(0);
      if (!apiResponses[href]) {
        hrefs.push(href);
        const channelLink = channelInfo?.children?.item(0)?.children?.item(0)?._data?.browseEndpoint?.browseId;
        chrefs.push(channelLink);
        apiResponses[href] = "loading";
        let ogImage = image?.lazyData?.sources.find((el) =>
          el["url"].includes("sddefault")
        );
        ogImage = ogImage ?? image?.lazyData?.sources[0];
        imageUrls[href] = ogImage?.url;
      }
    }
    updateApiResponse(hrefs, chrefs, updateView);
  } else {
    updateView();
  }
}

async function updateMediaItem(node) {
  const thumbnail = node?.children?.item(0);
  const image = thumbnail?.children?.item(0)?.children?.item(1);
  const details = node?.children
    ?.item(node.children.length - 1)
    ?.children?.item(1)
    ?.children?.item(0)
    ?.children?.item(0);
  const href = thumbnail?.getAttribute("href");

  const response = apiResponses[href];
  const { imageUrl, action } = await getParamsBasedOnResponse(response);
  if (imageUrl) {
    if (imageUrl == restrictionImageUrl) {
      node?.remove();
    } else {
      updateElementsWhenNecessary(
        image,
        imageUrl == cautionImageUrl ? imageUrls[href] : imageUrl,
        [thumbnail, details],
        action
      );
      updateLoadingView(imageUrl, thumbnail);
      updateCautionView(imageUrl, image, thumbnail);
     if (imageUrl == cautionImageUrl) {
        const channelThumb = node
          .querySelector("ytm-profile-icon.channel-thumbnail-icon")
          ?.children?.item(0);
        if (channelThumb.style.filter != "blur(1.1rem)") {
          channelThumb.style.filter = "blur(1.1rem)";
        }
      }
    }
  } else {
    if (thumbnail.style.pointerEvents == "none") {
      thumbnail.style.pointerEvents = action;
      details.style.pointerEvents = action;
      image?.removeAttribute("src");
      image?.setAttribute("src", imageUrls[href]);
    }
    if (response.type) {
      if (image.getAttribute("src") != response.metaData.thumbnail) {
        image?.removeAttribute("src");
        image?.setAttribute("src", response.metaData.thumbnail);
        updateLoadingView(imageUrl, thumbnail);
      }
      if (thumbnail.href !== response.url) {
        apiResponses[response.url] = response;
        thumbnail.href = response.url;
      }
      if (details.href !== response.url) {
        details.href = response.url;
      }
      const title = details.querySelector("h3.media-item-headline");
      if (title && title.children.item(0).textContent !== response.title) {
        title.textContent = response.title;
      }
      const channelInfo = node?.children
        ?.item(node.children.length - 1)
        ?.children?.item(0);
      const channelLink = channelInfo?.children?.item(0)?.children?.item(0);
      if (channelLink.href != response.channel.url) {
        channelLink.href = response.channel.url;
      }
      const channelThumb = node.querySelector(
        "ytm-profile-icon.channel-thumbnail-icon"
      );
      if (channelThumb.children.length == 1) {
        const innerHtml = `<img src="${response.channel.thumbnails.default.url}">`;
        if (channelThumb.innerHTML != innerHtml) {
          channelThumb.innerHTML = innerHtml;
        }
      }
      const hiddenVideoLink = channelInfo?.children?.item(1);
      if (hiddenVideoLink.href !== response.url) {
        hiddenVideoLink.href = response.url;
      }
      const sub = details?.children?.item(1);
      const textContent = `${response.channel.title} • ${response.metaData.views} • ${response.published_at}`;
      if (sub.textContent !== textContent) {
        sub.textContent = textContent;
      }
      const timeLine = node.querySelector("span.yt-core-attributed-string");
      if (timeLine.textContent !== response.metaData["timeline"]) {
        timeLine.textContent = response.metaData["timeline"];
      }
    }
  }
}

function show_loading_indicator() {
    const div1 = document.createElement("div");
    div1.classList.add("kahf-tube-loading-indicator");
    div1.innerHTML = `
       <div class="kahf-tube-loader">
         <div class="bar1"></div>
         <div class="bar2"></div>
         <div class="bar3"></div>
         <div class="bar4"></div>
         <div class="bar5"></div>
         <div class="bar6"></div>
       </div> `
    return div1;
}

function updateCautionView(
  imageUrl,
  imageElement,
  thumbnailElement,
  isLargeView = true
) {
  if (imageUrl == cautionImageUrl) {
    if (imageElement.style.filter != "blur(1.1rem)") {
      imageElement.style.filter = "blur(1.1rem)";
    }
    if (thumbnailElement.children.item(0).children.length <= 4) {
      thumbnailElement.children
        .item(0)
        .append(
          isLargeView
            ? createCautionElement("large")
            : createCautionElement("compact")
        );
    }
  }
}

function updateLoadingView(
  imageUrl,
  thumbnailElement
) {
  if (imageUrl == loadingImageUrl) {
    if (thumbnailElement.children.item(0).children.length <= 4) {
      thumbnailElement.children
        .item(0)
        .append(show_loading_indicator());
    }
  }
  else {
      const cautionElement = thumbnailElement.querySelector(".kahf-tube-loading-indicator");
      if (cautionElement) {
          cautionElement.remove();
      }
  }
}

function createCautionElement(options) {
  const container = document.createElement("div");
  container.classList.add("caution-container");
  options === "large" ?  container.classList.add("large-container") : container.classList.add("compact-container");
  const box = document.createElement("div");
  box.classList.add("caution-box");
  const title = document.createElement("p");
  options === "large" ?  title.classList.add("large-title") : title.classList.add("compact-title");
  title.textContent = "See Video (Not Recommended)";
  box.append(title);
  container.append(box);
  const message = document.createElement("p");
  message.classList.add("caution-message");
  options === "large" ?  message.classList.add("aution-message-large-caution") : message.classList.add("caution-message-compact-caution");
  message.textContent = "This video is not available on our database. Proceed with caution";
  container.append(message);
  return container;
}


function updateApiResponse(hrefs, chrefs, callback) {
  if (hrefs) {
    const re = new RegExp(
      ".*(?:(?:youtu.be/|v/|vi/|u/w/|embed/)|(?:(?:watch)??v(?:i)?=|&v(?:i)?=))([^#&?]*).*"
    );
    const cIds = [];
    const pIds = [];
    const vIds = hrefs
      .map((href) => {
        let vId = re.exec(href);
        if (href.includes("shorts")) {
          vId = href.split("/");
          vId.shift();
        } else if (href.includes("/playlist")) {
          let pId = href.split("=");
          pId.shift();
          pId = pId[pId.length - 1];
          pIds.push(pId);
        } else if (
          href.includes("/c") ||
          href.includes("/@") ||
          href.includes("/channel") ||
          href.includes("/user")
        ) {
          let cId = href.split("/");
          cId.shift();
          cId = cId[cId.length - 1];
          if (cId.startsWith("@")) {
            cId = cId.replace("@", "");
          }
          cIds.push(cId);
        }
        if (vId?.length > 0) {
          return vId[1];
        }
        return "";
      })
      .filter((el) => el != "");

    if (vIds.length > 0) {
      apiQueue.enqueue(async () => {
        try {
          let ids = "";
          for (let index = 0; index < vIds.length; index++) {
            const element = vIds[index];
            ids = ids + element + ":";
            if (chrefs[index]) {
              ids = ids + chrefs[index];
            }
            if (index != vIds.length - 1) {
              ids = ids + "&ids[]=";
            }
          }
          let url =
            `https://api.kahf.ai/api/v1/videos?ids[]=` +
            ids +
            `&premissible-for=${gender}&practicing-level=${mode}&_country=${yt.config_.GL}`;
          if (gender == 4) {
            let cursor = metaData?.next_cursor ?? "";
            url = `https://api.kahf.ai/api/v1/videos/recommends?permissible-for=${gender}&limit=${vIds.length}&cursor=${cursor}&_country=${yt.config_.GL}`;
          }
          const res = await fetch(url, {
            headers: {
              "Content-Type": "application/json",
              Accept: "application/json",
              Authorization: `Bearer ${token}`,
            },
          });
          const response = await res.json();
          let recommendVideoLength = response?.recommend?.length;
          if (gender == 4) {
            metaData = response?.meta;
          }
          let recommendIndex = 0;
          let relatedVideoLength = response?.related?.length;
          let relatedIndex = 0;
          for (const href of hrefs) {
            if (gender == 4) {
              sendMessage("fetchYtInitialData/-/" + response?.data[recommendIndex].id + "/-/" + href + "/-/ " + JSON.stringify(response?.data[recommendIndex]));
              recommendIndex = recommendIndex + 1;
            } else {
              const fIndex = response?.data?.findIndex((el) =>
                href.includes(el.id)
              );
              if (fIndex !== undefined && fIndex != -1) {
                if (!response?.data[fIndex]?.is_halal) {
                  if (
                    relatedVideoLength > 0 &&
                    relatedIndex < relatedVideoLength
                  ) {
                    const res = await window.flutter_inappwebview.callHandler(
                      "fetchYtInitialData",
                      response?.related[relatedIndex].id
                    );
                    apiResponses[href] = {
                      ...response?.related[relatedIndex],
                      type: "related",
                      metaData: res,
                    };
                    // console.log(JSON.stringify(apiResponses[href]));

                    relatedIndex = relatedIndex + 1;
                  } else {
                    apiResponses[href] = response?.data[fIndex];
                  }
                } else {
                  apiResponses[href] = response?.data[fIndex];
                }
              } else {
                const cIndex = cIds.findIndex((el) => href.includes(el));
                if (cIndex !== undefined && cIndex != -1) {
                } else {
                  // console.log(href + "----" + 404);

                  if (
                    recommendVideoLength > 0 &&
                    recommendIndex < recommendVideoLength
                  ) {
                    const res = await window.flutter_inappwebview.callHandler(
                      "fetchYtInitialData",
                      response?.recommend[recommendIndex].id
                    );
                    apiResponses[href] = {
                      ...response?.recommend[recommendIndex],
                      type: "recommended",
                      metaData: res,
                    };
                    recommendIndex = recommendIndex + 1;
                  } else {
                    apiResponses[href] = 404;
                  }
                }
              }
            }
          }
        } catch (error) {
          // console.log(error);
        }
      });
    }

    if (cIds.length > 0) {
      // console.log(cIds);
      apiQueue.enqueue(async () => {
        try {
          const res = await fetch(
            `https://api.kahf.ai/api/v1/channels?ids[]=` + cIds.join("&ids[]="),
            {
              headers: {
                "Content-Type": "application/json",
                Accept: "application/json",
                Authorization: `Bearer ${token}`,
              },
            }
          );
          const response = await res.json();
          hrefs.forEach((href) => {
            const fIndex = response?.data?.findIndex(
              (el) =>
                href.toLowerCase().includes(el.id) ||
                href.toLowerCase().includes(el["custom_url"].toLowerCase()) ||
                href.toLowerCase().includes(el["title"].toLowerCase())
            );
            if (fIndex !== undefined && fIndex != -1) {
              apiResponses[href] = response?.data[fIndex];
            }
          });

          hrefs.forEach((href) => {
            const fIndex = cIds.findIndex((el) => href.includes(el));
            if (
              fIndex !== undefined &&
              fIndex != -1 &&
              apiResponses[href] == "loading"
            ) {
              apiResponses[href] = 404;
            }
          });

          callback();
        } catch (error) {
          // console.log(error);
        }
      });
    }
  }
}

let isShareClicked = false;

new MutationObserver(() => {
  const homeIcon = document.querySelector("#home-icon");
  const svg = homeIcon.querySelector("svg")?.children?.item(0);
  if (svg?.getAttribute("fill") == "#ff0000" || "undefined") {
    svg?.setAttribute("fill", "#34A853");
  }

  if (
    document.querySelector("div.mobile-topbar-header-content").children.item(0)
      .textContent == "Open App"
  ) {
    document
      .querySelector("div.mobile-topbar-header-content")
      .children.item(0)
      .remove();
  }
  const tab = document.getElementsByTagName("ytm-pivot-bar-item-renderer");
  for (let index = 0; index < tab.length; index++) {
    const element = tab[index];
    if (element?.innerText.includes("Shorts")) {
      element?.remove();

    }
  }

  const channelTabs = document.querySelectorAll("a.scbrr-tab");
  for (let index = 0; index < channelTabs.length; index++) {
    const element = channelTabs[index];
    if (element.textContent == "Shorts") {
      element?.remove();
    }
  }

  const shareButton = document.querySelectorAll(
    "button.yt-spec-button-shape-next--tonal.yt-spec-button-shape-next--icon-leading"
  )[1];

  if (shareButton.isConnected && !isShareClicked) {
    isShareClicked = true;
    shareButton.addEventListener("click", async () => {
      let shared = await window.flutter_inappwebview.callHandler(
        "share",
        location.href
      );

      if (shared) {
        document.querySelector("c3-overlay").click();
      }
    });
  } else {
    isShareClicked = false;
  }
}).observe(document, { subtree: true, childList: true });
