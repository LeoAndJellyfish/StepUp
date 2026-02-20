// Version configuration - Update this when pubspec.yaml changes
const APP_VERSION = '3.1.2';

document.addEventListener('DOMContentLoaded', function() {
    updateVersionDisplay();
    initParticles();
    initMobileNav();
    initScrollEffects();
    initAnimations();
    initInteractions();
    initConsoleEasterEgg();
});

function updateVersionDisplay() {
    const versionDisplay = document.getElementById('version-display');
    const appVersions = document.querySelectorAll('.app-version');
    
    if (versionDisplay) {
        versionDisplay.textContent = 'v' + APP_VERSION;
    }
    
    appVersions.forEach(el => {
        el.textContent = '版本 ' + APP_VERSION;
    });
}

function initParticles() {
    const canvas = document.getElementById('particles');
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    let particles = [];
    let animationId;
    
    function resize() {
        canvas.width = canvas.offsetWidth;
        canvas.height = canvas.offsetHeight;
    }
    
    function createParticle() {
        return {
            x: Math.random() * canvas.width,
            y: Math.random() * canvas.height,
            size: Math.random() * 2 + 0.5,
            speedX: (Math.random() - 0.5) * 0.5,
            speedY: (Math.random() - 0.5) * 0.5,
            opacity: Math.random() * 0.5 + 0.2,
            hue: Math.random() * 60 + 220
        };
    }
    
    function init() {
        resize();
        particles = [];
        const particleCount = Math.min(80, Math.floor((canvas.width * canvas.height) / 15000));
        for (let i = 0; i < particleCount; i++) {
            particles.push(createParticle());
        }
    }
    
    function drawParticle(p) {
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fillStyle = `hsla(${p.hue}, 70%, 60%, ${p.opacity})`;
        ctx.fill();
    }
    
    function connectParticles() {
        for (let i = 0; i < particles.length; i++) {
            for (let j = i + 1; j < particles.length; j++) {
                const dx = particles[i].x - particles[j].x;
                const dy = particles[i].y - particles[j].y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                if (distance < 120) {
                    const opacity = (1 - distance / 120) * 0.15;
                    ctx.beginPath();
                    ctx.moveTo(particles[i].x, particles[i].y);
                    ctx.lineTo(particles[j].x, particles[j].y);
                    ctx.strokeStyle = `rgba(99, 102, 241, ${opacity})`;
                    ctx.lineWidth = 0.5;
                    ctx.stroke();
                }
            }
        }
    }
    
    function animate() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        particles.forEach(p => {
            p.x += p.speedX;
            p.y += p.speedY;
            
            if (p.x < 0 || p.x > canvas.width) p.speedX *= -1;
            if (p.y < 0 || p.y > canvas.height) p.speedY *= -1;
            
            drawParticle(p);
        });
        
        connectParticles();
        animationId = requestAnimationFrame(animate);
    }
    
    init();
    animate();
    
    window.addEventListener('resize', () => {
        cancelAnimationFrame(animationId);
        init();
        animate();
    });
    
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        cancelAnimationFrame(animationId);
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        particles.forEach(drawParticle);
    }
}

function initMobileNav() {
    const hamburger = document.querySelector('.hamburger');
    const navMenu = document.querySelector('.nav-menu');
    const navLinks = document.querySelectorAll('.nav-link');

    hamburger.addEventListener('click', function() {
        hamburger.classList.toggle('active');
        navMenu.classList.toggle('active');
    });

    navLinks.forEach(link => {
        link.addEventListener('click', function() {
            hamburger.classList.remove('active');
            navMenu.classList.remove('active');
        });
    });
}

function initScrollEffects() {
    const navbar = document.querySelector('.navbar');
    let lastScroll = 0;
    let ticking = false;

    function updateNavbar() {
        const currentScroll = window.pageYOffset;
        
        if (currentScroll > 50) {
            navbar.style.background = 'rgba(255, 255, 255, 0.98)';
            navbar.style.boxShadow = '6px 6px 0px #1A1A2E';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 1)';
            navbar.style.boxShadow = 'none';
        }

        lastScroll = currentScroll;
        ticking = false;
    }

    window.addEventListener('scroll', function() {
        if (!ticking) {
            requestAnimationFrame(updateNavbar);
            ticking = true;
        }
    });

    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                const offsetTop = target.offsetTop - 80;
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });
}

function initAnimations() {
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                setTimeout(() => {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }, index * 50);
            }
        });
    }, observerOptions);

    const animatedElements = document.querySelectorAll('.feature-card, .download-card, .tech-item');
    animatedElements.forEach((el, index) => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(40px)';
        el.style.transition = `opacity 0.6s cubic-bezier(0.34, 1.56, 0.64, 1) ${index * 0.05}s, transform 0.6s cubic-bezier(0.34, 1.56, 0.64, 1) ${index * 0.05}s`;
        observer.observe(el);
    });

    const progressBar = document.querySelector('.bar-fill');
    if (progressBar) {
        setTimeout(() => {
            progressBar.style.width = '75%';
        }, 800);
    }
}

function initInteractions() {
    const mockupCards = document.querySelectorAll('.mockup-card');
    mockupCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateX(8px) scale(1.02)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateX(0) scale(1)';
        });
    });

    const orbs = document.querySelectorAll('.gradient-orb');
    
    if (!window.matchMedia('(pointer: coarse)').matches && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        document.addEventListener('mousemove', function(e) {
            const mouseX = e.clientX / window.innerWidth;
            const mouseY = e.clientY / window.innerHeight;

            orbs.forEach((orb, index) => {
                const speed = (index + 1) * 15;
                const x = (mouseX - 0.5) * speed;
                const y = (mouseY - 0.5) * speed;
                
                orb.style.transform = `translate(${x}px, ${y}px)`;
            });
        });
    }

    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(button => {
        button.addEventListener('click', function(e) {
            const ripple = document.createElement('span');
            ripple.style.cssText = `
                position: absolute;
                width: 20px;
                height: 20px;
                background: rgba(255, 255, 255, 0.5);
                border-radius: 50%;
                transform: translate(-50%, -50%);
                pointer-events: none;
                animation: ripple 0.6s ease-out;
            `;
            
            const rect = this.getBoundingClientRect();
            ripple.style.left = (e.clientX - rect.left) + 'px';
            ripple.style.top = (e.clientY - rect.top) + 'px';
            
            this.style.position = 'relative';
            this.style.overflow = 'hidden';
            this.appendChild(ripple);
            
            setTimeout(() => ripple.remove(), 600);
        });
    });

    const style = document.createElement('style');
    style.textContent = `
        @keyframes ripple {
            to {
                width: 200px;
                height: 200px;
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(style);

    const heroTitle = document.querySelector('.hero-title');
    if (heroTitle && !window.matchMedia('(pointer: coarse)').matches) {
        heroTitle.addEventListener('mouseenter', function() {
            this.style.textShadow = '0 0 60px rgba(99, 102, 241, 0.5)';
        });
        
        heroTitle.addEventListener('mouseleave', function() {
            this.style.textShadow = 'none';
        });
    }

    const featureCards = document.querySelectorAll('.feature-card');
    featureCards.forEach(card => {
        card.addEventListener('mousemove', function(e) {
            const rect = this.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            const centerX = rect.width / 2;
            const centerY = rect.height / 2;
            
            const rotateX = (y - centerY) / 20;
            const rotateY = (centerX - x) / 20;
            
            this.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-8px)`;
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) translateY(0)';
        });
    });
}

function initConsoleEasterEgg() {
    console.log('%c StepUp ', 'background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; font-size: 24px; font-weight: bold; padding: 10px 20px; border-radius: 8px;');
    console.log('%c 让综测管理更简单 🎓 ', 'color: #6366f1; font-size: 14px;');
    console.log('%c 访问我们的 Gitee 仓库: https://gitee.com/LeoAndJellyfish/StepUp ', 'color: #22c55e; font-size: 12px;');
}

const debounce = (func, wait) => {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
};

const optimizedScrollHandler = debounce(() => {
}, 16);

window.addEventListener('scroll', optimizedScrollHandler);

function preloadResources() {
    const criticalResources = [];
    
    criticalResources.forEach(src => {
        const link = document.createElement('link');
        link.rel = 'preload';
        link.href = src;
        link.as = src.match(/\.(woff2?|ttf)$/) ? 'font' : 'image';
        if (link.as === 'font') {
            link.crossOrigin = 'anonymous';
        }
        document.head.appendChild(link);
    });
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', preloadResources);
} else {
    preloadResources();
}
