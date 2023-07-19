async function replaceImagesWithApiResults(apiUrl = 'https://api.safegaze.com/api/v1/analyze') {
    const batchSize = 4;

    const imageElements = Array.from(document.getElementsByTagName('img')).filter(img => !img.src.endsWith('.svg'));
    const lazyImageElements = Array.from(document.querySelectorAll('img[data-src]')).filter(img => !img.dataset.src.endsWith('.svg'));

    const allImages = [...imageElements, ...lazyImageElements];

    // Create batches of image URLs.
    const batches = [];
    for (let i = 0; i < allImages.length; i += batchSize) {
        batches.push(allImages.slice(i, i + batchSize));
    }

    for (const batch of batches) {
        try {
            // Create the request body.
            const requestBody = {
                media: batch.map(imgElement => ({
                    media_url: imgElement.src || imgElement.dataset.src,
                    media_type: 'image',
                    has_attachment: false
                }))
            };

            console.log('Sending request:', requestBody); // Log request body

            // Send the request to the API.
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(requestBody)
            });

            // Check if response status is ok
            if (!response.ok) {
                console.error('HTTP error, status = ' + response.status);
                continue;
            }

            // Extract the new URLs from the response.
            const responseBody = await response.json();

            console.log('Received response:', responseBody); // Log response body

            if (responseBody.success) {
                responseBody.media.forEach((media, index) => {
                    if (media.success) {
                        batch[index].src = "https://idsb.tmgrup.com.tr/ly/uploads/images/2023/07/13/thumbs/800x531/282268.jpg?v=1689250351";
                        if (batch[index].dataset) { // Check if data-src exists before trying to set it
                            batch[index].dataset.src = "https://idsb.tmgrup.com.tr/ly/uploads/images/2023/07/13/thumbs/800x531/282268.jpg?v=1689250351"
                        }
                    } else {
                        console.error('API failed to process image:', media.errors);
                    }
                });
            } else {
                console.error('API request failed:', responseBody.errors);
            }
        } catch (error) {
            console.error('Error occurred during API request:', error);
        }
    }
}

replaceImagesWithApiResults();


async function replaceImagesWithApiResults(apiUrl = 'https://api.safegaze.com/api/v1/analyze') {
    const batchSize = 4;

    const imageElements = Array.from(document.getElementsByTagName('img')).filter(img => {
        const src = img.getAttribute('src');
        return src ? !src.includes('.svg') : false;
    });

    const lazyImageElements = Array.from(document.querySelectorAll('img[data-src]')).filter(img => {
        const dataSrc = img.getAttribute('data-src');
        return dataSrc ? !dataSrc.includes('.svg') : false;
    });

    const allImages = [...imageElements, ...lazyImageElements];

    // Create batches of image URLs.
    const batches = [];
    for (let i = 0; i < allImages.length; i += batchSize) {
        batches.push(allImages.slice(i, i + batchSize));
    }

    for (const batch of batches) {
        try {
            // Create the request body.
            const requestBody = {
                media: batch.map(imgElement => ({
                    media_url: imgElement.getAttribute('src') || imgElement.getAttribute('data-src'),
                    media_type: 'image',
                    has_attachment: false
                }))
            };

            console.log('Sending request:', requestBody); // Log request body

            // Send the request to the API.
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(requestBody)
            });

            // Check if response status is ok
            if (!response.ok) {
                console.error('HTTP error, status = ' + response.status);
                continue;
            }

            // Extract the new URLs from the response.
            const responseBody = await response.json();

            console.log('Received response:', responseBody); // Log response body

            if (responseBody.success) {
                responseBody.media.forEach((media, index) => {
                  if (media.success) {
                      batch[index].src = "https://idsb.tmgrup.com.tr/ly/uploads/images/2023/07/13/thumbs/800x531/282268.jpg?v=1689250351";
                      if (batch[index].dataset) { // Check if data-src exists before trying to set it
                          batch[index].dataset.src = "https://idsb.tmgrup.com.tr/ly/uploads/images/2023/07/13/thumbs/800x531/282268.jpg?v=1689250351"
                      }
                  } else {
                      console.error('API failed to process image:', media.errors);
                  }
                });
            } else {
                console.error('API request failed:', responseBody.errors);
            }
        } catch (error) {
            console.error('Error occurred during API request:', error);
        }
    }
}

replaceImagesWithApiResults();
