let isButtonClicked = false;
let isAccountClicked = false;
let isMethodCalled = false;

new MutationObserver(() => {
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
      window.webkit.messageHandlers.emailHandler.postMessage("returnValues");
      window.webkit.messageHandlers.emailHandler.postMessage(returnValues);
    }
  }
}).observe(document, { subtree: true, childList: true });
