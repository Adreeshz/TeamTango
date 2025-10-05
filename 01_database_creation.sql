-- ================================================
-- TeamTango Database Creation Script
-- Purpose: Create the complete database structure for TeamTango Pune
-- Date: October 5, 2025
-- Usage: mysql -u root -p < 01_database_creation.sql
-- ================================================

-- Drop database if exists (CAUTION: This will delete all data)
-- DROP DATABASE IF EXISTS dbms_cp;

-- Create database
CREATE DATABASE IF NOT EXISTS dbms_cp;
USE dbms_cp;

-- Set character set and collation for proper Indian language support
ALTER DATABASE dbms_cp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ================================================
-- 1. CORE TABLES
-- ================================================

-- Roles Table (Must be created first due to foreign key constraints)
CREATE TABLE IF NOT EXISTS Roles (
    RoleID INT PRIMARY KEY AUTO_INCREMENT,
    RoleName VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users Table
CREATE TABLE IF NOT EXISTS Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Gender ENUM('Male', 'Female', 'Other'),
    Password VARCHAR(255) NOT NULL,
    PhoneNumber VARCHAR(15),
    Address TEXT,
    RoleID INT DEFAULT 1,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE SET NULL,
    INDEX idx_users_email (Email),
    INDEX idx_users_role (RoleID),
    INDEX idx_users_phone (PhoneNumber)
);

-- Sports Table
CREATE TABLE IF NOT EXISTS Sports (
    SportID INT PRIMARY KEY AUTO_INCREMENT,
    SportName VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT,
    MinPlayers INT DEFAULT 1,
    MaxPlayers INT DEFAULT 22,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sports_name (SportName)
);

-- Venues Table
CREATE TABLE IF NOT EXISTS Venues (
    VenueID INT PRIMARY KEY AUTO_INCREMENT,
    VenueName VARCHAR(200) NOT NULL,
    Location VARCHAR(200) NOT NULL,
    Address TEXT,
    City VARCHAR(100) DEFAULT 'Pune',
    State VARCHAR(100) DEFAULT 'Maharashtra',
    PinCode VARCHAR(10),
    ContactNumber VARCHAR(15),
    OwnerID INT,
    Capacity INT DEFAULT 0,
    PricePerHour DECIMAL(10,2) DEFAULT 0.00,
    Amenities TEXT,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (OwnerID) REFERENCES Users(UserID) ON DELETE SET NULL,
    INDEX idx_venues_location (Location),
    INDEX idx_venues_owner (OwnerID),
    INDEX idx_venues_active (IsActive),
    INDEX idx_venues_city (City)
);

-- Teams Table
CREATE TABLE IF NOT EXISTS Teams (
    TeamID INT PRIMARY KEY AUTO_INCREMENT,
    TeamName VARCHAR(100) NOT NULL,
    SportID INT,
    CaptainID INT,
    Description TEXT,
    HomeLocation VARCHAR(200),
    MaxMembers INT DEFAULT 15,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (SportID) REFERENCES Sports(SportID) ON DELETE SET NULL,
    FOREIGN KEY (CaptainID) REFERENCES Users(UserID) ON DELETE SET NULL,
    INDEX idx_teams_sport (SportID),
    INDEX idx_teams_captain (CaptainID),
    INDEX idx_teams_active (IsActive),
    UNIQUE KEY unique_team_name_sport (TeamName, SportID)
);

-- Team Members Table
CREATE TABLE IF NOT EXISTS TeamMembers (
    MemberID INT PRIMARY KEY AUTO_INCREMENT,
    TeamID INT,
    UserID INT,
    Position VARCHAR(50),
    JoinedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (TeamID) REFERENCES Teams(TeamID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    INDEX idx_teammembers_team (TeamID),
    INDEX idx_teammembers_user (UserID),
    INDEX idx_teammembers_active (IsActive),
    UNIQUE KEY unique_team_user (TeamID, UserID)
);

-- Timeslots Table
CREATE TABLE IF NOT EXISTS Timeslots (
    TimeslotID INT PRIMARY KEY AUTO_INCREMENT,
    VenueID INT,
    SlotDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    IsAvailable BOOLEAN DEFAULT TRUE,
    PriceINR DECIMAL(10,2) DEFAULT 0.00,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON DELETE CASCADE,
    INDEX idx_timeslots_venue (VenueID),
    INDEX idx_timeslots_date (SlotDate),
    INDEX idx_timeslots_available (IsAvailable),
    UNIQUE KEY unique_venue_datetime (VenueID, SlotDate, StartTime, EndTime)
);

-- Bookings Table
CREATE TABLE IF NOT EXISTS Bookings (
    BookingID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    VenueID INT,
    TimeslotID INT,
    BookingDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    TotalAmount DECIMAL(10,2) DEFAULT 0.00,
    Status ENUM('Pending', 'Confirmed', 'Cancelled', 'Completed') DEFAULT 'Pending',
    BookingNotes TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL,
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON DELETE SET NULL,
    FOREIGN KEY (TimeslotID) REFERENCES Timeslots(TimeslotID) ON DELETE SET NULL,
    INDEX idx_bookings_user (UserID),
    INDEX idx_bookings_venue (VenueID),
    INDEX idx_bookings_date (BookingDate),
    INDEX idx_bookings_status (Status),
    INDEX idx_bookings_timeslot (TimeslotID)
);

-- Payments Table
CREATE TABLE IF NOT EXISTS Payments (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT,
    BookingID INT,
    UserID INT,
    Amount DECIMAL(10,2) NOT NULL,
    Currency VARCHAR(3) DEFAULT 'INR',
    PaymentMethod ENUM('Cash', 'Card', 'UPI', 'Net Banking', 'Wallet') DEFAULT 'UPI',
    TransactionID VARCHAR(100),
    PaymentStatus ENUM('Pending', 'Success', 'Failed', 'Refunded') DEFAULT 'Pending',
    PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID) ON DELETE SET NULL,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL,
    INDEX idx_payments_booking (BookingID),
    INDEX idx_payments_user (UserID),
    INDEX idx_payments_status (PaymentStatus),
    INDEX idx_payments_date (PaymentDate),
    INDEX idx_payments_transaction (TransactionID)
);

-- Matches Table
CREATE TABLE IF NOT EXISTS Matches (
    MatchID INT PRIMARY KEY AUTO_INCREMENT,
    Team1ID INT,
    Team2ID INT,
    VenueID INT,
    MatchDate DATE NOT NULL,
    MatchTime TIME NOT NULL,
    SportID INT,
    Team1Score INT DEFAULT 0,
    Team2Score INT DEFAULT 0,
    WinnerTeamID INT,
    Status ENUM('Scheduled', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Scheduled',
    CreatedByUserID INT,
    MatchNotes TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (Team1ID) REFERENCES Teams(TeamID) ON DELETE SET NULL,
    FOREIGN KEY (Team2ID) REFERENCES Teams(TeamID) ON DELETE SET NULL,
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON DELETE SET NULL,
    FOREIGN KEY (SportID) REFERENCES Sports(SportID) ON DELETE SET NULL,
    FOREIGN KEY (WinnerTeamID) REFERENCES Teams(TeamID) ON DELETE SET NULL,
    FOREIGN KEY (CreatedByUserID) REFERENCES Users(UserID) ON DELETE SET NULL,
    INDEX idx_matches_date (MatchDate),
    INDEX idx_matches_venue (VenueID),
    INDEX idx_matches_sport (SportID),
    INDEX idx_matches_status (Status),
    INDEX idx_matches_teams (Team1ID, Team2ID)
);

-- Feedback Table
CREATE TABLE IF NOT EXISTS Feedback (
    FeedbackID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    VenueID INT,
    Rating INT CHECK (Rating >= 1 AND Rating <= 5),
    Comments TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL,
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON DELETE CASCADE,
    INDEX idx_feedback_venue (VenueID),
    INDEX idx_feedback_user (UserID),
    INDEX idx_feedback_rating (Rating),
    UNIQUE KEY unique_user_venue_feedback (UserID, VenueID)
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS Notifications (
    NotificationID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    Title VARCHAR(200) NOT NULL,
    Message TEXT,
    Type ENUM('Info', 'Success', 'Warning', 'Error') DEFAULT 'Info',
    IsRead BOOLEAN DEFAULT FALSE,
    RelatedEntityType VARCHAR(50), -- 'booking', 'match', 'team', etc.
    RelatedEntityID INT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ReadAt TIMESTAMP NULL,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    INDEX idx_notifications_user (UserID),
    INDEX idx_notifications_read (IsRead),
    INDEX idx_notifications_type (Type),
    INDEX idx_notifications_created (CreatedAt)
);

-- ================================================
-- 2. ADDITIONAL PERFORMANCE INDEXES
-- ================================================

-- Composite indexes for common queries
CREATE INDEX idx_bookings_user_date ON Bookings(UserID, BookingDate);
CREATE INDEX idx_venues_city_active ON Venues(City, IsActive);
CREATE INDEX idx_teams_sport_active ON Teams(SportID, IsActive);
CREATE INDEX idx_matches_date_venue ON Matches(MatchDate, VenueID);

-- ================================================
-- 3. DATABASE SETTINGS FOR INDIAN CONTEXT
-- ================================================

-- Set timezone to Indian Standard Time
SET time_zone = '+05:30';

-- Create database info table for versioning
CREATE TABLE IF NOT EXISTS DatabaseInfo (
    InfoID INT PRIMARY KEY AUTO_INCREMENT,
    DatabaseVersion VARCHAR(20) DEFAULT '1.0',
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    Description TEXT
);

INSERT IGNORE INTO DatabaseInfo (DatabaseVersion, Description) VALUES 
('1.0', 'Initial TeamTango Pune database structure with user classification system');

-- ================================================
-- SUCCESS MESSAGE
-- ================================================

SELECT 'TeamTango Database Created Successfully!' as Status,
       'Database: dbms_cp' as DatabaseName,
       '12 Tables Created' as TablesCount,
       'Pune Sports Management System' as Purpose,
       'Ready for Data Insertion' as NextStep;