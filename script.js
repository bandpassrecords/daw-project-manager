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
    
    // Default to Windows if unknown
    return 'windows';
}

// Show appropriate download card based on OS
function showDownloadCard() {
    const os = detectOS();
    const windowsCard = document.getElementById('windows-download');
    const macosCard = document.getElementById('macos-download');
    const heroBadges = document.getElementById('hero-badges');
    
    if (os === 'macos' && macosCard) {
        macosCard.style.display = 'block';
        if (heroBadges) {
            heroBadges.innerHTML = '<span class="badge">macOS</span><span class="badge">v1.2.0</span>';
        }
    } else if (windowsCard) {
        windowsCard.style.display = 'block';
        if (heroBadges) {
            heroBadges.innerHTML = '<span class="badge">Windows</span><span class="badge">v1.2.0</span>';
        }
    }
}

// Observe feature cards and other elements
document.addEventListener('DOMContentLoaded', () => {
    // Show appropriate download card
    showDownloadCard();
    
    const animatedElements = document.querySelectorAll('.feature-card, .daw-item, .download-card');
    
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

