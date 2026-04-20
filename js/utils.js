// utils.js

/**
 * Format price in USD or HTG
 */
export const formatPrice = (amount, currency = 'USD') => {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency,
    }).format(amount);
};

/**
 * Show a toast notification
 */
export const showToast = (message, type = 'info') => {
    const container = document.querySelector('.toast-container') || createToastContainer();
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;

    let icon = 'info';
    if (type === 'success') icon = 'check-circle-2';
    if (type === 'error') icon = 'x-circle';
    if (type === 'warning') icon = 'alert-triangle';

    toast.innerHTML = `
        <i data-lucide="${icon}"></i>
        <span>${message}</span>
    `;

    container.appendChild(toast);
    if (typeof lucide !== 'undefined') lucide.createIcons();

    // Elegant exit animation
    setTimeout(() => {
        toast.style.animation = 'none';
        toast.style.transform = 'translateX(120%) scale(0.8)';
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 400);
    }, 4000);
};

const createToastContainer = () => {
    const container = document.createElement('div');
    container.className = 'toast-container';
    document.body.appendChild(container);
    return container;
};

/**
 * Debounce function
 */
export const debounce = (func, wait) => {
    let timeout;
    return (...args) => {
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(this, args), wait);
    };
};
