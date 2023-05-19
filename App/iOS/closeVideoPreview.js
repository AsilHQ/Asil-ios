let isAccountPressed = false;
let isVideoClicked = false;
setTimeout(() => {
  const accountButton = document.querySelector(
    "div.setting-generic-category-title"
  );
  accountButton.click();
}, 1000);

new MutationObserver(() => {
  const videoPreview = document.querySelectorAll(
    "button.c3-material-toggle-button"
  )[1];
  if (videoPreview?.isConnected) {
    if (videoPreview?.getAttribute("aria-pressed")) {
      if (videoPreview?.getAttribute("aria-pressed") === "true") {
        if (!isVideoClicked) {
          isVideoClicked = true;
          console.log("LOLOL");
          videoPreview.click();
        } else {
          console.log("POLOA");
          if (!isAccountPressed) {
            isAccountPressed = true;
            window.webkit.messageHandlers.logHandler.postMessage("previewClosed");
          }
        }
      } else {
        if (!isAccountPressed) {
          isAccountPressed = true;
          window.webkit.messageHandlers.logHandler.postMessage("previewClosed");
        }
      }
    }
  }
}).observe(document, { subtree: true, childList: true });
