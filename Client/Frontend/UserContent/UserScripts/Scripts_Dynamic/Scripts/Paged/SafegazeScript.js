// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

const onProcessImageMap = new Map();
var imageCount = 0;

window.safegazeOnDeviceModelHandler = safegazeOnDeviceModelHandler;
window.updateBluredImageOpacity = updateBluredImageOpacity;

async function safegazeOnDeviceModelHandler(shouldBlur, index) {
    if (shouldBlur) {
        const imgElement = onProcessImageMap.get(index);
        onProcessImageMap.delete(index);
        imgElement.setAttribute('isSent', 'true');

        sendMessage("replaced"); // Update total blurred image count

        // upon hover or long press, we will unblur the image momentarily
        imgElement.onmouseenter = () => {
            unblurImage(imgElement);
        };
        imgElement.onmouseleave = () => {
            blurImage(imgElement);
        }

        // mobile touch will unblur the image momentarily
        imgElement.ontouchstart = () => {
            unblurImage(imgElement)
            setTimeout(() => {
                blurImage(imgElement)
            }, 2000);
        }

    } else {
        let element = onProcessImageMap.get(index);
        onProcessImageMap.delete(index);
        unblurImage(element);
    }
};

function blurImage(image) {
    image.style.filter = `blur(${window.blurIntensity * 10}px) grayscale(100%) brightness(0.5)`;
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
        element.style.filter = `blur(${window.blurIntensity * 10}px) grayscale(100%) brightness(0.5)`;
    });
}

async function getImageElements() {
    try {
    const minImageSize = 45; // Minimum image size in pixels

    const hasMinRenderedSize = (element) => {
        const rect = element.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) return "not rendered yet";
        return (rect.width >= minImageSize && rect.height >= minImageSize)
    };

    const processImage = (htmlElement, src, type="img", srcChanged = false, skipCheck = false) => {
        if (htmlElement.getAttribute('isSent') === type && !srcChanged) return;
        // we need to check the image size, but for that we need to make sure the image
        // has been loaded. If it has not been loaded, we need to wait for it to load
        if (skipCheck || typeof htmlElement.complete !== 'undefined') {
            if (htmlElement.complete) {
                if (!hasMinRenderedSize(htmlElement)) return;
            } else {
                const prevImgLoad = htmlElement.onload // Save the previous onload function
                htmlElement.onload = () => {
                    if (hasMinRenderedSize(htmlElement)) {
                        processImage(htmlElement, htmlElement.src, false, true);
                    }
                    return prevImgLoad ? prevImgLoad() : null;
                }
                return;
            }
        } else {
            if (hasMinRenderedSize(htmlElement) === false) return; // If the element is rendered but not of minimum size
        }

        blurImage(htmlElement);
        const srcEdited = src?.startsWith('://') ? 'https:' + src
        : src?.startsWith('data:') ? src
        : src;
        sendMessage("coreML/-/" + srcEdited + "/-/" + imageCount);
        htmlElement.setAttribute('isSent', type);
        onProcessImageMap.set(imageCount, htmlElement);
        imageCount++;
    }

    const observeElement = (el, srcChanged=false) => {
        try {
            if (!el.getAttribute) return;
            if (el.getAttribute('isObserved') && !srcChanged) return;
            el.setAttribute('isObserved', 'true');

            let src = el.src
            const srcChecker = /url\(\s*?['"]?\s*?(\S+?)\s*?["']?\s*?\)/i
            let bgImage = window.getComputedStyle(el, null).getPropertyValue('background-image')
            let match = bgImage.match(srcChecker);
            // let xlink = el.getAttribute('xlink:href');
            
            if (/^img$/i.test(el.tagName)) { // to handle img tags
                if (el.src?.length > 0) {
                    processImage(el, src, "img", srcChanged);
                }
            }
            // SVG images are not supported for now
            // else if (xlink) { // to handle svg images
            //         src = xlink;
            //         processImage(el, src, "svg");
            // }
            else if (match) { // to handle background images
                src = match[1];
                processImage(el, src,"bg");
            }
        } catch (e) {
            console.log(e);
        }

    }
    
    const fetchNewImages = (mutations) => {
        mutations.forEach(mutation => {
            if (mutation.type === 'childList') {
                mutation.addedNodes.forEach(node => {

                    observeElement(node);
                    // Process all child elements
                    if (!node.getElementsByTagName) return;
                    const allElements = node.getElementsByTagName('*');
                    for (let i = 0; i < allElements.length; i++) {
                        observeElement(allElements[i]);
                    }
                });
            } else if (mutation.type === 'attributes') {
                const el = mutation.target;
                observeElement(el, mutation.attributeName === 'src');
            }
        });
    }

            
    const observer = new MutationObserver(fetchNewImages)
    observer.observe(document, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['src']
    });
} catch (e) {
    console.log(e);
}
}


getImageElements();
