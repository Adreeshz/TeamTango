// Authentication and Role Management for Frontend
// This module handles user authentication, role management, and UI updates

// Configuration
const API_BASE_URL = 'http://localhost:5000/api';

// Authentication State Management
class AuthManager {
    constructor() {
        this.currentUser = null;
        this.token = localStorage.getItem('authToken') || null;
        this.init();
    }

    // Initialize authentication state on page load
    async init() {
        if (this.token) {
            try {
                await this.validateToken();
            } catch (error) {
                console.log('Invalid token, clearing auth state');
                this.logout();
            }
        }
        this.updateUI();
    }

    // Validate stored token and get user info
    async validateToken() {
        const response = await fetch(`${API_BASE_URL}/auth/profile`, {
            headers: {
                'Authorization': `Bearer ${this.token}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Token validation failed');
        }

        const data = await response.json();
        this.currentUser = data.user;
        return data.user;
    }

    // Login with email and password
    async login(email, password) {
        try {
            const response = await fetch(`${API_BASE_URL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ email, password })
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.message || 'Login failed');
            }

            // Store authentication data
            this.token = data.token;
            this.currentUser = data.user;
            localStorage.setItem('authToken', this.token);

            this.updateUI();
            return data;

        } catch (error) {
            console.error('Login error:', error);
            throw error;
        }
    }

    // Register new user
    async register(userData) {
        try {
            const response = await fetch(`${API_BASE_URL}/auth/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(userData)
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.message || 'Registration failed');
            }

            return data;

        } catch (error) {
            console.error('Registration error:', error);
            throw error;
        }
    }

    // Logout user
    logout() {
        this.token = null;
        this.currentUser = null;
        localStorage.removeItem('authToken');
        this.updateUI();
        
        // Redirect to home page
        if (window.location.pathname !== '/index.html' && window.location.pathname !== '/') {
            window.location.href = '/index.html';
        }
    }

    // Check if user is logged in
    isAuthenticated() {
        return this.token && this.currentUser;
    }

    // Get current user info
    getCurrentUser() {
        return this.currentUser;
    }

    // Check if user has specific role
    hasRole(role) {
        if (!this.currentUser) return false;
        
        const userRole = this.currentUser.userType || this.currentUser.role?.toLowerCase();
        return userRole === role.toLowerCase();
    }

    // Check if user is a player
    isPlayer() {
        return this.hasRole('player');
    }

    // Check if user is a venue owner
    isVenueOwner() {
        return this.hasRole('venue_owner');
    }

    // Check if user is an admin
    isAdmin() {
        return this.hasRole('admin');
    }

    // Get authorization header for API calls
    getAuthHeader() {
        return this.token ? { 'Authorization': `Bearer ${this.token}` } : {};
    }

    // Update UI based on authentication state and role
    updateUI() {
        this.updateNavigation();
        this.updateUserMenu();
        this.updateRoleSpecificContent();
    }

    // Update navigation menu based on user role
    updateNavigation() {
        const navContainer = document.getElementById('main-nav');
        if (!navContainer) return;

        let navItems = '';

        if (this.isAuthenticated()) {
            // Common navigation for all authenticated users
            navItems += `
                <a href="index.html" class="border-primary-500 text-gray-900 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Home</a>
                <a href="#sports" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Sports</a>
                <a href="venues.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Venues</a>
            `;

            if (this.isPlayer()) {
                navItems += `
                    <a href="teams.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Teams</a>
                    <a href="player-dashboard.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">My Dashboard</a>
                    <a href="payments.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Payments</a>
                `;
            } else if (this.isVenueOwner()) {
                navItems += `
                    <a href="venue-owner-dashboard.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">My Dashboard</a>
                    <a href="payments.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Payments</a>
                `;
            } else if (this.isAdmin()) {
                navItems += `
                    <a href="admin-dashboard.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Admin Dashboard</a>
                    <a href="payments.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Payments</a>
                `;
            }
        } else {
            // Navigation for non-authenticated users
            navItems += `
                <a href="index.html" class="border-primary-500 text-gray-900 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Home</a>
                <a href="#sports" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Sports</a>
                <a href="venues.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Venues</a>
                <a href="teams.html" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Teams</a>
            `;
        }

        navContainer.innerHTML = navItems;
    }

    // Update user menu based on authentication state
    updateUserMenu() {
        const authButtons = document.getElementById('auth-buttons');
        const userMenu = document.getElementById('user-menu-container');
        
        if (!authButtons) return;

        if (this.isAuthenticated()) {
            // Show user menu, hide auth buttons
            authButtons.style.display = 'none';
            
            if (userMenu) {
                userMenu.style.display = 'flex';
                userMenu.innerHTML = `
                    <div class="flex items-center space-x-4">
                        <div class="flex items-center space-x-2">
                            <img class="h-8 w-8 rounded-full" src="images/user.png" alt="Profile">
                            <div class="hidden md:block">
                                <div class="text-sm font-medium text-gray-700">${this.currentUser.name}</div>
                                <div class="text-xs text-gray-500 capitalize">${this.currentUser.userType || this.currentUser.role}</div>
                            </div>
                        </div>
                        <div class="relative">
                            <button type="button" class="bg-white rounded-md p-2 text-gray-400 hover:text-gray-500 focus:outline-none" onclick="auth.toggleUserDropdown()">
                                <i data-feather="chevron-down" class="h-4 w-4"></i>
                            </button>
                            <div id="user-dropdown" class="hidden absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
                                <a href="profile.html" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                    <i data-feather="user" class="h-4 w-4 inline mr-2"></i>Profile
                                </a>
                                <a href="settings.html" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                    <i data-feather="settings" class="h-4 w-4 inline mr-2"></i>Settings
                                </a>
                                <button onclick="auth.logout()" class="w-full text-left block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                    <i data-feather="log-out" class="h-4 w-4 inline mr-2"></i>Sign out
                                </button>
                            </div>
                        </div>
                    </div>
                `;
                
                // Re-initialize feather icons
                if (typeof feather !== 'undefined') {
                    feather.replace();
                }
            }
        } else {
            // Show auth buttons, hide user menu
            authButtons.style.display = 'flex';
            if (userMenu) {
                userMenu.style.display = 'none';
            }
        }
    }

    // Toggle user dropdown menu
    toggleUserDropdown() {
        const dropdown = document.getElementById('user-dropdown');
        if (dropdown) {
            dropdown.classList.toggle('hidden');
        }
    }

    // Update role-specific content
    updateRoleSpecificContent() {
        // Hide/show role-specific sections
        const playerSections = document.querySelectorAll('.player-only');
        const venueOwnerSections = document.querySelectorAll('.venue-owner-only');
        const adminSections = document.querySelectorAll('.admin-only');
        const authenticatedSections = document.querySelectorAll('.authenticated-only');
        const unauthenticatedSections = document.querySelectorAll('.unauthenticated-only');

        // Show/hide based on authentication
        authenticatedSections.forEach(section => {
            section.style.display = this.isAuthenticated() ? 'block' : 'none';
        });

        unauthenticatedSections.forEach(section => {
            section.style.display = this.isAuthenticated() ? 'none' : 'block';
        });

        // Show/hide based on roles
        playerSections.forEach(section => {
            section.style.display = this.isPlayer() ? 'block' : 'none';
        });

        venueOwnerSections.forEach(section => {
            section.style.display = this.isVenueOwner() ? 'block' : 'none';
        });

        adminSections.forEach(section => {
            section.style.display = this.isAdmin() ? 'block' : 'none';
        });
    }

    // Show role-specific welcome message
    updateWelcomeMessage() {
        const welcomeContainer = document.getElementById('role-welcome');
        if (!welcomeContainer || !this.isAuthenticated()) return;

        let welcomeMessage = '';
        const userName = this.currentUser.name;

        if (this.isPlayer()) {
            welcomeMessage = `
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
                    <h3 class="text-lg font-medium text-blue-900">Welcome back, ${userName}!</h3>
                    <p class="text-blue-700">Ready to find your next game? Browse teams, book venues, and connect with other players.</p>
                    <div class="mt-3 flex space-x-3">
                        <a href="teams.html" class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm font-medium rounded-md text-blue-700 bg-blue-100 hover:bg-blue-200">
                            Find Teams
                        </a>
                        <a href="venues.html" class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm font-medium rounded-md text-blue-700 bg-blue-100 hover:bg-blue-200">
                            Book Venues
                        </a>
                    </div>
                </div>
            `;
        } else if (this.isVenueOwner()) {
            welcomeMessage = `
                <div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
                    <h3 class="text-lg font-medium text-green-900">Welcome back, ${userName}!</h3>
                    <p class="text-green-700">Manage your venues, track bookings, and grow your sports business.</p>
                    <div class="mt-3 flex space-x-3">
                        <a href="venue-owner-dashboard.html" class="inline-flex items-center px-3 py-2 border border-green-300 text-sm font-medium rounded-md text-green-700 bg-green-100 hover:bg-green-200">
                            My Dashboard
                        </a>
                        <a href="venues.html" class="inline-flex items-center px-3 py-2 border border-green-300 text-sm font-medium rounded-md text-green-700 bg-green-100 hover:bg-green-200">
                            Manage Venues
                        </a>
                    </div>
                </div>
            `;
        } else if (this.isAdmin()) {
            welcomeMessage = `
                <div class="bg-purple-50 border border-purple-200 rounded-lg p-4 mb-6">
                    <h3 class="text-lg font-medium text-purple-900">Welcome back, ${userName}!</h3>
                    <p class="text-purple-700">Monitor the platform, manage users, and oversee all operations.</p>
                    <div class="mt-3 flex space-x-3">
                        <a href="admin-dashboard.html" class="inline-flex items-center px-3 py-2 border border-purple-300 text-sm font-medium rounded-md text-purple-700 bg-purple-100 hover:bg-purple-200">
                            Admin Dashboard
                        </a>
                        <a href="venues.html" class="inline-flex items-center px-3 py-2 border border-purple-300 text-sm font-medium rounded-md text-purple-700 bg-purple-100 hover:bg-purple-200">
                            Manage System
                        </a>
                    </div>
                </div>
            `;
        }

        welcomeContainer.innerHTML = welcomeMessage;
    }

    // API Helper Methods
    async apiRequest(endpoint, options = {}) {
        const url = `${API_BASE_URL}${endpoint}`;
        const headers = {
            'Content-Type': 'application/json',
            ...this.getAuthHeader(),
            ...options.headers
        };

        const response = await fetch(url, {
            ...options,
            headers
        });

        if (response.status === 401) {
            // Token expired or invalid
            this.logout();
            throw new Error('Session expired. Please log in again.');
        }

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || 'Request failed');
        }

        return data;
    }

    // Redirect to appropriate dashboard based on role
    redirectToDashboard() {
        if (this.isPlayer()) {
            window.location.href = 'player-dashboard.html';
        } else if (this.isVenueOwner()) {
            window.location.href = 'venue-owner-dashboard.html';
        } else if (this.isAdmin()) {
            window.location.href = 'admin-dashboard.html';
        } else {
            window.location.href = 'index.html';
        }
    }

    // Check if user should have access to current page
    checkPageAccess() {
        const path = window.location.pathname;
        const filename = path.split('/').pop();

        // Define page access rules
        const playerPages = ['player-dashboard.html'];
        const venueOwnerPages = ['venue-owner-dashboard.html'];
        const adminPages = ['admin-dashboard.html'];
        const authRequiredPages = [...playerPages, ...venueOwnerPages, ...adminPages, 'profile.html', 'settings.html'];

        // Check if authentication is required
        if (authRequiredPages.includes(filename) && !this.isAuthenticated()) {
            window.location.href = 'login.html';
            return false;
        }

        // Check role-specific access
        if (playerPages.includes(filename) && !this.isPlayer()) {
            this.redirectToDashboard();
            return false;
        }

        if (venueOwnerPages.includes(filename) && !this.isVenueOwner()) {
            this.redirectToDashboard();
            return false;
        }

        if (adminPages.includes(filename) && !this.isAdmin()) {
            this.redirectToDashboard();
            return false;
        }

        return true;
    }
}

// Global authentication manager instance
const auth = new AuthManager();

// Utility functions for external use
window.auth = auth;

// Close dropdown when clicking outside
document.addEventListener('click', (event) => {
    const dropdown = document.getElementById('user-dropdown');
    const button = event.target.closest('button');
    
    if (dropdown && !dropdown.contains(event.target) && !button) {
        dropdown.classList.add('hidden');
    }
});

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    auth.updateWelcomeMessage();
    auth.checkPageAccess();
});