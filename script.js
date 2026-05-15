const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

document.addEventListener('DOMContentLoaded', () => {
    const navbar = document.querySelector('.navbar');
    const hamburger = document.querySelector('.hamburger');
    const navMenu = document.querySelector('.nav-menu');
    const navLinks = document.querySelectorAll('.nav-link');
    const currentYear = document.querySelector('#currentYear');

    if (currentYear) {
        currentYear.textContent = String(new Date().getFullYear());
    }

    const setMenuOpen = (open) => {
        if (!hamburger || !navMenu) return;
        hamburger.classList.toggle('active', open);
        navMenu.classList.toggle('active', open);
        hamburger.setAttribute('aria-expanded', String(open));
    };

    if (hamburger && navMenu) {
        hamburger.setAttribute('aria-label', 'Toggle navigation');
        hamburger.setAttribute('aria-expanded', 'false');
        hamburger.setAttribute('role', 'button');
        hamburger.setAttribute('tabindex', '0');

        hamburger.addEventListener('click', () => {
            setMenuOpen(!navMenu.classList.contains('active'));
        });

        hamburger.addEventListener('keydown', (event) => {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                setMenuOpen(!navMenu.classList.contains('active'));
            }
        });

        document.addEventListener('click', (event) => {
            if (!navMenu.contains(event.target) && !hamburger.contains(event.target)) {
                setMenuOpen(false);
            }
        });

        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') setMenuOpen(false);
        });
    }

    navLinks.forEach((link) => {
        link.addEventListener('click', () => setMenuOpen(false));
    });

    document.querySelectorAll('a[href^="#"]').forEach((link) => {
        link.addEventListener('click', (event) => {
            const targetId = link.getAttribute('href');
            if (!targetId || targetId === '#') return;

            const target = document.querySelector(targetId);
            if (!target) return;

            event.preventDefault();
            const navHeight = navbar?.offsetHeight || 0;
            const targetTop = target.getBoundingClientRect().top + window.scrollY - navHeight;
            window.scrollTo({
                top: targetTop,
                behavior: prefersReducedMotion ? 'auto' : 'smooth'
            });
        });
    });

    document.querySelectorAll('a[target="_blank"]').forEach((link) => {
        const rel = new Set((link.getAttribute('rel') || '').split(/\s+/).filter(Boolean));
        rel.add('noopener');
        rel.add('noreferrer');
        link.setAttribute('rel', Array.from(rel).join(' '));
    });

    const faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach((item) => {
        const question = item.querySelector('.faq-question');
        const answer = item.querySelector('.faq-answer');
        if (!question || !answer) return;

        question.setAttribute('role', 'button');
        question.setAttribute('tabindex', '0');
        question.setAttribute('aria-expanded', 'false');

        const toggleItem = () => {
            const isOpening = !item.classList.contains('active');

            faqItems.forEach((otherItem) => {
                const otherQuestion = otherItem.querySelector('.faq-question');
                const otherAnswer = otherItem.querySelector('.faq-answer');
                otherItem.classList.remove('active');
                if (otherQuestion) otherQuestion.setAttribute('aria-expanded', 'false');
                if (otherAnswer) otherAnswer.style.maxHeight = '0';
            });

            if (isOpening) {
                item.classList.add('active');
                question.setAttribute('aria-expanded', 'true');
                answer.style.maxHeight = `${answer.scrollHeight}px`;
            }
        };

        question.addEventListener('click', toggleItem);
        question.addEventListener('keydown', (event) => {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                toggleItem();
            }
        });
    });

    if (navbar) {
        const updateNavbar = () => {
            navbar.classList.toggle('is-scrolled', window.scrollY > 50);
        };
        updateNavbar();
        window.addEventListener('scroll', updateNavbar, { passive: true });
    }

    if ('IntersectionObserver' in window && !prefersReducedMotion) {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach((entry) => {
                if (!entry.isIntersecting) return;
                entry.target.classList.add('is-visible');
                observer.unobserve(entry.target);
            });
        }, { threshold: 0.12, rootMargin: '0px 0px -50px 0px' });

        document.querySelectorAll('.feature-card, .screenshot-item, .section-header').forEach((element) => {
            element.classList.add('reveal');
            observer.observe(element);
        });
    }
});
