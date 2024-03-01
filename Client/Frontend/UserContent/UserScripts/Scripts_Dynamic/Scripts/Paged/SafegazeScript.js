// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

const imagesToReplace = [];
const cleanedSavedImagesArray = []
const requestFailImages = {};

window.safegazeOnDeviceModelHandler = safegazeOnDeviceModelHandler;
window.sendMessage = sendMessage;
window.updateBluredImageOpacity = updateBluredImageOpacity;
window.safegazeSendBase64RequestsHandler = safegazeSendBase64RequestsHandler

async function sendSingleRequest(base64, src) {
    const requestBody = {
        media: [
            {
                media_ref: src,
                media_url: base64,
                media_type: "image",
                has_attachment: false
            }
        ]
    };

    try {
        //sendMessage("-> Request analyze base64 images has been sent")
        const response = await fetch('https://api.safegaze.com/api/v1/analyze', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
        });

        if (!response.ok) {
            sendMessage(`-> Response for ${src} fail -> HTTP error, status = ${response.status}`);
        } else {
            const responseBody = await response.json();
            //sendMessage(`-> Response for ${src} success -> HTTP status = ${response.status}`);

            if (responseBody.media.length === 0) {
                sendMessage('Empty response');
            } else {
                if (responseBody.success) {
                    const element = responseBody.media[0];
                    const correspondingMedia = requestFailImages[element.media_ref];
                    if (correspondingMedia) {
                        if (element.errors.length > 0) {
                            unblurImage(correspondingMedia);
                        } else {
                            setImageSrc(correspondingMedia, element.processed_media_url)
                        }
                    }
                } else {
                    sendMessage(`API request for ${src} failed: ${responseBody.errors}`);
                }
            }
        }
    } catch (error) {
        sendMessage(`Error occurred while processing ${src}: ${error.message}`);
    }
}

async function safegazeSendBase64RequestsHandler (srcs, base64s) {
    try {
        for (let i = 0; i < base64s.length; i++) {
            const base64 = base64s[i];
            const src = srcs[i];
            await sendSingleRequest(base64, src);
        }
    } catch(error) {
        sendMessage('Error occurred during /api/v1/safegazeSendBase64RequestsHandler request:' + error);
        /*srcs.map(src => {
            sendMessage("Error media:" + src)
            const correspondingMedia = requestFailImages[src];
            if (correspondingMedia) {
                unblurImage(correspondingMedia)
            }
        });*/
    }
};

async function safegazeOnDeviceModelHandler (isExist, index) {
    if (isExist === true) {
        imagesToReplace.push(cleanedSavedImagesArray[index]);

        // Check if the batch size (5) is reached, or if it's the last image
        if (imagesToReplace.length % 5 === 0) {
            try {
                //sendMessage("**//analyzedImages");
                await analyzeImages(imagesToReplace.slice(-5)); // Get the last 5 elements
            } catch (error) {
                sendMessage('**//Error in analyzeImages:' + error);
            }
        }
        else if (index === cleanedSavedImagesArray.length - 1) {
            // If it's the last image and we have fewer than 5 images, wait for a certain period
            setTimeout(async () => {
                if (imagesToReplace.length > 0 && index === cleanedSavedImagesArray.length - 1) {
                    try {
                        const startIndex = Math.floor(imagesToReplace.length / 5) * 5;
                        let slice = imagesToReplace.slice(startIndex)
                        //sendMessage("**//analyzedImages/escape " + slice.length);
                        await analyzeImages(slice);
                    } catch (error) {
                        sendMessage('**//Error in analyzeImages:' + error);
                    }
                }
            }, 1000); // Adjust the timeout value as needed
        } else {
            //sendMessage("**//skipForCount" + imagesToReplace.length);
        }
    } else {
        let element = cleanedSavedImagesArray[index]
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

function updateBluredImageOpacity() {
    const blurredElements = document.querySelectorAll('[isBlurred="true"]');
    blurredElements.forEach(element => {
        element.style.filter = `blur(${window.blurIntensity * 20}px)`;
    });
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

function setImageSrc(element, url) {
    const isBackgroundImage = element.getAttribute('hasBackgroundImage') && element.tagName !== "IMG" && element.tagName !== "image";
    if (isBackgroundImage) {
        element.style.backgroundImage = `url(${url})`;
        element.setAttribute('data-replaced', 'true');
        unblurImage(element);
    }
    else {
        element.src = url;
        element.removeAttribute('data-lazysrc');
        element.removeAttribute('srcset');
        element.removeAttribute('data-srcset');
        element.setAttribute('data-replaced', 'true');
        unblurImageOnLoad(element);
        if (element.dataset) {
            element.dataset.src = url;
        }
    }
    sendMessage("replaced"); //Sends message for total blurred imaged count
}

const sendConvertToBase64Request = async (batch) => {
    let base64Request = "ConvertToBase64";
    batch.forEach(imgElement => {
        requestFailImages[imgElement.src] = imgElement;
        base64Request += "/**/" + imgElement.src;
    });
    sendMessage(base64Request);
};


const analyzeImages = async (batch) => {
  const requestBody = {
   media: batch.map(imgElement => {
         return {
           media_url: imgElement.getAttribute('src'),
           media_type: "image",
           has_attachment: false,
           srcAttr: imgElement.getAttribute('srcAttr')
         };
       })
  };
  
  try {
    // Mark the URLs of all images in the current batch as sent in requests
    batch.forEach(imgElement => imgElement.setAttribute('isSent', 'true'));
      
    //sendMessage("->Request analyzeImages has been sent")

    const response = await fetch('https://api.safegaze.com/api/v1/analyze', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody)
    });
    
    if (!response.ok) {
      sendMessage('->Response analyzeImages fail -> HTTP error, status = ' + response.status + "->" + JSON.stringify(requestBody));
      return;
    }
      
    const responseBody = await response.json();
    if (responseBody.media.length === 0) {
        sendMessage('Empty response');
    }
    else {
        if (responseBody.success) {
          const failImagesArray = []
          batch.forEach((element, index) => {
                const correspondingMedia = responseBody.media.find(media => element.src === media.original_media_url || element.src.includes(media.original_media_url));
                if (correspondingMedia) {
                    if (correspondingMedia.success) {
                        setImageSrc(element, correspondingMedia.processed_media_url);
                    }
                    else {
                        failImagesArray.push(element);
                    }
                }
          });
          if (failImagesArray.length !== 0) {
            await sendConvertToBase64Request(failImagesArray);
          }
        } else {
          sendMessage('API request failed:' + responseBody.errors);
        }
    }
  } catch (error) {
      sendMessage('Error occurred during /api/v1/analyze request:' + error);
  }
};


async function replaceImagesWithApiResults() {
  const batchSize = 4;
  const minImageSize = 40; // Minimum image size in pixels
  
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
    if (allImages.length > 0) {
         const analyzePromises = [];
         allImages.forEach(imgElement => {
           var mediaUrl = imgElement.getAttribute('src') || imgElement.getAttribute('data-src');
           var absoluteUrl = new URL(mediaUrl, window.location.origin).href;
           if (absoluteUrl) {
               mediaUrl = absoluteUrl;
           }

           let analyzer = new RemoteAnalyzer({ mediaUrl });
           const analyzePromise = analyzer.analyze().then((result) => {
             if (!result.shouldMask) {
               imgElement.src = mediaUrl
               sendMessage("coreML/-/" + imgElement.src + "/-/" + cleanedSavedImagesArray.length); //Pushs image url to on device model
               cleanedSavedImagesArray.push(imgElement)
             } else {
               setImageSrc(imgElement, result.maskedUrl);
             }
           }).catch((err) => {
             sendMessage("Error analyzing media:" + err);
           });
           analyzePromises.push(analyzePromise);
         })

         await Promise.all(analyzePromises)
        }
  };
  window.addEventListener('load', function() { fetchNewImages(); });
  window.addEventListener('scroll', fetchNewImages);
  window.addEventListener('beforeunload', function () {
        // Reset the arrays when the page is about to unload
        imagesToReplace.length = 0;
        cleanedSavedImagesArray.length = 0;
  });
}

class RemoteAnalyzer {
  constructor(data) {
    this.data = data;
  }

  analyze = async () => {
    try {
      let relativeFilePath = await this.relativeFilePath(this.data.mediaUrl);
      if (await this.urlExists(relativeFilePath)) {
        return {
          shouldMask: true,
          maskedUrl: relativeFilePath,
        };
      }
    } catch (error) {
      sendMessage("RemoteAnalyzer Error: " + error.toString());
    }
    return {
      shouldMask: false,
      maskedUrl: ""
    };
  };

  urlExists = async (url) => {
      try {
        const response = await fetch(url, {
          method: "GET",
          cache: "no-cache"
        });
        return response.ok;
      } catch (error) {
        sendMessage(error.toString());
        return false;
      }
    };

  relativeFilePath = async (originalMediaUrl) => {
    const hash = await this.sha256(originalMediaUrl);
    let newUrl = `https://images.safegaze.com/annotated_image/${hash}/image.png`;
    return newUrl;
  };
    
 sha256 = async (str) => {
      try {
        const encoder = new TextEncoder();
        const data = encoder.encode(str);
        const hashBuffer = await crypto.subtle.digest('SHA-256', data);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        const hashHex = hashArray.map(byte => byte.toString(16).padStart(2, '0')).join('');
        return hashHex;
      } catch (error) {
        sendMessage("Sha256 Error: " + error.toString());
        return "";
      }
  };
}

replaceImagesWithApiResults();
