// Add your CSS styles here
const css = `
.spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  border: 4px solid rgba(0, 0, 0, 0.3);
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 25px;
  margin-left: -12.5px;
  margin-top: -12.5px;
  height: 25px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}`;

// Create a style element and append it to the head to embed the CSS styles
const style = document.createElement('style');
style.innerHTML = css;
document.head.appendChild(style);


async function replaceImagesWithApiResults(apiUrl = 'https://api.safegaze.com/api/v1/analyze') {
  const batchSize = 4;
  const minImageSize = 30; // Minimum image size in pixels
  
  const imageElements = Array.from(document.getElementsByTagName('img')).filter(img => {
    const src = img.getAttribute('src');
    return src ? (!src.includes('.svg') && img.naturalWidth >= minImageSize && img.naturalHeight >= minImageSize) : false;
  });
  
  const lazyImageElements = Array.from(document.querySelectorAll('img[data-src]')).filter(img => {
    const dataSrc = img.getAttribute('data-src');
    return dataSrc ? (!dataSrc.includes('.svg') && img.naturalWidth >= minImageSize && img.naturalHeight >= minImageSize) : false;
  });
  
  const allImages = [...imageElements, ...lazyImageElements];
  const sentUrls = new Set(); // Set to keep track of URLs sent in requests
  
  // Function to apply blur effect to images and show spinner
  const blurImages = (images) => {
    images.forEach(imgElement => {
      imgElement.style.filter = 'blur(5px)';
      const spinner = document.createElement('div');
      spinner.classList.add('spinner');
      imgElement.parentElement.appendChild(spinner);
    });
  };
  
  // Function to remove blur effect and spinner from images
  const unblurImages = (images) => {
    images.forEach(imgElement => {
      imgElement.style.filter = 'none';
      const container = imgElement.parentElement; // Get the container that holds the image and spinner
      const spinner = container.querySelector('.spinner');
      if (spinner) {
        spinner.remove();
      }
    });
  };
  
  const replaceImages = async (batch) => {
    // Apply blur effect to images during API request
    blurImages(batch);
    
    // Create the request body.
    const requestBody = {
    media: batch.map(imgElement => ({
    media_url: imgElement.getAttribute('src') || imgElement.getAttribute('data-src'),
    media_type: 'image',
    has_attachment: false
    }))
    };
    
    console.log('Sending request:', JSON.stringify(requestBody)); // Log request body
    
    try {
      // Mark the URLs of all images in the current batch as sent in requests
      batch.forEach(imgElement => {
        const url = imgElement.getAttribute('src') || imgElement.getAttribute('data-src');
        sentUrls.add(url);
      });
      
      // Send the request to the API.
      const response = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody)
      });
      
      // Check if response status is ok
      if (!response.ok) {
        console.error('HTTP error, status = ' + response.status);
        return;
      }
      
      // Extract the response data from the response.
      const responseBody = await response.json();
      
      console.log('Received response:', responseBody); // Log response body
      
      if (responseBody.success) {
        responseBody.media.forEach((media, index) => {
          const processedMediaUrl = media.success ? media.processed_media_url : null;

          if (processedMediaUrl !== null) {
            batch[index].src = processedMediaUrl;
            if (batch[index].dataset) {
              batch[index].dataset.src = processedMediaUrl;
            }
            // Remove blur effect from the individual image after it is replaced successfully
            unblurImages([batch[index]]);
          }
          // Remove spinner and mark the image as replaced regardless of processed_media_url being null or not
          removeSpinner(batch[index]);
          batch[index].setAttribute('data-replaced', 'true');
        });
      } else {
        console.error('API request failed:', responseBody.errors);
      }
    } catch (error) {
      console.error('Error occurred during API request:', error);
    }
  };
  
  // Create batches of image URLs.
  const batches = [];
  for (let i = 0; i < allImages.length; i += batchSize) {
    batches.push(allImages.slice(i, i + batchSize));
  }
  
  for (const batch of batches) {
    // Filter out images that have already been replaced or sent in previous requests
    const imagesToReplace = batch.filter(imgElement => !imgElement.hasAttribute('data-replaced') && !sentUrls.has(imgElement.getAttribute('src') || imgElement.getAttribute('data-src')));
    
    if (imagesToReplace.length > 0) {
      await replaceImages(imagesToReplace);
    }
  }
  
  // Scroll event listener
  window.addEventListener('scroll', async () => {
    const newImages = Array.from(document.getElementsByTagName('img')).filter(img => {
      const src = img.getAttribute('src');
      return src && !src.includes('.svg') && !allImages.includes(img) && img.naturalWidth >= minImageSize && img.naturalHeight >= minImageSize && !sentUrls.has(src) && !img.hasAttribute('data-replaced');
    });
    
    if (newImages.length > 0) {
      const newBatches = [];
      for (let i = 0; i < newImages.length; i += batchSize) {
        newBatches.push(newImages.slice(i, i + batchSize));
      }
      
      for (const batch of newBatches) {
        // Filter out images that have already been replaced or sent in previous requests
        const imagesToReplace = batch.filter(imgElement => !imgElement.hasAttribute('data-replaced') && !sentUrls.has(imgElement.getAttribute('src') || imgElement.getAttribute('data-src')));
        
        if (imagesToReplace.length > 0) {
          await replaceImages(imagesToReplace);
        }
      }
      
      allImages.push(...newImages);
    }
  });
}

function removeSpinner(element) {
  // Replace this with your logic to remove the spinner element.
  // For example:
  // Assuming the spinner element has a class 'spinner':
  const spinnerElement = element.querySelector('.spinner');
  if (spinnerElement) {
    spinnerElement.remove();
  }
}

replaceImagesWithApiResults();
