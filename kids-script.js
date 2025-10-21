// KidsTube - Kid-Friendly Video App JavaScript

// Sample kid-friendly video data with REAL YouTube video IDs
const videoData = {
    all: [
        {
            id: 'jJ4Iu2PMNoc',
            title: 'Learn Colors with Blippi! 🌈',
            description: 'Learn about colors in a fun and interactive way with Blippi!',
            category: 'education',
            thumbnail: 'https://img.youtube.com/vi/jJ4Iu2PMNoc/maxresdefault.jpg',
            duration: '3:32',
            tags: ['colors', 'learning', 'fun', 'kids', 'education', 'blippi']
        },
        {
            id: 'XqZsoesa55w',
            title: 'Baby Shark Dance! 🦈',
            description: 'Sing and dance along with the Baby Shark family!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/XqZsoesa55w/maxresdefault.jpg',
            duration: '4:15',
            tags: ['baby', 'shark', 'dance', 'music', 'kids', 'songs']
        },
        {
            id: 'kffacxfA7G4',
            title: 'Wheels on the Bus! 🚌',
            description: 'Classic nursery rhyme with fun animations!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/kffacxfA7G4/maxresdefault.jpg',
            duration: '3:47',
            tags: ['wheels', 'bus', 'nursery', 'rhyme', 'kids', 'songs']
        },
        {
            id: 'CQY3KSUr4aI',
            title: 'Peppa Pig - Muddy Puddles! 🐷',
            description: 'Join Peppa Pig on exciting adventures!',
            category: 'cartoons',
            thumbnail: 'https://img.youtube.com/vi/CQY3KSUr4aI/maxresdefault.jpg',
            duration: '5:20',
            tags: ['peppa', 'pig', 'cartoon', 'adventure', 'fun', 'muddy']
        },
        {
            id: 'DRxq6KzIthA',
            title: 'Number Song 1-20! 🔢',
            description: 'Learn numbers 1-20 with fun songs and animations!',
            category: 'education',
            thumbnail: 'https://img.youtube.com/vi/DRxq6KzIthA/maxresdefault.jpg',
            duration: '6:30',
            tags: ['numbers', 'counting', 'math', 'learning', 'fun', 'kids']
        },
        {
            id: 'U3W5J3oZ_5M',
            title: 'Head Shoulders Knees and Toes! 💃',
            description: 'Get up and dance with this fun action song!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/U3W5J3oZ_5M/maxresdefault.jpg',
            duration: '4:45',
            tags: ['dancing', 'music', 'moving', 'exercise', 'fun', 'body']
        },
        {
            id: 'h6CNvzJhLdE',
            title: 'ABC Song - Alphabet Song! 📚',
            description: 'Learn the alphabet with this classic ABC song!',
            category: 'education',
            thumbnail: 'https://img.youtube.com/vi/h6CNvzJhLdE/maxresdefault.jpg',
            duration: '7:12',
            tags: ['alphabet', 'abc', 'letters', 'learning', 'fun', 'kids']
        },
        {
            id: 'YQHsXMglC9A',
            title: 'Magic Science Experiments! ✨',
            description: 'Amazing science experiments that look like magic!',
            category: 'education',
            thumbnail: 'https://img.youtube.com/vi/YQHsXMglC9A/maxresdefault.jpg',
            duration: '5:55',
            tags: ['science', 'experiments', 'magic', 'learning', 'fun', 'kids']
        },
        {
            id: 'fJ9rUzIMcZQ',
            title: 'Old MacDonald Had a Farm! 🐄',
            description: 'Sing along with Old MacDonald and his farm animals!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/fJ9rUzIMcZQ/maxresdefault.jpg',
            duration: '8:30',
            tags: ['farm', 'animals', 'macdonald', 'songs', 'kids', 'music']
        },
        {
            id: 'kJQP7kiw5Fk',
            title: 'Twinkle Twinkle Little Star! ⭐',
            description: 'Beautiful lullaby for bedtime!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/kJQP7kiw5Fk/maxresdefault.jpg',
            duration: '6:15',
            tags: ['twinkle', 'star', 'lullaby', 'bedtime', 'kids', 'songs']
        },
        {
            id: 'L_jWHffIx5E',
            title: 'If You\'re Happy and You Know It! 😊',
            description: 'Clap your hands and sing along!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/L_jWHffIx5E/maxresdefault.jpg',
            duration: '12:45',
            tags: ['happy', 'clap', 'hands', 'songs', 'kids', 'music']
        },
        {
            id: '9bZkp7q19f0',
            title: 'Paw Patrol - Adventure Bay! 🐕',
            description: 'Join the Paw Patrol on exciting rescue missions!',
            category: 'cartoons',
            thumbnail: 'https://img.youtube.com/vi/9bZkp7q19f0/maxresdefault.jpg',
            duration: '9:20',
            tags: ['paw', 'patrol', 'cartoon', 'adventure', 'rescue', 'dogs']
        }
    ],
    cartoons: [
        {
            id: 'CQY3KSUr4aI',
            title: 'Peppa Pig - Muddy Puddles! 🐷',
            description: 'Join Peppa Pig on exciting adventures!',
            category: 'cartoons',
            thumbnail: 'https://img.youtube.com/vi/CQY3KSUr4aI/maxresdefault.jpg',
            duration: '5:20',
            tags: ['peppa', 'pig', 'cartoon', 'adventure', 'fun', 'muddy']
        },
        {
            id: '9bZkp7q19f0',
            title: 'Paw Patrol - Adventure Bay! 🐕',
            description: 'Join the Paw Patrol on exciting rescue missions!',
            category: 'cartoons',
            thumbnail: 'https://img.youtube.com/vi/9bZkp7q19f0/maxresdefault.jpg',
            duration: '9:20',
            tags: ['paw', 'patrol', 'cartoon', 'adventure', 'rescue', 'dogs']
        }
    ],
    education: [
        {
            id: 'jJ4Iu2PMNoc',
            title: 'Learn Colors with Blippi! 🌈',
            description: 'Learn about colors in a fun and interactive way with Blippi!',
            category: 'education',
            thumbnail: 'https://img.youtube.com/vi/jJ4Iu2PMNoc/maxresdefault.jpg',
            duration: '3:32',
            tags: ['colors', 'learning', 'fun', 'kids', 'education', 'blippi']
        },
        {
            id: 'DRxq6KzIthA',
            title: 'Number Song 1-20! 🔢',
            description: 'Learn numbers 1-20 with fun songs and animations!',
            category: 'education',
            thumbnail: 'https://img.youtube.com/vi/DRxq6KzIthA/maxresdefault.jpg',
            duration: '6:30',
            tags: ['numbers', 'counting', 'math', 'learning', 'fun', 'kids']
        },
        {
            id: 'h6CNvzJhLdE',
            title: 'ABC Song - Alphabet Song! 📚',
            description: 'Learn the alphabet with this classic ABC song!',
            category: 'education',
            thumbnail: 'https://img.youtube.com/vi/h6CNvzJhLdE/maxresdefault.jpg',
            duration: '7:12',
            tags: ['alphabet', 'abc', 'letters', 'learning', 'fun', 'kids']
        },
        {
            id: 'YQHsXMglC9A',
            title: 'Magic Science Experiments! ✨',
            description: 'Amazing science experiments that look like magic!',
            category: 'education',
            thumbnail: 'https://img.youtube.com/vi/YQHsXMglC9A/maxresdefault.jpg',
            duration: '5:55',
            tags: ['science', 'experiments', 'magic', 'learning', 'fun', 'kids']
        }
    ],
    music: [
        {
            id: 'XqZsoesa55w',
            title: 'Baby Shark Dance! 🦈',
            description: 'Sing and dance along with the Baby Shark family!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/XqZsoesa55w/maxresdefault.jpg',
            duration: '4:15',
            tags: ['baby', 'shark', 'dance', 'music', 'kids', 'songs']
        },
        {
            id: 'kffacxfA7G4',
            title: 'Wheels on the Bus! 🚌',
            description: 'Classic nursery rhyme with fun animations!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/kffacxfA7G4/maxresdefault.jpg',
            duration: '3:47',
            tags: ['wheels', 'bus', 'nursery', 'rhyme', 'kids', 'songs']
        },
        {
            id: 'U3W5J3oZ_5M',
            title: 'Head Shoulders Knees and Toes! 💃',
            description: 'Get up and dance with this fun action song!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/U3W5J3oZ_5M/maxresdefault.jpg',
            duration: '4:45',
            tags: ['dancing', 'music', 'moving', 'exercise', 'fun', 'body']
        },
        {
            id: 'fJ9rUzIMcZQ',
            title: 'Old MacDonald Had a Farm! 🐄',
            description: 'Sing along with Old MacDonald and his farm animals!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/fJ9rUzIMcZQ/maxresdefault.jpg',
            duration: '8:30',
            tags: ['farm', 'animals', 'macdonald', 'songs', 'kids', 'music']
        },
        {
            id: 'kJQP7kiw5Fk',
            title: 'Twinkle Twinkle Little Star! ⭐',
            description: 'Beautiful lullaby for bedtime!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/kJQP7kiw5Fk/maxresdefault.jpg',
            duration: '6:15',
            tags: ['twinkle', 'star', 'lullaby', 'bedtime', 'kids', 'songs']
        },
        {
            id: 'L_jWHffIx5E',
            title: 'If You\'re Happy and You Know It! 😊',
            description: 'Clap your hands and sing along!',
            category: 'music',
            thumbnail: 'https://img.youtube.com/vi/L_jWHffIx5E/maxresdefault.jpg',
            duration: '12:45',
            tags: ['happy', 'clap', 'hands', 'songs', 'kids', 'music']
        }
    ],
    games: [
        {
            id: 'YQHsXMglC9A',
            title: 'Magic Science Experiments! ✨',
            description: 'Amazing science experiments that look like magic!',
            category: 'games',
            thumbnail: 'https://img.youtube.com/vi/YQHsXMglC9A/maxresdefault.jpg',
            duration: '5:55',
            tags: ['science', 'experiments', 'magic', 'learning', 'fun', 'kids']
        },
        {
            id: 'U3W5J3oZ_5M',
            title: 'Head Shoulders Knees and Toes! 💃',
            description: 'Get up and dance with this fun action song!',
            category: 'games',
            thumbnail: 'https://img.youtube.com/vi/U3W5J3oZ_5M/maxresdefault.jpg',
            duration: '4:45',
            tags: ['dancing', 'music', 'moving', 'exercise', 'fun', 'body']
        }
    ]
};

let currentCategory = 'all';
let currentVideo = null;

// Tonedown feature variables
let tonedownActive = false;
let tonedownStartTime = null;
let tonedownDuration = 30; // minutes
let tonedownInterval = null;
let tonedownProgress = 0;

// Initialize the app
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

function initializeApp() {
    console.log('Initializing KidsTube app...'); // Debug log
    setupEventListeners();
    loadVideos('all');
    showWelcomeMessage();
    
    // Test basic functionality
    setTimeout(() => {
        console.log('Testing app functionality...');
        console.log('Video data loaded:', videoData.all.length, 'videos');
        console.log('Search input element:', document.getElementById('searchInput') ? 'Found' : 'Not found');
        console.log('Videos container:', document.getElementById('videosContainer') ? 'Found' : 'Not found');
        console.log('Video player:', document.getElementById('videoPlayer') ? 'Found' : 'Not found');
    }, 1000);
}

function setupEventListeners() {
    // Navigation tabs
    const navTabs = document.querySelectorAll('.nav-tab');
    navTabs.forEach(tab => {
        tab.addEventListener('click', function() {
            const category = this.getAttribute('data-category');
            switchCategory(category);
        });
    });

    // Search functionality
    const searchInput = document.getElementById('searchInput');
    searchInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            searchVideos();
        }
    });

    // Video player click
    const videoPlayer = document.getElementById('videoPlayer');
    if (videoPlayer) {
        videoPlayer.addEventListener('click', function() {
            console.log('Video player clicked, currentVideo:', currentVideo); // Debug log
            if (currentVideo) {
                playVideo(currentVideo);
            } else {
                console.log('No video selected to play');
            }
        });
    } else {
        console.error('Video player element not found during initialization!');
    }
}

function switchCategory(category) {
    // Update active tab
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    document.querySelector(`[data-category="${category}"]`).classList.add('active');
    
    // Update current category
    currentCategory = category;
    
    // Load videos for the category
    loadVideos(category);
}

function loadVideos(category) {
    showLoading(true);
    
    setTimeout(() => {
        const videos = videoData[category] || videoData.all;
        displayVideos(videos);
        showLoading(false);
    }, 500);
}

function displayVideos(videos) {
    console.log('=== DISPLAY VIDEOS CALLED ===');
    console.log('Videos to display:', videos);
    
    const container = document.getElementById('videosContainer');
    if (!container) {
        console.error('Videos container not found!');
        return;
    }
    
    console.log('Displaying videos:', videos.length);
    container.innerHTML = '';

    if (!videos || videos.length === 0) {
        console.log('No videos to display');
        container.innerHTML = '<div class="no-videos">No videos found</div>';
        return;
    }

    videos.forEach((video, index) => {
        console.log(`Creating video card ${index + 1}:`, video.title);
        const videoCard = createVideoCard(video);
        container.appendChild(videoCard);
    });
    
    console.log('Finished displaying videos');
}

function createVideoCard(video) {
    console.log('Creating video card for:', video.title); // Debug log
    
    const card = document.createElement('div');
    card.className = 'video-card';
    card.onclick = () => {
        console.log('Video card clicked:', video.title); // Debug log
        selectVideo(video);
    };

    card.innerHTML = `
        <div class="video-thumbnail">
            <img src="${video.thumbnail}" alt="${video.title}" onerror="this.style.display='none'">
            <div class="play-overlay">
                <i class="fas fa-play"></i>
            </div>
        </div>
        <div class="video-details">
            <h4 class="video-title">${video.title}</h4>
            <div class="video-meta">
                <span class="category-tag">${video.category}</span>
                <span>${video.duration}</span>
            </div>
        </div>
    `;

    return card;
}

function selectVideo(video) {
    console.log('Selecting video:', video.title); // Debug log
    currentVideo = video;
    
    // Update video player
    const videoPlayer = document.getElementById('videoPlayer');
    if (!videoPlayer) {
        console.error('Video player element not found!');
        return;
    }
    
    videoPlayer.innerHTML = `
        <div class="video-placeholder">
            <i class="fas fa-play-circle"></i>
            <p>Click to play: ${video.title}</p>
        </div>
    `;
    
    // Update video info
    const titleElement = document.getElementById('videoTitle');
    const descElement = document.getElementById('videoDescription');
    
    if (titleElement) titleElement.textContent = video.title;
    if (descElement) descElement.textContent = video.description;
    
    // Add click animation
    videoPlayer.style.transform = 'scale(0.95)';
    setTimeout(() => {
        videoPlayer.style.transform = 'scale(1)';
    }, 150);
}

function playVideo(video) {
    if (!video) {
        console.log('No video provided to playVideo function');
        return;
    }
    
    console.log('Playing video:', video.title, 'ID:', video.id); // Debug log
    
    // Create YouTube iframe
    const videoPlayer = document.getElementById('videoPlayer');
    if (!videoPlayer) {
        console.error('Video player element not found!');
        return;
    }
    
    videoPlayer.innerHTML = `
        <iframe 
            width="100%" 
            height="100%" 
            src="https://www.youtube.com/embed/${video.id}?autoplay=1&rel=0&modestbranding=1&showinfo=0&controls=1&fs=1&cc_load_policy=1" 
            frameborder="0" 
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
            allowfullscreen>
        </iframe>
    `;
    
    // Update video info
    const titleElement = document.getElementById('videoTitle');
    const descElement = document.getElementById('videoDescription');
    
    if (titleElement) titleElement.textContent = video.title;
    if (descElement) descElement.textContent = video.description;
    
    // Add success animation
    showSuccessMessage(`Now playing: ${video.title}! 🎉`);
    
    // Scroll to show the video player nicely - more conservative approach
    setTimeout(() => {
        const headerHeight = document.querySelector('.header').offsetHeight;
        const navHeight = 60; // Approximate nav height
        const offset = headerHeight + navHeight + 10; // Reduced offset
        
        // Scroll to a position that shows the video player nicely
        const targetPosition = Math.max(0, offset);
        
        window.scrollTo({
            top: targetPosition,
            behavior: 'smooth'
        });
        
        console.log('Scrolling to position:', targetPosition, 'Header height:', headerHeight);
    }, 100);
}

function searchVideos() {
    console.log('=== SEARCH FUNCTION CALLED ===');
    
    const searchInput = document.getElementById('searchInput');
    if (!searchInput) {
        console.error('Search input element not found!');
        return;
    }
    
    const searchTerm = searchInput.value.toLowerCase().trim();
    console.log('Search term:', searchTerm);
    
    if (!searchTerm) {
        console.log('No search term, loading all videos');
        loadVideos(currentCategory);
        return;
    }
    
    console.log('Starting search...');
    showLoading(true);
    
    setTimeout(() => {
        const allVideos = videoData.all;
        console.log('Total videos available:', allVideos.length);
        
        const filteredVideos = allVideos.filter(video => {
            const titleMatch = video.title.toLowerCase().includes(searchTerm);
            const descMatch = video.description.toLowerCase().includes(searchTerm);
            const categoryMatch = video.category.toLowerCase().includes(searchTerm);
            const tagMatch = video.tags && video.tags.some(tag => tag.toLowerCase().includes(searchTerm));
            
            const result = titleMatch || descMatch || categoryMatch || tagMatch;
            console.log(`Video: ${video.title} - Match: ${result}`);
            return result;
        });
        
        console.log('Filtered videos found:', filteredVideos.length);
        console.log('Filtered videos:', filteredVideos.map(v => v.title));
        
        displayVideos(filteredVideos);
        showLoading(false);
        
        if (filteredVideos.length === 0) {
            showNoResultsMessage(searchTerm);
        } else {
            showSuccessMessage(`Found ${filteredVideos.length} video${filteredVideos.length === 1 ? '' : 's'} for "${searchTerm}"! 🎉`);
        }
    }, 500);
}

function showLoading(show) {
    const spinner = document.getElementById('loadingSpinner');
    if (show) {
        spinner.classList.add('show');
    } else {
        spinner.classList.remove('show');
    }
}

function showWelcomeMessage() {
    setTimeout(() => {
        showSuccessMessage('Welcome to KidsTube! Choose a fun video to watch! 🎈');
    }, 1000);
}

function showSuccessMessage(message) {
    // Create temporary success message
    const successDiv = document.createElement('div');
    successDiv.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: var(--primary-green);
        color: var(--text-dark);
        padding: 1rem 1.5rem;
        border-radius: var(--border-radius);
        box-shadow: var(--shadow-soft);
        z-index: 1000;
        font-weight: 600;
        animation: slideIn 0.3s ease;
    `;
    successDiv.textContent = message;
    
    document.body.appendChild(successDiv);
    
    setTimeout(() => {
        successDiv.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            document.body.removeChild(successDiv);
        }, 300);
    }, 3000);
}

function showNoResultsMessage(searchTerm) {
    const container = document.getElementById('videosContainer');
    container.innerHTML = `
        <div style="grid-column: 1 / -1; text-align: center; padding: 2rem; color: var(--text-light);">
            <i class="fas fa-search" style="font-size: 3rem; margin-bottom: 1rem; color: var(--primary-pink);"></i>
            <h3>No videos found for "${searchTerm}"</h3>
            <p>Try searching for something else or browse our categories!</p>
            <button onclick="loadVideos('${currentCategory}')" style="
                background: var(--primary-pink);
                color: var(--text-white);
                border: none;
                padding: 0.8rem 1.5rem;
                border-radius: var(--border-radius);
                font-family: 'Fredoka', sans-serif;
                font-weight: 600;
                cursor: pointer;
                margin-top: 1rem;
            ">Show All Videos</button>
        </div>
    `;
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
    
    @keyframes slideOut {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(100%); opacity: 0; }
    }
`;
document.head.appendChild(style);

// Prevent right-click context menu for better kid experience
document.addEventListener('contextmenu', function(e) {
    e.preventDefault();
});

// Disable text selection on video cards for better touch experience
document.addEventListener('selectstart', function(e) {
    if (e.target.closest('.video-card')) {
        e.preventDefault();
    }
});

// Add touch feedback for mobile
document.addEventListener('touchstart', function(e) {
    if (e.target.closest('.video-card')) {
        e.target.closest('.video-card').style.transform = 'scale(0.95)';
    }
});

document.addEventListener('touchend', function(e) {
    if (e.target.closest('.video-card')) {
        setTimeout(() => {
            e.target.closest('.video-card').style.transform = 'scale(1)';
        }, 150);
    }
});

// Keyboard navigation support
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && currentVideo) {
        // Reset video player
        const videoPlayer = document.getElementById('videoPlayer');
        videoPlayer.innerHTML = `
            <div class="video-placeholder">
                <i class="fas fa-play-circle"></i>
                <p>Click a video to start watching!</p>
            </div>
        `;
        currentVideo = null;
        document.getElementById('videoTitle').textContent = 'Welcome to KidsTube!';
        document.getElementById('videoDescription').textContent = 'Choose a fun video from below to get started! 🎉';
    }
});

// Service Worker registration for offline support (optional)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
        // Service worker can be added here for offline functionality
        console.log('KidsTube is ready! 🎈');
    });
}

// ==================== TONEDOWN FEATURE ====================

function toggleTonedown() {
    const toggleBtn = document.getElementById('tonedownToggle');
    const durationSelect = document.getElementById('tonedownDuration');
    
    if (!tonedownActive) {
        startTonedown();
    } else {
        stopTonedown();
    }
}

function startTonedown() {
    tonedownActive = true;
    tonedownStartTime = Date.now();
    tonedownDuration = parseInt(document.getElementById('tonedownDuration').value);
    tonedownProgress = 0;
    
    // Update UI
    const toggleBtn = document.getElementById('tonedownToggle');
    toggleBtn.innerHTML = '<i class="fas fa-pause"></i> Stop Tonedown';
    toggleBtn.classList.add('active');
    
    // Disable duration selection during tonedown
    document.getElementById('tonedownDuration').disabled = true;
    
    // Start the tonedown process
    tonedownInterval = setInterval(updateTonedown, 1000); // Update every second
    
    showSuccessMessage('Tonedown started! Colors will gradually fade to help reduce screen time. 🌙');
}

function stopTonedown() {
    tonedownActive = false;
    tonedownStartTime = null;
    tonedownProgress = 0;
    
    // Clear interval
    if (tonedownInterval) {
        clearInterval(tonedownInterval);
        tonedownInterval = null;
    }
    
    // Reset visual effects
    document.body.classList.remove('tonedown-active', 'tonedown-extreme');
    document.documentElement.style.setProperty('--saturation-level', '1');
    document.documentElement.style.setProperty('--brightness-level', '1');
    document.documentElement.style.setProperty('--contrast-level', '1');
    
    // Update UI
    const toggleBtn = document.getElementById('tonedownToggle');
    toggleBtn.innerHTML = '<i class="fas fa-play"></i> Start Tonedown';
    toggleBtn.classList.remove('active');
    
    // Re-enable duration selection
    document.getElementById('tonedownDuration').disabled = false;
    
    // Reset progress
    updateProgressDisplay(0, 'Tonedown stopped');
    
    showSuccessMessage('Tonedown stopped! Colors restored to full brightness. 🌈');
}

function updateTonedown() {
    if (!tonedownActive || !tonedownStartTime) return;
    
    const elapsed = Date.now() - tonedownStartTime;
    const totalDuration = tonedownDuration * 60 * 1000; // Convert to milliseconds
    const progress = Math.min(elapsed / totalDuration, 1);
    
    tonedownProgress = progress;
    
    // Update visual effects based on progress
    updateVisualEffects(progress);
    
    // Update progress display
    const remainingTime = Math.max(0, totalDuration - elapsed);
    const remainingMinutes = Math.ceil(remainingTime / (60 * 1000));
    updateProgressDisplay(progress, `Tonedown in progress... ${remainingMinutes} min left`);
    
    // Check if tonedown is complete
    if (progress >= 1) {
        completeTonedown();
    }
}

function updateVisualEffects(progress) {
    const root = document.documentElement;
    
    if (progress < 0.3) {
        // Early stage: slight reduction
        const factor = 1 - (progress * 0.3);
        root.style.setProperty('--saturation-level', factor);
        root.style.setProperty('--brightness-level', 1);
        root.style.setProperty('--contrast-level', 1);
        document.body.classList.remove('tonedown-active', 'tonedown-extreme');
    } else if (progress < 0.7) {
        // Middle stage: moderate reduction
        const factor = 0.7 - ((progress - 0.3) * 0.5);
        root.style.setProperty('--saturation-level', factor);
        root.style.setProperty('--brightness-level', 0.9 - ((progress - 0.3) * 0.2));
        root.style.setProperty('--contrast-level', 0.95 - ((progress - 0.3) * 0.15));
        document.body.classList.add('tonedown-active');
        document.body.classList.remove('tonedown-extreme');
    } else {
        // Final stage: significant reduction
        const factor = 0.2 - ((progress - 0.7) * 0.1);
        root.style.setProperty('--saturation-level', Math.max(factor, 0.1));
        root.style.setProperty('--brightness-level', Math.max(0.7 - ((progress - 0.7) * 0.2), 0.5));
        root.style.setProperty('--contrast-level', Math.max(0.8 - ((progress - 0.7) * 0.2), 0.6));
        document.body.classList.add('tonedown-extreme');
    }
}

function updateProgressDisplay(progress, text) {
    const progressFill = document.getElementById('progressFill');
    const progressText = document.getElementById('progressText');
    const timeRemaining = document.getElementById('timeRemaining');
    
    progressFill.style.width = `${progress * 100}%`;
    progressText.textContent = text;
    
    if (tonedownActive) {
        const remaining = tonedownDuration - Math.floor(progress * tonedownDuration);
        timeRemaining.textContent = `${remaining} min remaining`;
    } else {
        timeRemaining.textContent = '';
    }
}

function completeTonedown() {
    tonedownActive = false;
    
    // Clear interval
    if (tonedownInterval) {
        clearInterval(tonedownInterval);
        tonedownInterval = null;
    }
    
    // Apply maximum tonedown effect
    document.body.classList.add('tonedown-extreme');
    document.documentElement.style.setProperty('--saturation-level', '0.05');
    document.documentElement.style.setProperty('--brightness-level', '0.4');
    document.documentElement.style.setProperty('--contrast-level', '0.5');
    
    // Update UI
    const toggleBtn = document.getElementById('tonedownToggle');
    toggleBtn.innerHTML = '<i class="fas fa-check"></i> Tonedown Complete';
    toggleBtn.classList.remove('active');
    toggleBtn.style.background = '#95E1D3';
    
    // Re-enable duration selection
    document.getElementById('tonedownDuration').disabled = false;
    
    // Show completion message
    showSuccessMessage('Tonedown complete! Screen is now very dull to encourage stopping. 🛑');
    
    // Update progress display
    updateProgressDisplay(1, 'Tonedown complete - time to take a break!');
    
    // Auto-reset after 5 minutes of completion
    setTimeout(() => {
        if (!tonedownActive) {
            resetTonedown();
        }
    }, 5 * 60 * 1000);
}

function resetTonedown() {
    stopTonedown();
    
    // Reset all visual properties
    document.documentElement.style.setProperty('--saturation-level', '1');
    document.documentElement.style.setProperty('--brightness-level', '1');
    document.documentElement.style.setProperty('--contrast-level', '1');
    document.body.classList.remove('tonedown-active', 'tonedown-extreme');
    
    // Reset progress bar
    updateProgressDisplay(0, 'Ready to start tonedown');
    
    showSuccessMessage('Tonedown reset! All colors restored. 🌈');
}

// Initialize tonedown settings on page load
document.addEventListener('DOMContentLoaded', function() {
    // Set up duration change listener
    document.getElementById('tonedownDuration').addEventListener('change', function() {
        if (!tonedownActive) {
            tonedownDuration = parseInt(this.value);
        }
    });
    
    // Load saved settings from localStorage
    loadTonedownSettings();
});

function loadTonedownSettings() {
    const savedDuration = localStorage.getItem('tonedownDuration');
    if (savedDuration) {
        document.getElementById('tonedownDuration').value = savedDuration;
        tonedownDuration = parseInt(savedDuration);
    }
}

function saveTonedownSettings() {
    localStorage.setItem('tonedownDuration', document.getElementById('tonedownDuration').value);
}

// Save settings when duration changes
document.getElementById('tonedownDuration').addEventListener('change', function() {
    saveTonedownSettings();
});

// Add keyboard shortcut for tonedown (Ctrl+T)
document.addEventListener('keydown', function(e) {
    if (e.ctrlKey && e.key === 't') {
        e.preventDefault();
        toggleTonedown();
    }
});

// Add visual feedback for tonedown progress
function addTonedownVisualFeedback() {
    const style = document.createElement('style');
    style.textContent = `
        .tonedown-progress-indicator {
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(255, 107, 107, 0.9);
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-weight: 600;
            z-index: 1000;
            transition: all 0.3s ease;
        }
        
        .tonedown-warning {
            animation: warningPulse 1s infinite;
        }
        
        @keyframes warningPulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.7; }
        }
    `;
    document.head.appendChild(style);
}

// Initialize visual feedback
addTonedownVisualFeedback();

// Test functions for debugging
window.testSearch = function(term) {
    console.log('Testing search with term:', term);
    document.getElementById('searchInput').value = term;
    searchVideos();
};

window.testVideoPlay = function() {
    if (videoData.all.length > 0) {
        console.log('Testing video play with first video');
        selectVideo(videoData.all[0]);
        setTimeout(() => {
            playVideo(videoData.all[0]);
        }, 1000);
    }
};

window.testApp = function() {
    console.log('=== KidsTube App Test ===');
    console.log('Video data:', videoData);
    console.log('Current category:', currentCategory);
    console.log('Current video:', currentVideo);
    console.log('Available functions: testSearch(term), testVideoPlay()');
};
