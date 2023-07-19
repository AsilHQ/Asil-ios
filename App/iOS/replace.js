const apiUrl = 'https://api.safegaze.com/api/v1/analyze';
let processedUrls = [];
let processingUrls = [];

// Function to process a batch of images
const processImagesBatch = async (imageBatch) => {
  const batchUrls = imageBatch.map(img => img.dataset.src || img.src);

  // Filter out URLs that should not be processed
  const urlsToProcess = batchUrls.filter(url => {
    return !url.includes('.svg') &&
      !processedUrls.includes(url) &&
      !processingUrls.includes(url);
  });

  if (urlsToProcess.length === 0) {
    return;
  }

  processingUrls.push(...urlsToProcess);

  const requestBody = {
    media: urlsToProcess.map(url => ({
      media_url: url,
      media_type: 'image',
      has_attachment: false,
    })),
  };

  console.log('Sending Request:', requestBody);  // Log the request

  // Apply blur to all images in the batch
  imageBatch.forEach(img => img.style.filter = 'blur(5px)');

  try {
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      throw new Error('Request failed');
    }

    const data = await response.json();
    console.log('Received Response:', data);  // Log the response

    // Process each image in the batch
    for (let i = 0; i < imageBatch.length; i++) {
      const img = imageBatch[i];
      const url = img.dataset.src || img.src;
      const urlIndex = urlsToProcess.indexOf(url);

      if (urlIndex !== -1 && data.media[urlIndex].processed_media_url) {
        img.src = "  https://idsb.tmgrup.com.tr/ly/uploads/images/2023/07/13/thumbs/800x531/282268.jpg?v=1689250351"
        img.style.filter = '';  // Remove blur
      }
    }

    processingUrls = processingUrls.filter(urlProcessing => !urlsToProcess.includes(urlProcessing));
    processedUrls.push(...urlsToProcess);
  } catch (error) {
    console.error('Analyze request failed:', error);
    console.error('Failed URLs:', urlsToProcess);
  }
};

// Process initially visible images in batches of 4
const initialImages = Array.from(document.getElementsByTagName('img'));
for (let i = 0; i < initialImages.length; i += 4) {
  const imageBatch = initialImages.slice(i, i + 4);
  processImagesBatch(imageBatch);
}

// Observer for new images entering the viewport
const observer = new IntersectionObserver((entries, observer) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const img = entry.target;
      observer.unobserve(img);
      processImagesBatch([img]);  // Send each lazy-loaded image separately
    }
  });
}, {rootMargin: '0px', threshold: 0.1});

// Scroll event listener for lazy-loaded images
window.addEventListener('scroll', () => {
  Array.from(document.getElementsByTagName('img')).forEach(img => {
    if (img.getBoundingClientRect().top < window.innerHeight && img.getBoundingClientRect().bottom >= 0) {
      observer.observe(img);
    }
  });
});
