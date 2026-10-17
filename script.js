// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add scroll effect to navbar
let lastScroll = 0;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;
    
    if (currentScroll > 100) {
        navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.3)';
    } else {
        navbar.style.boxShadow = 'none';
    }
    
    lastScroll = currentScroll;
});

// Fade in animation on scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Detect operating system and show appropriate download
function detectOS() {
    const userAgent = navigator.userAgent || navigator.vendor || window.opera;
    const platform = navigator.platform || navigator.userAgentData?.platform;

    // Check for macOS
    if (/Mac|iPhone|iPad|iPod/.test(platform) || /Mac|iPhone|iPad|iPod/.test(userAgent)) {
        return 'macos';
    }

    // Check for Windows
    if (/Win/.test(platform) || /Win/.test(userAgent) || /Windows/.test(userAgent)) {
        return 'windows';
    }

    // Check for Linux (desktop only — Android's user agent also contains
    // "Linux", so it must be excluded here; there's no dedicated Android
    // card on this page, so an Android visitor keeps falling through to the
    // Windows default below, same as before this check was added).
    if (!/Android/.test(userAgent) && (/Linux/.test(platform) || /Linux/.test(userAgent) || /X11/.test(userAgent))) {
        return 'linux';
    }

    // Default to Windows if unknown
    return 'windows';
}

// Show appropriate download card based on OS
function showDownloadCard() {
    const os = detectOS();
    const windowsCard = document.getElementById('windows-download');
    const macosCard = document.getElementById('macos-download');
    const linuxCard = document.getElementById('linux-download');
    const windowsOtherPlatform = document.getElementById('windows-other-platform');
    const macosOtherPlatform = document.getElementById('macos-other-platform');
    const linuxOtherPlatform = document.getElementById('linux-other-platform');
    const heroBadges = document.getElementById('hero-badges');

    if (os === 'macos' && macosCard) {
        macosCard.style.display = 'block';
        if (macosOtherPlatform) {
            macosOtherPlatform.style.display = 'block';
        }
    } else if (os === 'linux' && linuxCard) {
        linuxCard.style.display = 'block';
        if (linuxOtherPlatform) {
            linuxOtherPlatform.style.display = 'block';
        }
    } else if (windowsCard) {
        windowsCard.style.display = 'block';
        if (windowsOtherPlatform) {
            windowsOtherPlatform.style.display = 'block';
        }
    }
}

// Filter the Supported DAWs grid as the user types — matches against both
// the DAW name and its file extension(s), so e.g. "als" finds Ableton Live.
function setupDawSearch() {
    const input = document.getElementById('daw-search-input');
    const grid = document.getElementById('daws-grid');
    const emptyMessage = document.getElementById('daw-search-empty');
    if (!input || !grid) return;

    const items = Array.from(grid.querySelectorAll('.daw-item'));

    input.addEventListener('input', () => {
        const query = input.value.trim().toLowerCase();
        let visibleCount = 0;

        items.forEach(item => {
            const matches = query === '' || item.textContent.toLowerCase().includes(query);
            item.style.display = matches ? '' : 'none';
            if (matches) visibleCount++;
        });

        if (emptyMessage) {
            emptyMessage.style.display = visibleCount === 0 ? 'block' : 'none';
        }
    });
}

// Open any app screenshot full-size in a lightbox on click; close via the
// close button, clicking the backdrop, or Escape.
function setupLightbox() {
    const lightbox = document.getElementById('lightbox');
    const lightboxImg = document.getElementById('lightbox-img');
    const closeBtn = document.getElementById('lightbox-close');
    if (!lightbox || !lightboxImg || !closeBtn) return;

    function closeLightbox() {
        lightbox.classList.remove('active');
        lightboxImg.src = '';
    }

    document.querySelectorAll('img.app-screenshot').forEach(img => {
        img.addEventListener('click', () => {
            lightboxImg.src = img.src;
            lightboxImg.alt = img.alt;
            lightbox.classList.add('active');
        });
    });

    closeBtn.addEventListener('click', closeLightbox);
    lightbox.addEventListener('click', (e) => {
        if (e.target === lightbox) closeLightbox();
    });
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeLightbox();
    });
}

// Observe feature cards and other elements
document.addEventListener('DOMContentLoaded', () => {
    // Show appropriate download card
    showDownloadCard();

    setupDawSearch();
    setupLightbox();

    const animatedElements = document.querySelectorAll('.feature-row, .daw-item, .download-card');

    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});


// Metadata Extraction Support: typing narrows the table to your DAW.
// Case, spaces and punctuation are ignored, so "fl", "flstudio" and
// "FL Studio" all find the same row.
(() => {
    const input = document.getElementById('metadata-filter');
    const table = document.querySelector('.metadata-table');
    const empty = document.getElementById('metadata-empty');
    if (!input || !table || !empty) return;
    const fold = text => text.toLowerCase().replace(/[^a-z0-9]/g, '');
    const rows = [...table.tBodies[0].rows].map(row => ({
        row,
        name: fold(row.querySelector('.metadata-daw')?.textContent ?? ''),
    }));
    input.addEventListener('input', () => {
        const query = fold(input.value);
        let shown = 0;
        for (const { row, name } of rows) {
            const match = name.includes(query);
            row.hidden = !match;
            if (match) shown++;
        }
        table.hidden = shown === 0;
        empty.hidden = shown !== 0;
        empty.querySelector('span').textContent = input.value.trim();
    });
})();
