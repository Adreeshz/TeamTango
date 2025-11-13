# 🏏 TeamTango - Sports Venue Booking Platform

A comprehensive sports venue booking and team management system built for the Indian market, specifically designed for Pune-based sports facilities.

## 📋 Project Overview

TeamTango is a full-stack web application that enables users to discover, book, and manage sports venues. The platform supports team creation, match scheduling, payment processing, and provides comprehensive analytics for sports facility management with role-based access for Players, Venue Owners, and Administrators.

## ✨ Key Features

### 🎯 Core Functionality
- **Venue Discovery** - Browse and filter sports venues by sport, location, and price
- **Team Management** - Create and manage sports teams with member roles
- **Booking System** - Real-time venue booking with time slot management
- **Match Scheduling** - Organize matches between teams with automated notifications
- **Payment Integration** - Secure payment processing for bookings
- **Analytics Dashboard** - Comprehensive reporting and insights for all user roles

### 🇮🇳 India-Specific Features
- **Localized Pricing** - ₹100-150/hour rates suitable for Indian market
- **Pune Venues** - Real venues like Shivaji University, Deccan Gymkhana, MCA Grounds
- **IST Time Slots** - Indian Standard Time scheduling (6 AM - 8 PM)
- **Popular Sports** - Cricket, Football, Badminton, Basketball, Tennis

## 🛠️ Technology Stack

### Backend
- **Node.js** with Express.js framework
- **MySQL** database with comprehensive schema
- **JWT Authentication** with bcrypt password hashing
- **RESTful API** design with proper error handling

### Frontend  
- **Vanilla JavaScript** with modern ES6+ features
- **Tailwind CSS** for responsive UI design
- **Feather Icons** for consistent iconography

### Database Features
- **15 Normalized Tables** - Users, Venues, Teams, Bookings, Matches, Payments, etc.
- **Stored Procedures** - Automated booking and payment processing  
- **Database Triggers** - Validation, notifications, and audit logging
- **Database Views** - Analytics and reporting queries
- **Foreign Key Constraints** - Data integrity and referential consistency

## 🚀 Quick Start

### Prerequisites
- Node.js (v14+)
- MySQL (v8+)
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/Adreeshz/TeamTango.git
cd TeamTango
```

2. **Install dependencies**
```bash
cd playo-backend
npm install
```

3. **Set up MySQL database**
```bash
mysql -u root -p
CREATE DATABASE dbms_cp;
```

4. **Import database schema**
```bash
mysql -u root -p dbms_cp < database/01_schema_ddl.sql
mysql -u root -p dbms_cp < database/02_sample_data.sql
```

5. **Configure database connection**
```javascript
// Update playo-backend/utils/db.js with your credentials
const db = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: 'your_password',
    database: 'dbms_cp'
});
```

6. **Start the application**
```bash
cd playo-backend
node server.js
```

7. **Access the application**
- Open browser to `http://localhost:5000`
- Use demo credentials: `user1@player.com` / `password123`

## 👥 Demo Accounts

| Email | Password | Role |
|-------|----------|------|
| user1@player.com | password123 | Player |
| user2@player.com | password123 | Player |
| admin@teamtango.com | admin123 | Admin |

## 📊 Database Schema

The application uses a normalized MySQL database with the following key tables:

- **Users** - User profiles with authentication
- **Venues** - Sports facility information
- **Teams** - Team management with member roles  
- **Bookings** - Venue reservations and scheduling
- **Matches** - Inter-team competitions
- **Payments** - Transaction records and billing
- **Sports** - Supported sports categories
- **Notifications** - User communication system

## 🎯 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Venues
- `GET /api/venues` - List all venues
- `GET /api/venues/:id` - Get venue details
- `POST /api/venues/create` - Create new venue

### Bookings
- `GET /api/bookings` - List user bookings
- `POST /api/bookings/create` - Create new booking
- `PUT /api/bookings/update/:id` - Update booking

### Teams
- `GET /api/teams` - List user teams
- `POST /api/teams/create` - Create new team
- `POST /api/team-members/add` - Add team member

## 🔒 Security Features

- Password hashing using bcrypt with salt rounds
- JWT-based authentication with token expiration
- Role-based access control for different user types
- Input validation and sanitization
- SQL injection prevention through parameterized queries

## 📄 License

This project is developed for educational purposes as part of academic coursework.