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

    // Function to apply blur effect to images
    const blurImages = (images) => {
        images.forEach(imgElement => {
            imgElement.style.filter = 'blur(5px)';
        });
    };

    // Function to remove blur effect from images
    const unblurImages = (images) => {
        images.forEach(imgElement => {
            imgElement.style.filter = 'none';
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
                    if (media.success) {
                        const processedMediaUrl = media.processed_media_url;
                        batch[index].src = processedMediaUrl;
                        if (batch[index].dataset) { // Check if data-src exists before trying to set it
                            batch[index].dataset.src = processedMediaUrl;
                        }
                        // Mark the image as replaced by adding the data-replaced attribute
                        batch[index].setAttribute('data-replaced', 'true');
                        // Remove blur effect from the individual image after it is replaced successfully
                        unblurImages([batch[index]]);
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

replaceImagesWithApiResults();
