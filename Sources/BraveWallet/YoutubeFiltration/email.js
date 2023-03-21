window.webkit.messageHandlers.emailHandler.postMessage("AAAcemcmemcr");
let isButtonClicked = false;
let isAccountClicked = false;
let isMethodCalled = false;
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
            document.querySelector("button.mobile-topbar-back-arrow")?.click();
          }
        }
      } else {
        console.log("POLOA2");
        if (!isAccountPressed) {
          isAccountPressed = true;
          document.querySelector("button.mobile-topbar-back-arrow")?.click();
        }
      }
    }
  }
  const button = document
    .querySelector("ytm-topbar-menu-button-renderer")
    .children.item(0);
    
  if (!isButtonClicked && button.isConnected) {
    isButtonClicked = true;
    button.click();
  }

  const image = document
    .querySelector("ytm-topbar-menu-button-renderer")
    ?.querySelector("ytm-profile-icon")
    ?.querySelector("img");

  if (image) {
    const account = document.querySelector("div.active-account-name");

    if (!isAccountClicked && account?.isConnected) {
      isAccountClicked = true;
      account.click();
    }
    const holder = document.querySelector("div.google-account-header-renderer");

    if (holder?.isConnected) {
      const email = holder.children.item(1).textContent;
      const name = holder.children.item(0).textContent;
      const imgSrc = image.getAttribute("src");
      if (!isMethodCalled) {
        isMethodCalled = true;
        const returnValues = { email, imgSrc, name };
        window.webkit.messageHandlers.emailHandler.postMessage("returnValues");
        window.webkit.messageHandlers.emailHandler.postMessage(returnValues);
      }
    }
  } else if (isButtonClicked) {
    if (!isMethodCalled) {
      isMethodCalled = true;
      const email = holder.children.item(1).textContent;
      const returnValues = { email };
      window.webkit.messageHandlers.emailHandler.postMessage(returnValues);
    }
  }
}).observe(document, { subtree: true, childList: true });
