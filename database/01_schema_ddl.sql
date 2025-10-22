
-- Create database if not exists
CREATE DATABASE IF NOT EXISTS dbms_cp;

USE dbms_cp;

-- Disable foreign key checks for clean recreation
SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables in correct order (to handle dependencies)
DROP TABLE IF EXISTS AuditLog;
DROP TABLE IF EXISTS Notifications;
DROP TABLE IF EXISTS Feedback;
DROP TABLE IF EXISTS Matches;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Bookings;
DROP TABLE IF EXISTS Timeslots;
DROP TABLE IF EXISTS TeamMembers;
DROP TABLE IF EXISTS Teams;
DROP TABLE IF EXISTS Venues;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS UserPermissions;
DROP TABLE IF EXISTS Sports;
DROP TABLE IF EXISTS Roles;

-- ================================================
-- 1. ROLES TABLE - User Classification System
-- ================================================
CREATE TABLE Roles (
    RoleID INT PRIMARY KEY AUTO_INCREMENT,
    RoleName VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT NOT NULL,
    
    -- Constraints
    CONSTRAINT chk_roles_name_length CHECK (CHAR_LENGTH(RoleName) >= 3)
);

-- ================================================
-- 2. SPORTS TABLE - Sports Categories
-- ================================================
CREATE TABLE Sports (
    SportID INT PRIMARY KEY AUTO_INCREMENT,
    SportName VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT,
    Category ENUM('Indoor', 'Outdoor', 'Both') DEFAULT 'Both'
);

-- ================================================
-- 3. USER PERMISSIONS TABLE - Role-Based Access Control
-- ================================================
CREATE TABLE UserPermissions (
    PermissionID INT PRIMARY KEY AUTO_INCREMENT,
    RoleID INT NOT NULL,
    TableName VARCHAR(100) NOT NULL,
    CanCreate BOOLEAN DEFAULT FALSE,
    CanRead BOOLEAN DEFAULT FALSE,
    CanUpdate BOOLEAN DEFAULT FALSE,
    CanDelete BOOLEAN DEFAULT FALSE,
    
    -- Foreign Keys
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE,
    
    -- Unique constraints
    UNIQUE KEY uk_role_table (RoleID, TableName)
);

-- ================================================
-- 4. USERS TABLE - User Management System
-- ================================================
CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    Gender ENUM('Male', 'Female', 'Other') NOT NULL,
    Password VARCHAR(255) NOT NULL,
    PhoneNumber VARCHAR(15) NOT NULL,
    Address VARCHAR(255) NOT NULL,
    RoleID INT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON UPDATE CASCADE ON DELETE RESTRICT,
    
    -- Constraints
    CONSTRAINT chk_users_name_length CHECK (CHAR_LENGTH(Name) >= 2),
    CONSTRAINT chk_users_phone_format CHECK (PhoneNumber REGEXP '^[0-9]{10}$')
);

-- ================================================
-- 5. VENUES TABLE - Sports Venue Management
-- ================================================
CREATE TABLE Venues (
    VenueID INT PRIMARY KEY AUTO_INCREMENT,
    VenueName VARCHAR(200) NOT NULL,
    Location VARCHAR(200) NOT NULL,
    City VARCHAR(100) DEFAULT 'Pune',
    ContactNumber VARCHAR(15) NOT NULL,
    OwnerID INT NOT NULL,
    PricePerHour DECIMAL(10,2) NOT NULL,
    SportID INT,
    
    -- Foreign Keys
    FOREIGN KEY (OwnerID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (SportID) REFERENCES Sports(SportID) ON UPDATE CASCADE ON DELETE SET NULL,
    
    -- Constraints
    CONSTRAINT chk_venues_price CHECK (PricePerHour >= 0)
);

-- ================================================
-- 6. TEAMS TABLE - Team Management
-- ================================================
CREATE TABLE Teams (
    TeamID INT PRIMARY KEY AUTO_INCREMENT,
    TeamName VARCHAR(150) NOT NULL,
    SportID INT NOT NULL,
    CaptainID INT NOT NULL,
    
    -- Foreign Keys
    FOREIGN KEY (SportID) REFERENCES Sports(SportID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (CaptainID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ================================================
-- 7. TEAM MEMBERS TABLE - Team Membership Management
-- ================================================
CREATE TABLE TeamMembers (
    MemberID INT PRIMARY KEY AUTO_INCREMENT,
    TeamID INT NOT NULL,
    UserID INT NOT NULL,
    JoinedDate DATE DEFAULT (CURDATE()),
    
    -- Foreign Keys
    FOREIGN KEY (TeamID) REFERENCES Teams(TeamID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    
    -- Unique constraints
    UNIQUE KEY uk_team_user (TeamID, UserID)
);

-- ================================================
-- 8. TIMESLOTS TABLE - Venue Availability Management
-- ================================================
CREATE TABLE Timeslots (
    TimeslotID INT PRIMARY KEY AUTO_INCREMENT,
    VenueID INT NOT NULL,
    SlotDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    PriceINR DECIMAL(10,2) NOT NULL,
    IsAvailable BOOLEAN DEFAULT TRUE,
    
    -- Foreign Keys
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON DELETE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_ts_times CHECK (StartTime < EndTime),
    
    -- Unique constraints
    UNIQUE KEY uk_venue_datetime (VenueID, SlotDate, StartTime, EndTime)
);

-- ================================================
-- 9. BOOKINGS TABLE - Venue Booking Management
-- ================================================
CREATE TABLE Bookings (
    BookingID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    VenueID INT NOT NULL,
    TimeslotID INT NOT NULL,
    BookingDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    BookingStatus ENUM('Pending', 'Confirmed', 'Cancelled') DEFAULT 'Pending',
    
    -- Foreign Keys
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (TimeslotID) REFERENCES Timeslots(TimeslotID) ON UPDATE CASCADE ON DELETE RESTRICT,
    
    -- Constraints
    CONSTRAINT chk_bookings_amount CHECK (TotalAmount >= 0)
);

-- ================================================
-- 10. PAYMENTS TABLE - Payment Processing System
-- ================================================
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT,
    BookingID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod ENUM('Cash', 'Card', 'UPI') NOT NULL,
    PaymentStatus ENUM('Pending', 'Success', 'Failed') DEFAULT 'Pending',
    PaymentDate DATE NOT NULL,
    
    -- Foreign Keys
    FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID) ON DELETE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_payments_amount CHECK (Amount > 0)
);

-- ================================================
-- 11. MATCHES TABLE - Match Management (Simplified)
-- ================================================
CREATE TABLE Matches (
    MatchID INT PRIMARY KEY AUTO_INCREMENT,
    MatchTitle VARCHAR(200) NOT NULL,
    Team1ID INT NOT NULL,
    Team2ID INT NOT NULL,
    VenueID INT NOT NULL,
    MatchDate DATE NOT NULL,
    MatchTime TIME NOT NULL,
    Team1Score INT DEFAULT 0,
    Team2Score INT DEFAULT 0,
    MatchStatus ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    FOREIGN KEY (Team1ID) REFERENCES Teams(TeamID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (Team2ID) REFERENCES Teams(TeamID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON UPDATE CASCADE ON DELETE RESTRICT,
    
    -- Constraints
    CONSTRAINT chk_matches_score CHECK (Team1Score >= 0 AND Team2Score >= 0),
    
    -- Indexes
    INDEX idx_matches_team1 (Team1ID),
    INDEX idx_matches_team2 (Team2ID),
    INDEX idx_matches_venue (VenueID),
    INDEX idx_matches_date (MatchDate),
    INDEX idx_matches_status (MatchStatus)
);

-- ================================================
-- 12. FEEDBACK TABLE - Venue Reviews
-- ================================================
CREATE TABLE Feedback (
    FeedbackID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    VenueID INT NOT NULL,
    Rating INT NOT NULL,
    Comment TEXT,
    
    -- Foreign Keys
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON DELETE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_feedback_rating CHECK (Rating >= 1 AND Rating <= 5)
);

-- ================================================
-- 13. NOTIFICATIONS TABLE - User Notifications
-- ================================================
CREATE TABLE Notifications (
    NotificationID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    Message TEXT NOT NULL,
    IsRead BOOLEAN DEFAULT FALSE,
    
    -- Foreign Keys
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

-- ================================================
-- 14. AUDIT LOG TABLE - System Activity Tracking
-- ================================================
CREATE TABLE AuditLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    Action VARCHAR(100) NOT NULL,
    TableName VARCHAR(100),
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL
);

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ================================================
-- INITIAL DATA INSERTION
-- ================================================

-- Insert default roles
INSERT INTO Roles (RoleID, RoleName, Description) VALUES
(1, 'Player', 'Regular sports players who can join teams, make bookings, and participate in matches'),
(2, 'Venue Owner', 'Venue owners who can list and manage sports venues, view bookings, and manage timeslots'),
(3, 'Admin', 'System administrators with full access to all features and user management');

-- Insert popular sports (original 6 sports)
INSERT INTO Sports (SportName, Description, Category) VALUES
('Football', 'Association football with growing popularity in urban India', 'Outdoor'),
('Basketball', 'Popular team sport especially in urban areas and schools', 'Both'),
('Tennis', 'Classic racquet sport for singles and doubles matches', 'Both'),
('Badminton', 'Popular indoor racquet sport played in singles or doubles', 'Indoor'),
('Cricket', 'The most popular sport in India with various formats like T20, ODI, and Test', 'Outdoor'),
('Volleyball', 'Team sport popular in schools and communities', 'Both');

-- Insert default permissions for each role
INSERT INTO UserPermissions (RoleID, TableName, CanCreate, CanRead, CanUpdate, CanDelete) VALUES
-- Player permissions
(1, 'Users', FALSE, TRUE, TRUE, FALSE),
(1, 'Teams', TRUE, TRUE, TRUE, FALSE),
(1, 'TeamMembers', TRUE, TRUE, TRUE, TRUE),
(1, 'Bookings', TRUE, TRUE, TRUE, TRUE),
(1, 'Payments', TRUE, TRUE, FALSE, FALSE),
(1, 'Feedback', TRUE, TRUE, TRUE, TRUE),
(1, 'Venues', FALSE, TRUE, FALSE, FALSE),

-- Venue Owner permissions
(2, 'Users', FALSE, TRUE, TRUE, FALSE),
(2, 'Venues', TRUE, TRUE, TRUE, TRUE),
(2, 'Timeslots', TRUE, TRUE, TRUE, TRUE),
(2, 'Bookings', FALSE, TRUE, TRUE, FALSE),
(2, 'Payments', FALSE, TRUE, FALSE, FALSE),
(2, 'Feedback', FALSE, TRUE, TRUE, FALSE),

-- Admin permissions (full access)
(3, 'Users', TRUE, TRUE, TRUE, TRUE),
(3, 'Roles', TRUE, TRUE, TRUE, TRUE),
(3, 'Sports', TRUE, TRUE, TRUE, TRUE),
(3, 'Venues', TRUE, TRUE, TRUE, TRUE),
(3, 'Teams', TRUE, TRUE, TRUE, TRUE),
(3, 'TeamMembers', TRUE, TRUE, TRUE, TRUE),
(3, 'Bookings', TRUE, TRUE, TRUE, TRUE),
(3, 'Payments', TRUE, TRUE, TRUE, TRUE),
(3, 'Matches', TRUE, TRUE, TRUE, TRUE),
(3, 'Feedback', TRUE, TRUE, TRUE, TRUE),
(3, 'Notifications', TRUE, TRUE, TRUE, TRUE),
(3, 'AuditLog', FALSE, TRUE, FALSE, FALSE);

-- Success message
SELECT 'Student-friendly database schema created successfully!' as Status,
       'Clean 14-table structure perfect for beginners and ER diagrams' as Message,
       'Essential DBMS concepts with beginner-friendly complexity' as NextStep;