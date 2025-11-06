/**
 * XSearch Logo Rotator
 * Randomly displays one of the available colored logos
 */

(function() {
    'use strict';

    // Available logo variants (without .svg extension)
    const logoVariants = [
        'xsearch-blue',
        'xsearch-green',
        'xsearch-orange',
        'xsearch-purple',
        'xsearch-red'
    ];

    /**
     * Get random logo variant
     */
    function getRandomLogo() {
        const randomIndex = Math.floor(Math.random() * logoVariants.length);
        return logoVariants[randomIndex];
    }

    /**
     * Set logo on page load
     */
    function setRandomLogo() {
        const logoImg = document.querySelector('.index-logo');

        if (!logoImg) {
            return; // Not on index page
        }

        const selectedLogo = getRandomLogo();
        const logoPath = `/static/themes/simple/img/${selectedLogo}.svg`;

        // Set the logo
        logoImg.src = logoPath;
        logoImg.setAttribute('data-logo-variant', selectedLogo);

        // Optional: Store selection in sessionStorage to keep same logo during session
        try {
            sessionStorage.setItem('xsearch-logo', selectedLogo);
        } catch (e) {
            // SessionStorage not available, that's ok
        }

        console.log('XSearch: Using logo variant:', selectedLogo);
    }

    /**
     * Get consistent logo for session (optional)
     * If you want same logo during entire session, use this
     */
    function getSessionLogo() {
        try {
            const stored = sessionStorage.getItem('xsearch-logo');
            if (stored && logoVariants.includes(stored)) {
                return stored;
            }
        } catch (e) {
            // SessionStorage not available
        }
        return getRandomLogo();
    }

    /**
     * Initialize on DOM ready
     */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setRandomLogo);
    } else {
        setRandomLogo();
    }

})();
