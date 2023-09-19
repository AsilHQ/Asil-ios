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

sendMessage("aaaaaaa");

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

async function canSeee(responsee) {
  const apiGender = responsee["permissible_for"];
  const apiMode = responsee["practicing_level"];
  // console.log(mode);
  // console.log(gender);
  if (responsee["type"]) {
    return true;
  }
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

const apiResponses = {};
const imageUrls = {};
const restrictionImageUrl =
  "Media/img_do_not_enter.jpeg";
const loadingImageUrl = "Media/loading.gif";
const cautionImageUrl = "Media/caution.png";


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
    console.log(ogImage);
    ogImage = ogImage ?? image?.lazyData?.sources[0];
    imageUrls[href] = ogImage?.url;
    updateApiResponse([href], updateView);
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
    updateApiResponse([href], updateView);
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
  const compactVideoList = document.querySelectorAll("div.compact-media-item");

  const updateView = () => {
    for (let index = 0; index < compactVideoList.length; index++) {
      updateCompactVideo(compactVideoList[index]);
    }
  };

  if (compactItemLength != compactVideoList.length) {
    // console.log(compactVideoList.length);
    compactItemLength = compactVideoList.length;
    const hrefs = [];
    for (let index = 0; index < compactVideoList.length; index++) {
      const thumbnail = compactVideoList[index]?.children?.item(0);
      const image = thumbnail.children?.item(0)?.children?.item(1);
      const href = thumbnail?.getAttribute("href");
      if (!apiResponses[href]) {
        hrefs.push(href);
        apiResponses[href] = "loading";
        let ogImage = image?.lazyData?.sources?.find((el) =>
          el["url"].includes("mqdefault")
        );
        ogImage = ogImage ?? image?.lazyData?.sources[0];
        imageUrls[href] = ogImage?.url;
      }
    }
    updateApiResponse(hrefs, updateView);
  } else {
    updateView();
  }
}

let mediaItemLength = 0;
function updateMediaItemList() {
  const videoList = document.getElementsByTagName("ytm-media-item");

  const updateView = () => {
    for (let index = 0; index < videoList.length; index++) {
      updateMediaItem(videoList[index]);
    }
  };

  if (mediaItemLength != videoList.length) {
    // console.log(videoList.length);
    mediaItemLength = videoList.length;
    const hrefs = [];
    for (let index = 0; index < videoList.length; index++) {
      const thumbnail = videoList[index]?.children?.item(0);
      const href = thumbnail?.getAttribute("href");
      const image = thumbnail?.children?.item(0)?.children?.item(1);
      if (!apiResponses[href]) {
        hrefs.push(href);
        apiResponses[href] = "loading";
        let ogImage = image?.lazyData?.sources.find((el) =>
          el["url"].includes("sddefault")
        );
        ogImage = ogImage ?? image?.lazyData?.sources[0];
        imageUrls[href] = ogImage?.url;
      }
    }
    updateApiResponse(hrefs, updateView);
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
      updateCautionView(imageUrl, image, thumbnail);
      if (cautionImageUrl) {
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
    // Check if the caution element is already present in the thumbnailElement
    const cautionElement = thumbnailElement.querySelector(".caution-element");
    if (!cautionElement ) {
      thumbnailElement.children
        .item(0)
        .append(
          isLargeView
            ? createLargeCautionElement()
            : createCompactCautionElement()
        );
    }
  }
}

function createCompactCautionElement() {
  const div1 = document.createElement("div");
  div1.classList.add("caution-element");
  div1.style.position = "absolute";
  div1.style.display = "flex";
  div1.style.width = "100%";
  div1.style.alignItems = "center";
  div1.style.justifyContent = "center";
  div1.style.bottom = "15%";
  div1.style.flexDirection = "column";
  const div2 = document.createElement("div");
  div2.style.background = "#FFFFFF";
  div2.style.boxShadow = "0px 4px 12px rgba(53, 53, 55, 0.82)";
  div2.style.borderRadius = "5px";
  const p = document.createElement("p");
  p.style.fontFamily = "Roboto";
  p.style.fontStyle = "normal";
  p.style.fontWeight = 500;
  p.style.fontSize = "0.9rem";
  p.style.lineHeight = "1rem";
  p.style.color = "#383838";
  p.style.margin = "0.5rem";
  p.textContent = "See Video (Not Recommended)";
  div2.append(p);
  div1.append(div2);
  const p1 = document.createElement("p");
  p1.style.color = "#FFFFFF";
  p1.textContent =
    "This video is not avaialable on our database. Proceed with caution";
  p1.style.fontFamily = "Roboto";
  p1.style.fontStyle = "normal";
  p1.style.fontWeight = 400;
  p1.style.fontSize = "0.8rem";
  p1.style.textAlign = "center";
  p1.style.lineHeight = "1rem";
  div1.append(p1);
  return div1;
}

function createLargeCautionElement() {
  const div1 = document.createElement("div");
  div1.classList.add("caution-element");
  div1.style.position = "absolute";
  div1.style.display = "flex";
  div1.style.width = "100%";
  div1.style.alignItems = "center";
  div1.style.justifyContent = "center";
  div1.style.bottom = "31%";
  div1.style.flexDirection = "column";
  const div2 = document.createElement("div");
  div2.style.background = "#FFFFFF";
  div2.style.boxShadow = "0px 4px 12px rgba(53, 53, 55, 0.82)";
  div2.style.borderRadius = "5px";
  const p = document.createElement("p");
  p.style.fontFamily = "Roboto";
  p.style.fontStyle = "normal";
  p.style.fontWeight = 500;
  p.style.fontSize = "1.3";
  p.style.lineHeight = "1.5rem";
  p.style.color = "#383838";
  p.style.margin = "1.5rem";
  p.textContent = "See Video (Not Recommended)";
  div2.append(p);
  div1.append(div2);
  const p1 = document.createElement("p");
  p1.style.color = "#FFFFFF";
  p1.textContent =
    "This video is not avaialable on our database. Proceed with caution";
  p1.style.fontFamily = "Roboto";
  p1.style.fontStyle = "normal";
  p1.style.fontWeight = 400;
  p1.style.fontSize = "1.1rem";
  p1.style.textAlign = "center";
  p1.style.lineHeight = "1.4rem";
  div1.append(p1);
  return div1;
}

function updateApiResponse(hrefs, callback) {
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
          const res = await fetch(
            `https://api.kahf.ai/api/v1/videos?ids[]=` + vIds.join("&ids[]="),
            {
              headers: {
                "Content-Type": "application/json",
                Accept: "application/json",
                Authorization: `Bearer ${token}`,
              },
            }
          );
          const response = await res.json();
          console.log(JSON.stringify(response));
          const recommendVideoLength = response?.recommend?.length;
          let recommendIndex = 0;
          const relatedVideoLength = response?.related?.length;
          let relatedIndex = 0;
          for (const href of hrefs) {
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
                  console.log(JSON.stringify(apiResponses[href]));

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
                apiResponses[href] = 404;
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
                }
              }
            }
          }

          callback();
        } catch (error) {
          // console.log(error);
        }
      });
    }

    if (cIds.length > 0) {
      console.log(cIds);
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
          console.log(JSON.stringify(response));
          hrefs.forEach((href) => {
            console.log(href);
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
              console.log("LOL");
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

  const url = location.href;
  if (!url.includes("google")) {
    forceSignin();
  } else {
    if (!email) {
      if (url == "https://m.youtube.com/") {
        document.location.reload();
      }
      document.location.href = "https://m.youtube.com";
    }
  }
}).observe(document, { subtree: true, childList: true });

const forceSignin = async () => {
  const button = document
    .querySelector("ytm-topbar-menu-button-renderer")
    .children.item(0);

  window.flutter_inappwebview.callHandler(
    "shouldRestart",
    button?.children?.item(0)?.children?.item(0)?.nodeName
  );
};
