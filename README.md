# 🏏 TeamTango - Sports Venue Booking Platform

A comprehensive sports venue booking and team management system built for the Indian market, specifically designed for Pune-based sports facilities.

## 📋 Project Overview

TeamTango is a full-stack web application that enables users to discover, book, and manage sports venues across Pune. The platform supports team creation, match scheduling, and provides analytics for sports facility management.

## ✨ Key Features

### 🎯 Core Functionality
- **Venue Discovery** - Browse and filter sports venues by sport, location, and price
- **Team Management** - Create and manage sports teams with member roles
- **Booking System** - Real-time venue booking with time slot management
- **Match Scheduling** - Organize matches between teams with automated notifications
- **Payment Integration** - Secure payment processing for bookings
- **Analytics Dashboard** - Comprehensive reporting and insights

### 🇮🇳 India-Specific Features
- **Localized Pricing** - Affordable ₹100-150/hour rates suitable for Indian market
- **Pune Venues** - Real venues like Shivaji University, Deccan Gymkhana, MCA Grounds
- **IST Time Slots** - Indian Standard Time scheduling (6 AM - 8 PM)
- **Popular Sports** - Cricket, Football, Badminton, Basketball prioritized
- **Regional Teams** - Pune Warriors, Maratha Mavericks, Sahyadri Strikers

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
- **Progressive Enhancement** with fallback data

### Database Features
- **15 Normalized Tables** - Users, Venues, Teams, Bookings, etc.
- **Stored Procedures** - Automated booking and payment processing  
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
git clone https://github.com/yourusername/teamtango-sports-booking.git
cd teamtango-sports-booking
```

2. **Install dependencies**
```bash
cd playo-backend
npm install
```

3. **Set up MySQL database**
```bash
# Create database
mysql -u root -p
CREATE DATABASE dbms_cp;
```

4. **Import database schema**
```bash
# Run the SQL files in order:
mysql -u root -p dbms_cp < 01_create_tables.sql
mysql -u root -p dbms_cp < 02_insert_sample_data.sql  
mysql -u root -p dbms_cp < 03_create_views.sql
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

## 📈 Analytics Views

Pre-built database views for reporting:
- **user_profile_view** - Complete user information
- **venue_details_view** - Venue statistics and ratings
- **booking_summary_view** - Booking analytics by date/venue
- **team_performance_view** - Team statistics and match history
- **popular_sports_view** - Sport popularity rankings
- **revenue_analytics_view** - Financial reporting
- **monthly_bookings_view** - Booking trends analysis

## 🖼️ Screenshots

The application features a modern, responsive design with:
- Clean venue browsing interface
- Interactive booking modal
- Team management dashboard  
- Analytics and reporting views
- Mobile-responsive design

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for DBMS Course Project
- Inspired by Indian sports booking needs
- Uses real Pune venue locations
- Designed for college and recreational sports

## 📞 Contact

For questions or support, please open an issue on GitHub or contact [your-email@example.com].

---
**Made with ❤️ for the Indian Sports Community** 🏏🇮🇳