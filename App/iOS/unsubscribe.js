let isSubscriptionClicked = false;
let isBttonClicked = false;

let timer;
const valuesArray = Object.values(haramChannel);
new MutationObserver(async (mutationList, observer) => {
  if (valuesArray.length > 0) {
    const lastObject = valuesArray[valuesArray.length - 1];
    const lastObjectHref = lastObject.href
    window.webkit.messageHandlers.logHandler.postMessage(lastObjectHref);
    let foundChannel = document.querySelector(
      `a.compact-media-item-metadata-content[href="${lastObjectHref}"]`
    );
    foundChannel =
      foundChannel ??
      document.querySelector(
       `a.channel-list-item-link[href="${lastObjectHref}"]`
      );
    foundChannel?.click();
    const button = document
      .querySelector("ytm-subscribe-button-renderer")
      ?.querySelector("button");

    // const channelName = document.querySelector("h1.c4-tabbed-header-title");
    if (button?.classList?.contains("yt-spec-button-shape-next--tonal")) {
      if (!isBttonClicked) {
        window.webkit.messageHandlers.logHandler.postMessage("LOL");
        isBttonClicked = true;
        button?.click();
      }
    }
    
    if (
      isBttonClicked &&
      button?.classList?.contains("yt-spec-button-shape-next--filled")
    ) {
      window.webkit.messageHandlers.logHandler.postMessage("-------- DONE ---------");
      if (haramChannel[lastObject.href]["isUnsubscribed"] == false) {
        haramChannel[lastObject.href]["isUnsubscribed"] = true;
        isBttonClicked = false;
        valuesArray.pop();
        history.back();
      }
    }

    const unsubscribeButton = document
      .querySelector("div.dialog-buttons")
      ?.querySelectorAll("button")[1];
    if (unsubscribeButton && !haramChannel[lastObject.href]["isUnsubscribeClicked"]) {
      window.webkit.messageHandlers.logHandler.postMessage("GONE");
      unsubscribeButton.click();
      haramChannel[lastObject.href]["isUnsubscribeClicked"] = true;
    }
  } else {
    window.webkit.messageHandlers.logHandler.postMessage("-------- COMPLETED ---------");
    window.webkit.messageHandlers.getUnsubscribedChannelsHandler.postMessage(haramChannel);
  }
}).observe(document, {
  childList: true,
  subtree: true,
});
