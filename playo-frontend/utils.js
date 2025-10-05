// TeamTango Utility Functions
class TeamTangoUtils {
    static API_BASE_URL = 'http://localhost:5000/api';

    // Show toast notification
    static showToast(message, type = 'info', duration = 3000) {
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.textContent = message;
        
        document.body.appendChild(toast);
        
        setTimeout(() => {
            toast.style.animation = 'slideOutRight 0.3s ease-out';
            setTimeout(() => {
                document.body.removeChild(toast);
            }, 300);
        }, duration);
    }

    // Format date
    static formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }

    // Format time
    static formatTime(timeString) {
        const [hours, minutes] = timeString.split(':');
        const hour = parseInt(hours);
        const ampm = hour >= 12 ? 'PM' : 'AM';
        const displayHour = hour % 12 || 12;
        return `${displayHour}:${minutes} ${ampm}`;
    }

    // Format currency in INR
    static formatCurrency(amount) {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    }

    // Format Indian number system (with commas)
    static formatIndianNumber(number) {
        return new Intl.NumberFormat('en-IN').format(number);
    }

    // Validate email
    static isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    // Validate phone number
    static isValidPhone(phone) {
        const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
        return phoneRegex.test(phone.replace(/\s/g, ''));
    }

    // Generate random ID
    static generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }

    // Debounce function
    static debounce(func, wait, immediate) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                timeout = null;
                if (!immediate) func(...args);
            };
            const callNow = immediate && !timeout;
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
            if (callNow) func(...args);
        };
    }

    // Local Storage helpers
    static setStorage(key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
        } catch (error) {
            console.error('Error saving to localStorage:', error);
        }
    }

    static getStorage(key) {
        try {
            const item = localStorage.getItem(key);
            return item ? JSON.parse(item) : null;
        } catch (error) {
            console.error('Error reading from localStorage:', error);
            return null;
        }
    }

    static removeStorage(key) {
        try {
            localStorage.removeItem(key);
        } catch (error) {
            console.error('Error removing from localStorage:', error);
        }
    }

    // API helper functions
    static async apiGet(endpoint) {
        try {
            const response = await fetch(`${this.API_BASE_URL}${endpoint}`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error('API GET error:', error);
            throw error;
        }
    }

    static async apiPost(endpoint, data) {
        try {
            const response = await fetch(`${this.API_BASE_URL}${endpoint}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error('API POST error:', error);
            throw error;
        }
    }

    static async apiPut(endpoint, data) {
        try {
            const response = await fetch(`${this.API_BASE_URL}${endpoint}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error('API PUT error:', error);
            throw error;
        }
    }

    static async apiDelete(endpoint) {
        try {
            const response = await fetch(`${this.API_BASE_URL}${endpoint}`, {
                method: 'DELETE'
            });
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error('API DELETE error:', error);
            throw error;
        }
    }

    // Loading spinner
    static showLoading(element) {
        element.innerHTML = '<div class="spinner mx-auto"></div>';
    }

    static hideLoading(element, content) {
        element.innerHTML = content;
    }

    // Confirm dialog
    static confirm(message, onConfirm, onCancel) {
        if (window.confirm(message)) {
            if (onConfirm) onConfirm();
        } else {
            if (onCancel) onCancel();
        }
    }

    // Get current user (mock implementation)
    static getCurrentUser() {
        return this.getStorage('currentUser') || {
            id: 1,
            name: 'John Doe',
            email: 'john@example.com',
            avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face'
        };
    }

    // Set current user
    static setCurrentUser(user) {
        this.setStorage('currentUser', user);
    }

    // Check if user is logged in
    static isLoggedIn() {
        return !!this.getCurrentUser();
    }

    // Initialize feather icons
    static initFeatherIcons() {
        if (typeof feather !== 'undefined') {
            feather.replace();
        }
    }

    // Initialize tooltips (if using a tooltip library)
    static initTooltips() {
        // Placeholder for tooltip initialization
        console.log('Tooltips initialized');
    }

    // Handle form submission with loading state
    static async handleFormSubmit(form, submitHandler) {
        const submitBtn = form.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;
        
        try {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<div class="spinner mr-2"></div>Processing...';
            
            await submitHandler();
            
            this.showToast('Operation completed successfully!', 'success');
        } catch (error) {
            console.error('Form submission error:', error);
            this.showToast('An error occurred. Please try again.', 'error');
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
        }
    }

    // Initialize common page functionality
    static initPage() {
        this.initFeatherIcons();
        this.initTooltips();
        
        // Add smooth scrolling to all anchor links
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

        // Add fade-in animation to cards
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('fade-in');
                }
            });
        }, observerOptions);

        document.querySelectorAll('.card-hover, .fade-on-scroll').forEach(el => {
            observer.observe(el);
        });
    }
}

// Sample data for development/demo
const SampleData = {
    sports: [
        { SportID: 1, SportName: "Football" },
        { SportID: 2, SportName: "Basketball" },
        { SportID: 3, SportName: "Tennis" },
        { SportID: 4, SportName: "Badminton" },
        { SportID: 5, SportName: "Cricket" },
        { SportID: 6, SportName: "Volleyball" }
    ],
    
    teams: [
        {
            TeamID: 1,
            TeamName: "Thunder Bolts",
            Sport: "Basketball",
            Description: "Competitive basketball team",
            MemberCount: 12,
            CreatedDate: "2024-01-15"
        },
        {
            TeamID: 2,
            TeamName: "Lightning Eagles",
            Sport: "Football", 
            Description: "Amateur football enthusiasts",
            MemberCount: 18,
            CreatedDate: "2024-02-10"
        },
        {
            TeamID: 3,
            TeamName: "Court Warriors",
            Sport: "Tennis",
            Description: "Tennis doubles team",
            MemberCount: 4,
            CreatedDate: "2024-03-05"
        }
    ],
    
    venues: [
        {
            VenueID: 1,
            VenueName: "Shree Shiv Chhatrapati Sports Complex",
            Location: "Balewadi, Pune",
            PricePerHour: 120,
            SportType: "Basketball",
            Description: "Modern indoor basketball court with professional lighting and air conditioning",
            Rating: 4.8,
            Image: "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=400&h=300&fit=crop&crop=center"
        },
        {
            VenueID: 2,
            VenueName: "Cooperage Football Ground",
            Location: "Pune University, Pune",
            PricePerHour: 150,
            SportType: "Football",
            Description: "Full-size football field with natural grass, floodlights available",
            Rating: 4.6,
            Image: "https://images.unsplash.com/photo-1579952363873-27d3bfad9c0d?w=400&h=300&fit=crop&crop=center"
        },
        {
            VenueID: 3,
            VenueName: "Deccan Gymkhana Tennis Courts",
            Location: "Deccan Gymkhana, Pune",
            PricePerHour: 130,
            SportType: "Tennis",
            Description: "Premium tennis courts with synthetic surface and coaching available",
            Rating: 4.9,
            Image: "https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400&h=300&fit=crop&crop=center"
        }
    ]
};

// Initialize on DOM load
document.addEventListener('DOMContentLoaded', () => {
    TeamTangoUtils.initPage();
});

// Export for use in other files
window.TeamTangoUtils = TeamTangoUtils;
window.SampleData = SampleData;