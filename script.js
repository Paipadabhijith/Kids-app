// Mobile Navigation Toggle
const hamburger = document.querySelector('.hamburger');
const navMenu = document.querySelector('.nav-menu');

hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('active');
    navMenu.classList.toggle('active');
    
    // Prevent body scroll when menu is open
    if (navMenu.classList.contains('active')) {
        document.body.style.overflow = 'hidden';
    } else {
        document.body.style.overflow = 'auto';
    }
});

// Close mobile menu when clicking on a link
document.querySelectorAll('.nav-link').forEach(n => n.addEventListener('click', () => {
    hamburger.classList.remove('active');
    navMenu.classList.remove('active');
    document.body.style.overflow = 'auto';
}));

// Close mobile menu when clicking outside
document.addEventListener('click', (e) => {
    if (!hamburger.contains(e.target) && !navMenu.contains(e.target)) {
        hamburger.classList.remove('active');
        navMenu.classList.remove('active');
        document.body.style.overflow = 'auto';
    }
});

// Handle window resize
window.addEventListener('resize', () => {
    if (window.innerWidth > 768) {
        hamburger.classList.remove('active');
        navMenu.classList.remove('active');
        document.body.style.overflow = 'auto';
    }
});

// Smooth scrolling for navigation links
function scrollToSection(sectionId) {
    const element = document.getElementById(sectionId);
    if (element) {
        element.scrollIntoView({
            behavior: 'smooth',
            block: 'start'
        });
    }
}

// Add click event listeners to navigation links
document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', (e) => {
        const href = link.getAttribute('href');
        
        // Only prevent default for anchor links (starting with #)
        if (href.startsWith('#')) {
            e.preventDefault();
            const targetId = href.substring(1);
            scrollToSection(targetId);
        }
        // For external links (like history.html), let them work normally
    });
});

// Navbar background change on scroll
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.background = 'linear-gradient(135deg, rgba(139, 21, 56, 0.98) 0%, rgba(160, 30, 66, 0.98) 100%)';
        navbar.style.boxShadow = '0 4px 20px rgba(139, 21, 56, 0.4)';
    } else {
        navbar.style.background = 'linear-gradient(135deg, #8b1538 0%, #a01e42 100%)';
        navbar.style.boxShadow = '0 4px 20px rgba(139, 21, 56, 0.3)';
    }
});

// Form submission handling
const contactForm = document.querySelector('.contact-form');
if (contactForm) {
    contactForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        // Get form data
        const formData = new FormData(contactForm);
        const name = contactForm.querySelector('input[type="text"]').value;
        const email = contactForm.querySelector('input[type="email"]').value;
        const message = contactForm.querySelector('textarea').value;
        
        // Simple validation
        if (!name || !email || !message) {
            alert('Please fill in all fields.');
            return;
        }
        
        // Simulate form submission
        const submitBtn = contactForm.querySelector('.btn-primary');
        const originalText = submitBtn.textContent;
        
        submitBtn.textContent = 'Sending...';
        submitBtn.disabled = true;
        
        setTimeout(() => {
            alert('Thank you for your message! We\'ll get back to you soon.');
            contactForm.reset();
            submitBtn.textContent = originalText;
            submitBtn.disabled = false;
        }, 2000);
    });
}

// Newsletter subscription
const newsletterForm = document.querySelector('.newsletter-form');
if (newsletterForm) {
    newsletterForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        const email = newsletterForm.querySelector('input[type="email"]').value;
        if (!email) {
            alert('Please enter your email address.');
            return;
        }
        
        const submitBtn = newsletterForm.querySelector('.btn-primary');
        const originalText = submitBtn.textContent;
        
        submitBtn.textContent = 'Subscribing...';
        submitBtn.disabled = true;
        
        setTimeout(() => {
            alert('Thank you for subscribing to our newsletter!');
            newsletterForm.reset();
            submitBtn.textContent = originalText;
            submitBtn.disabled = false;
        }, 1500);
    });
}

// Intersection Observer for animations
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

// Observe elements for animation
document.addEventListener('DOMContentLoaded', () => {
    const animatedElements = document.querySelectorAll('.feature-card, .destination-card, .about-text, .contact-info');
    
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// Destination card hover effects
document.querySelectorAll('.destination-card').forEach(card => {
    card.addEventListener('mouseenter', () => {
        card.style.transform = 'translateY(-10px) scale(1.02)';
    });
    
    card.addEventListener('mouseleave', () => {
        card.style.transform = 'translateY(0) scale(1)';
    });
});

// Feature card click effects
document.querySelectorAll('.feature-card').forEach(card => {
    card.addEventListener('click', () => {
        card.style.transform = 'translateY(-5px) scale(1.02)';
        setTimeout(() => {
            card.style.transform = 'translateY(-5px) scale(1)';
        }, 150);
    });
});

// Floating cards animation enhancement
document.querySelectorAll('.floating-card').forEach((card, index) => {
    card.addEventListener('mouseenter', () => {
        card.style.animationPlayState = 'paused';
        card.style.transform = 'translateY(-15px) scale(1.05)';
    });
    
    card.addEventListener('mouseleave', () => {
        card.style.animationPlayState = 'running';
        card.style.transform = 'translateY(0) scale(1)';
    });
});

// Add loading animation
window.addEventListener('load', () => {
    document.body.style.opacity = '0';
    document.body.style.transition = 'opacity 0.5s ease';
    
    setTimeout(() => {
        document.body.style.opacity = '1';
    }, 100);
});

// Back to top button
const backToTopBtn = document.createElement('button');
backToTopBtn.innerHTML = '<i class="fas fa-arrow-up"></i>';
backToTopBtn.className = 'back-to-top';
backToTopBtn.style.cssText = `
    position: fixed;
    bottom: 20px;
    right: 20px;
    width: 50px;
    height: 50px;
    background: linear-gradient(135deg, #8b1538 0%, #a01e42 100%);
    color: white;
    border: 2px solid #d4af37;
    border-radius: 50%;
    cursor: pointer;
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s ease;
    z-index: 1000;
    font-size: 1.2rem;
    box-shadow: 0 4px 15px rgba(139, 21, 56, 0.4);
`;

document.body.appendChild(backToTopBtn);

window.addEventListener('scroll', () => {
    if (window.scrollY > 300) {
        backToTopBtn.style.opacity = '1';
        backToTopBtn.style.visibility = 'visible';
    } else {
        backToTopBtn.style.opacity = '0';
        backToTopBtn.style.visibility = 'hidden';
    }
});

backToTopBtn.addEventListener('click', () => {
    window.scrollTo({
        top: 0,
        behavior: 'smooth'
    });
});

// Add hover effect to back to top button
backToTopBtn.addEventListener('mouseenter', () => {
    backToTopBtn.style.background = 'linear-gradient(135deg, #d4af37 0%, #b8860b 100%)';
    backToTopBtn.style.transform = 'scale(1.1)';
    backToTopBtn.style.color = '#8b1538';
});

backToTopBtn.addEventListener('mouseleave', () => {
    backToTopBtn.style.background = 'linear-gradient(135deg, #8b1538 0%, #a01e42 100%)';
    backToTopBtn.style.transform = 'scale(1)';
    backToTopBtn.style.color = 'white';
});

// Mobile-specific optimizations
// Add touch event listeners for better mobile experience
document.addEventListener('DOMContentLoaded', () => {
    // Add touch-friendly classes
    if ('ontouchstart' in window) {
        document.body.classList.add('touch-device');
    }

    // Optimize images for mobile
    const images = document.querySelectorAll('img');
    images.forEach(img => {
        img.loading = 'lazy';
        img.decoding = 'async';
    });

    // Add mobile-specific event listeners
    const cards = document.querySelectorAll('.feature-card, .destination-card');
    cards.forEach(card => {
        card.addEventListener('touchstart', (e) => {
            card.style.transform = 'scale(0.98)';
        });
        
        card.addEventListener('touchend', (e) => {
            setTimeout(() => {
                card.style.transform = '';
            }, 150);
        });
    });
});

// Performance optimization for mobile
let ticking = false;

function updateOnScroll() {
    // Throttle scroll events for better performance
    if (!ticking) {
        requestAnimationFrame(() => {
            // Scroll-based animations can go here
            ticking = false;
        });
        ticking = true;
    }
}

window.addEventListener('scroll', updateOnScroll, { passive: true });

// Console welcome message
console.log('%c🧵 Welcome to SareeSutra! 🧵', 'color: #a21caf; font-size: 20px; font-weight: bold;');
console.log('%cExplore sarees from every Indian state. 🇮🇳', 'color: #64748b; font-size: 14px;');

// State → Saree Data
const STATE_SAREE_DATA = {
    'Gujarat': { sarees: ['Patola', 'Bandhani'], materials: ['Silk', 'Cotton'], note: 'Double ikat Patola and tie-dye Bandhani' },
    'Maharashtra': { sarees: ['Paithani', 'Nauvari'], materials: ['Silk', 'Zari'], note: 'Handwoven Paithani with peacock motifs' },
    'Rajasthan': { sarees: ['Leheriya', 'Bandhej'], materials: ['Silk', 'Georgette'], note: 'Vibrant wave patterns of Leheriya' },
    'Punjab': { sarees: ['Phulkari'], materials: ['Cotton', 'Silk'], note: 'Floral embroidery work' },
    'Uttar Pradesh': { sarees: ['Banarasi'], materials: ['Silk', 'Zari'], note: 'Brocade with rich zari and meenakari' },
    'West Bengal': { sarees: ['Jamdani', 'Baluchari', 'Tant'], materials: ['Cotton', 'Silk'], note: 'Fine muslin Jamdani butis' },
    'Assam': { sarees: ['Muga', 'Eri'], materials: ['Muga Silk', 'Eri Silk'], note: 'Natural golden Muga sheen' },
    'Karnataka': { sarees: ['Mysore Silk', 'Ilkal'], materials: ['Silk', 'Cotton'], note: 'Pure silk with elegant drape' },
    'Kerala': { sarees: ['Kasavu'], materials: ['Cotton', 'Zari'], note: 'Ivory cotton with gold borders' },
    'Tamil Nadu': { sarees: ['Kanchipuram'], materials: ['Silk', 'Zari'], note: 'Temple borders and contrast pallus' },
    'Telangana': { sarees: ['Gadwal', 'Pochampally'], materials: ['Silk', 'Cotton'], note: 'Lightweight Gadwal, Ikat Pochampally' },
    'Andhra Pradesh': { sarees: ['Uppada', 'Mangalgiri'], materials: ['Silk', 'Cotton'], note: 'Jamdhani Uppada weaves' },
    'Odisha': { sarees: ['Sambalpuri Ikat', 'Bomkai'], materials: ['Cotton', 'Silk'], note: 'Geometric ikat patterns' },
    'Bihar': { sarees: ['Tussar', 'Bhagalpuri'], materials: ['Tussar Silk'], note: 'Textured wild silk elegance' },
    'Madhya Pradesh': { sarees: ['Chanderi', 'Maheshwari'], materials: ['Silk-Cotton'], note: 'Sheer, lightweight Chanderi' }
};

// Tooltip logic for map hotspots
document.addEventListener('DOMContentLoaded', () => {
    const tooltip = document.getElementById('mapTooltip');
    const hotspots = document.querySelectorAll('.state-hotspot');

    function showTooltip(evt, stateName) {
        const data = STATE_SAREE_DATA[stateName];
        if (!data) return;
        tooltip.innerHTML = `<strong>${stateName}</strong><br>Signature: ${data.sarees.join(', ')}<br>Materials: ${data.materials.join(', ')}<br><span style="opacity:.8">${data.note}</span>`;
        tooltip.style.display = 'block';
        tooltip.setAttribute('aria-hidden', 'false');
        positionTooltip(evt);
    }

    function hideTooltip() {
        tooltip.style.display = 'none';
        tooltip.setAttribute('aria-hidden', 'true');
    }

    function positionTooltip(evt) {
        const wrapper = document.querySelector('.map-wrapper');
        const rect = wrapper.getBoundingClientRect();
        const x = evt.clientX - rect.left;
        const y = evt.clientY - rect.top;
        tooltip.style.left = `${x}px`;
        tooltip.style.top = `${y}px`;
    }

    hotspots.forEach(h => {
        const stateName = h.getAttribute('data-state');
        h.addEventListener('mouseenter', (e) => showTooltip(e, stateName));
        h.addEventListener('mousemove', positionTooltip);
        h.addEventListener('mouseleave', hideTooltip);
        h.addEventListener('click', () => {
            // Scroll to collections and maybe filter in the future
            scrollToSection('collections');
        });
        // Touch support
        h.addEventListener('touchstart', (e) => {
            const touch = e.touches[0];
            showTooltip(touch, stateName);
        }, { passive: true });
        h.addEventListener('touchmove', (e) => {
            const touch = e.touches[0];
            positionTooltip(touch);
        }, { passive: true });
        h.addEventListener('touchend', hideTooltip, { passive: true });
    });

    // Load accurate states SVG if present
    const container = document.getElementById('indiaMapContainer');
    if (container) {
        fetch('assets/india-states.svg', { cache: 'no-store' })
            .then(r => r.ok ? r.text() : Promise.reject())
            .then(svg => {
                container.innerHTML = svg;
                // Expect each state path to have id or data-name
                const statePaths = container.querySelectorAll('path, polygon');
                statePaths.forEach(p => {
                    const name = p.getAttribute('data-name') || p.getAttribute('title') || p.id || 'State';
                    p.style.cursor = 'pointer';
                    p.style.transition = 'fill 0.15s ease, transform 0.15s ease';
                    p.addEventListener('mouseenter', (e) => {
                        p.dataset._origFill = p.getAttribute('fill') || '';
                        p.setAttribute('fill', '#fb7185');
                        showTooltip(e, name);
                    });
                    p.addEventListener('mousemove', positionTooltip);
                    p.addEventListener('mouseleave', () => {
                        if (p.dataset._origFill !== undefined) p.setAttribute('fill', p.dataset._origFill);
                        hideTooltip();
                    });
                    p.addEventListener('click', () => scrollToSection('collections'));
                    // Touch
                    p.addEventListener('touchstart', (e) => { const t = e.touches[0]; showTooltip(t, name); }, { passive: true });
                    p.addEventListener('touchmove', (e) => { const t = e.touches[0]; positionTooltip(t); }, { passive: true });
                    p.addEventListener('touchend', hideTooltip, { passive: true });
                });
            })
            .catch(() => {
                // leave fallback
            });
    }
});
