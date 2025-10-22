# TeamTango - Sports Management Platform# 🏏 TeamTango - Sports Venue Booking Platform



A comprehensive web-based sports facility management system that enables seamless booking, team management, and venue operations for sports facilities and players.A comprehensive sports venue booking and team management system built for the Indian market, specifically designed for Pune-based sports facilities.



## Overview## 📋 Project Overview



TeamTango is a full-stack web application designed to streamline sports facility management. The platform provides role-based access for three distinct user types: players who can book venues and manage teams, venue owners who can manage their facilities and track revenue, and administrators who oversee the entire system.TeamTango is a full-stack web application that enables users to discover, book, and manage sports venues across Pune. The platform supports team creation, match scheduling, and provides analytics for sports facility management.



## Features## ✨ Key Features



### Player Dashboard### 🎯 Core Functionality

- User registration and authentication- **Venue Discovery** - Browse and filter sports venues by sport, location, and price

- Browse and book available sports venues- **Team Management** - Create and manage sports teams with member roles

- Create and manage teams- **Booking System** - Real-time venue booking with time slot management

- Schedule matches between teams- **Match Scheduling** - Organize matches between teams with automated notifications

- View booking history and upcoming matches- **Payment Integration** - Secure payment processing for bookings

- Process payments for bookings- **Analytics Dashboard** - Comprehensive reporting and insights



### Venue Owner Dashboard### 🇮🇳 India-Specific Features

- Manage venue information and availability- **Localized Pricing** - Affordable ₹100-150/hour rates suitable for Indian market

- Set pricing and time slots- **Pune Venues** - Real venues like Shivaji University, Deccan Gymkhana, MCA Grounds

- Track bookings and revenue analytics- **IST Time Slots** - Indian Standard Time scheduling (6 AM - 8 PM)

- View venue utilization statistics- **Popular Sports** - Cricket, Football, Badminton, Basketball prioritized

- Manage venue-specific sports offerings- **Regional Teams** - Pune Warriors, Maratha Mavericks, Sahyadri Strikers



### Admin Dashboard## 🛠️ Technology Stack

- Comprehensive system oversight

- User account management### Backend

- Venue approval and monitoring- **Node.js** with Express.js framework

- System-wide analytics and reporting- **MySQL** database with comprehensive schema

- Role and permission management- **JWT Authentication** with bcrypt password hashing

- **RESTful API** design with proper error handling

### Core Functionality

- Real-time venue availability checking### Frontend  

- Secure payment processing- **Vanilla JavaScript** with modern ES6+ features

- Match scheduling with conflict detection- **Tailwind CSS** for responsive UI design

- Team member management- **Feather Icons** for consistent iconography

- Notification system for bookings and updates- **Progressive Enhancement** with fallback data

- Revenue tracking and financial reporting

### Database Features

## Technology Stack- **15 Normalized Tables** - Users, Venues, Teams, Bookings, etc.

- **Stored Procedures** - Automated booking and payment processing  

### Backend- **Database Views** - Analytics and reporting queries

- **Runtime:** Node.js- **Foreign Key Constraints** - Data integrity and referential consistency

- **Framework:** Express.js

- **Database:** MySQL with connection pooling## 🚀 Quick Start

- **Authentication:** JSON Web Tokens (JWT) with bcrypt hashing

- **API Architecture:** RESTful endpoints with middleware validation### Prerequisites

- Node.js (v14+)

### Frontend- MySQL (v8+)

- **Languages:** HTML5, CSS3, JavaScript (ES6+)- Git

- **Styling:** Custom CSS with responsive design

- **Architecture:** Multi-page application with dynamic content loading### Installation

- **Authentication:** Token-based session management

1. **Clone the repository**

### Database Design```bash

- Relational database with proper foreign key constraintsgit clone https://github.com/yourusername/teamtango-sports-booking.git

- Triggers for automated data validationcd teamtango-sports-booking

- Stored procedures for complex operations```

- Views for optimized data retrieval

- Comprehensive indexing for performance2. **Install dependencies**

```bash

## Project Structurecd playo-backend

npm install

``````

TeamTango/

├── playo-backend/3. **Set up MySQL database**

│   ├── server.js              # Main server entry point```bash

│   ├── package.json           # Dependencies and scripts# Create database

│   ├── routes/               # API route handlersmysql -u root -p

│   │   ├── users.js          # User managementCREATE DATABASE dbms_cp;

│   │   ├── venues.js         # Venue operations```

│   │   ├── bookings.js       # Booking system

│   │   ├── teams.js          # Team management4. **Import database schema**

│   │   ├── matches.js        # Match scheduling```bash

│   │   ├── payments.js       # Payment processing# Run the SQL files in order:

│   │   └── sports.js         # Sports managementmysql -u root -p dbms_cp < 01_create_tables.sql

│   └── utils/mysql -u root -p dbms_cp < 02_insert_sample_data.sql  

│       └── db.js             # Database connection and utilitiesmysql -u root -p dbms_cp < 03_create_views.sql

└── playo-frontend/```

    ├── index.html            # Landing page

    ├── login.html            # Authentication5. **Configure database connection**

    ├── dashboard.html        # Main dashboard router```javascript

    ├── player-dashboard.html # Player interface// Update playo-backend/utils/db.js with your credentials

    ├── venue-owner-dashboard.html # Venue owner interfaceconst db = mysql.createPool({

    ├── admin-dashboard.html  # Administrative interface    host: 'localhost',

    ├── matches.html          # Match management    user: 'root',

    ├── teams.html            # Team operations    password: 'your_password',

    ├── venues.html           # Venue browsing    database: 'dbms_cp'

    ├── payments.html         # Payment interface});

    ├── styles.css            # Application styling```

    ├── utils.js              # Frontend utilities

    └── js/6. **Start the application**

        └── auth.js           # Authentication logic```bash

```cd playo-backend

node server.js

## Database Schema```



### Core Tables7. **Access the application**

- **users**: User accounts with role-based permissions- Open browser to `http://localhost:5000`

- **venues**: Sports facility information and pricing- Use demo credentials: `user1@player.com` / `password123`

- **bookings**: Reservation system with conflict prevention

- **teams**: Team management with member associations## 👥 Demo Accounts

- **matches**: Match scheduling between teams

- **payments**: Financial transaction tracking| Email | Password | Role |

- **sports**: Available sports and categories|-------|----------|------|

| user1@player.com | password123 | Player |

### Key Relationships| user2@player.com | password123 | Player |

- Users can have multiple bookings and team memberships| admin@teamtango.com | admin123 | Admin |

- Venues support multiple sports with specific pricing

- Teams are associated with specific sports## 📊 Database Schema

- Matches link teams with venues and time slots

- Payments are connected to bookings for financial trackingThe application uses a normalized MySQL database with the following key tables:



## Installation and Setup- **Users** - User profiles with authentication

- **Venues** - Sports facility information

### Prerequisites- **Teams** - Team management with member roles  

- Node.js (version 14 or higher)- **Bookings** - Venue reservations and scheduling

- MySQL Server (version 8.0 or higher)- **Matches** - Inter-team competitions

- npm or yarn package manager- **Payments** - Transaction records and billing

- **Sports** - Supported sports categories

### Installation Steps- **Notifications** - User communication system



1. **Clone the repository**## 🎯 API Endpoints

   ```bash

   git clone https://github.com/Adreeshz/TeamTango.git### Authentication

   cd TeamTango- `POST /api/auth/login` - User login

   ```- `POST /api/auth/register` - User registration



2. **Install backend dependencies**### Venues

   ```bash- `GET /api/venues` - List all venues

   cd playo-backend- `GET /api/venues/:id` - Get venue details

   npm install- `POST /api/venues/create` - Create new venue

   ```

### Bookings

3. **Configure database connection**- `GET /api/bookings` - List user bookings

   - Update database credentials in `utils/db.js`- `POST /api/bookings/create` - Create new booking

   - Create MySQL database named `sports_booking`- `PUT /api/bookings/update/:id` - Update booking



4. **Initialize database schema**### Teams

   - Import the provided SQL schema file- `GET /api/teams` - List user teams

   - Run initial data population scripts if available- `POST /api/teams/create` - Create new team

- `POST /api/team-members/add` - Add team member

5. **Start the server**

   ```bash## 📈 Analytics Views

   npm start

   ```Pre-built database views for reporting:

- **user_profile_view** - Complete user information

6. **Access the application**- **venue_details_view** - Venue statistics and ratings

   - Open web browser and navigate to `http://localhost:3000`- **booking_summary_view** - Booking analytics by date/venue

   - Use the provided demo accounts or register new users- **team_performance_view** - Team statistics and match history

- **popular_sports_view** - Sport popularity rankings

## API Endpoints- **revenue_analytics_view** - Financial reporting

- **monthly_bookings_view** - Booking trends analysis

### Authentication

- `POST /api/users/register` - User registration## 🖼️ Screenshots

- `POST /api/users/login` - User authentication

- `GET /api/users/profile` - Get user profileThe application features a modern, responsive design with:

- Clean venue browsing interface

### Venues- Interactive booking modal

- `GET /api/venues` - List all venues- Team management dashboard  

- `POST /api/venues` - Create new venue (venue owners)- Analytics and reporting views

- `PUT /api/venues/:id` - Update venue information- Mobile-responsive design

- `GET /api/venues/:id/availability` - Check venue availability

## 🤝 Contributing

### Bookings

- `POST /api/bookings` - Create new booking1. Fork the repository

- `GET /api/bookings/user/:userId` - Get user bookings2. Create a feature branch (`git checkout -b feature/amazing-feature`)

- `PUT /api/bookings/:id/cancel` - Cancel booking3. Commit your changes (`git commit -m 'Add amazing feature'`)

4. Push to the branch (`git push origin feature/amazing-feature`)

### Teams and Matches5. Open a Pull Request

- `POST /api/teams` - Create team

- `GET /api/teams/user/:userId` - Get user teams## 📄 License

- `POST /api/matches` - Schedule match

- `GET /api/matches` - List matches with filtersThis project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.



## Security Features## 🙏 Acknowledgments



- Password hashing using bcrypt with salt rounds- Built for DBMS Course Project

- JWT-based authentication with token expiration- Inspired by Indian sports booking needs

- Role-based access control for different user types- Uses real Pune venue locations

- Input validation and sanitization- Designed for college and recreational sports

- SQL injection prevention through parameterized queries

- CORS configuration for secure cross-origin requests## 📞 Contact



## Performance OptimizationsFor questions or support, please open an issue on GitHub or contact [your-email@example.com].



- Database connection pooling for efficient resource usage---

- Indexed database columns for faster query execution**Made with ❤️ for the Indian Sports Community** 🏏🇮🇳
- Optimized SQL queries with proper JOIN operations
- Frontend caching strategies for static resources
- Asynchronous operations for non-blocking I/O

## Contributing

This project was developed as part of a Database Management Systems course project. The codebase follows standard web development practices and includes comprehensive error handling and validation.

## License

This project is developed for educational purposes as part of academic coursework.

## Authors

- **Adreesh** - Lead Developer and Database Designer

## Project Status

This is a completed academic project demonstrating full-stack web development skills with emphasis on database design and management. The application includes all core features for sports facility management and is ready for demonstration and evaluation.