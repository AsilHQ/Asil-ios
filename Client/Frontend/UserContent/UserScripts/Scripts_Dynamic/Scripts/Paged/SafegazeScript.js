// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

const onProcessImageMap = new Map();
var imageCount = 0;

window.safegazeOnDeviceModelHandler = safegazeOnDeviceModelHandler;
window.sendMessage = sendMessage;
window.updateBluredImageOpacity = updateBluredImageOpacity;

async function safegazeOnDeviceModelHandler(shouldBlur, index) {
    if (shouldBlur) {
        const imgElement = onProcessImageMap.get(index);
        onProcessImageMap.delete(index);
        imgElement.setAttribute('isSent', 'true');

        sendMessage("replaced"); // Update total blurred image count
    } else {
        let element = onProcessImageMap.get(index);
        onProcessImageMap.delete(index);
        unblurImage(element);
        element.removeAttribute('data-lazysrc');
        element.removeAttribute('srcset');
        element.removeAttribute('data-srcset');
        element.setAttribute('data-replaced', 'true');
    }
};

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

function removeSourceElementsInPictures() {
    const pictureElements = document.querySelectorAll('picture');

    pictureElements.forEach(picture => {
        const sourceElements = picture.querySelectorAll('source');
        sourceElements.forEach(source => {
            source.remove();
        });
    });
}

function blurImage(image) {
    image.style.filter = `blur(${window.blurIntensity * 10}px)`;
    image.setAttribute('isBlurred', 'true');
}

function unblurImageOnLoad(image) {
    image.onload = () => {
        image.style.filter = 'none';
    };
    image.setAttribute('isBlurred', 'false');
}

//Means that there is no object in image
function unblurImage(image) {
    image.style.filter = 'none';
    image.setAttribute('isBlurred', 'false');
}

function updateBluredImageOpacity() {
    const blurredElements = document.querySelectorAll('[isBlurred="true"]');
    blurredElements.forEach(element => {
        element.style.filter = `blur(${window.blurIntensity * 10}px)`;
    });
}

async function getImageElements() {
  const minImageSize = 45; // Minimum image size in pixels

  const hasMinRenderedSize = (element) => {
    const rect = element.getBoundingClientRect();
    return rect.width >= minImageSize && rect.height >= minImageSize;
  };

  // Scroll event listener
  const fetchNewImages = async () => {
     removeSourceElementsInPictures();
     const backgroundImages = Array.from(document.querySelectorAll(':not([isSent="true"]):not([data-replaced="true"]):not([alt="logo"]):not([src*="captcha"])')).filter(img => {
           const backgroundImage = img.style.backgroundImage;
           if (backgroundImage) {
               const backgroundImageUrl = backgroundImage.slice(5, -2);
               const hasBackgroundImage = backgroundImage.startsWith("url(");
               if (hasBackgroundImage && img.tagName !== "IMG" && !backgroundImageUrl.includes('.svg')) {
                  blurImage(img);
                  img.setAttribute('hasBackgroundImage', 'true');
                  img.setAttribute('isSent', 'true');
                  img.setAttribute('src', backgroundImageUrl);
                  return true;
               }
           }
           return false;
     });

     const imageElements = Array.from(document.querySelectorAll('img[src]:not([src*="logo"]):not([src*=".svg"]):not([src*="no-image"]):not([isSent="true"]):not([data-replaced="true"]):not([alt="logo"]):not([src*="captcha"])')).filter(img => {
        const src = img.getAttribute('src');
        const alt = img.getAttribute('alt');
        const id = img.getAttribute('id');
        if (img.parentElement.classList.contains('captcha') || (id && id.includes('captcha'))) {
            return false;
        }
        if (src && !src.startsWith('data:image/') && src.length > 0) {
            if (hasMinRenderedSize(img)) {
                blurImage(img);
                img.setAttribute('isSent', 'true');
                return true;
            }
            else {
                return false;
            }
        }
        else if (!src || src.length === 0) {
            if (img.getAttribute("xlink:href")) {
                img.setAttribute('src', img.getAttribute("xlink:href"));
                img.setAttribute('srcAttr', "xlink:href");
                blurImage(img);
                img.setAttribute('isSent', 'true');
                return true;
            }
        }
        blurImage(img);
        return false;
    });

    const lazyImageElements = Array.from(document.querySelectorAll('img[data-src]:not([data-src*="logo"]):not([data-src*=".svg"]):not([data-src*="no-image"]):not([isSent="true"]):not([data-replaced="true"]):not([alt="logo"]:not([data-src*="captcha"])')).filter(img => {
        const dataSrc = img.getAttribute('data-src');
        const alt = img.getAttribute('alt');
        const id = img.getAttribute('id');
        if (img.parentElement.classList.contains('captcha') || (id && id.includes('captcha'))) {
            return false;
        }
        if (dataSrc && !dataSrc.startsWith('data:image/') && dataSrc.length > 0) {
            if (hasMinRenderedSize(img)) {
                blurImage(img);
                img.setAttribute('isSent', 'true');
                img.setAttribute('src', dataSrc);
                return true;
            }
            else {
                return false;
            }
        }
        else if (!dataSrc || dataSrc.length === 0) {
            if (img.getAttribute("xlink:href")) {
                img.setAttribute('src', img.getAttribute("xlink:href"));
                img.setAttribute('srcAttr', "xlink:href");
                blurImage(img);
                img.setAttribute('isSent', 'true');
                return true;
            }
        }
        blurImage(img);
        return false;
    });

    const allImages = [...imageElements, ...lazyImageElements, ...backgroundImages];

    allImages.forEach(imgElement => {
        blurImage(imgElement);

        var mediaUrl = imgElement.getAttribute('src') || imgElement.getAttribute('data-src');
        imgElement.src = mediaUrl
        sendMessage("coreML/-/" + imgElement.src + "/-/" + imageCount);
        onProcessImageMap.set(imageCount, imgElement);
        imageCount++;
    })
  };

  window.addEventListener('load', function() { fetchNewImages(); });
  window.addEventListener('scroll', fetchNewImages);
  window.addEventListener('unload', sendMessage("page_refresh"))
  window.addEventListener('beforeunload', function () {
        // Reset the arrays when the page is about to unload
        onProcessImageMap.clear();
        imageCount = 0;
  });
}

getImageElements();
