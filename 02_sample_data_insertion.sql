-- ================================================
-- TeamTango Sample Data Insertion Script
-- Purpose: Insert comprehensive sample data for Pune-based sports management
-- Date: October 5, 2025
-- Usage: mysql -u root -p dbms_cp < 02_sample_data_insertion.sql
-- Prerequisite: Run 01_database_creation.sql first
-- ================================================

USE dbms_cp;

-- Disable foreign key checks for easier insertion
SET FOREIGN_KEY_CHECKS = 0;

-- ================================================
-- 1. ROLES DATA
-- ================================================

INSERT IGNORE INTO Roles (RoleID, RoleName, Description) VALUES 
(1, 'Player', 'Regular players who can join teams, make bookings, and participate in matches'),
(2, 'Venue Owner', 'Owners who can list and manage sports venues in Pune'),
(3, 'Admin', 'System administrators with full access (for future use)');

-- ================================================
-- 2. SPORTS DATA (Popular in Pune)
-- ================================================

INSERT IGNORE INTO Sports (SportID, SportName, Description, MinPlayers, MaxPlayers) VALUES 
(1, 'Cricket', 'The most popular sport in India with various formats', 11, 22),
(2, 'Football', 'Association football with growing popularity in Pune', 11, 22),
(3, 'Badminton', 'Popular indoor racquet sport', 1, 4),
(4, 'Tennis', 'Classic racquet sport for singles and doubles', 1, 4),
(5, 'Basketball', 'Popular team sport especially in urban areas', 5, 10),
(6, 'Volleyball', 'Team sport popular in schools and communities', 6, 12),
(7, 'Table Tennis', 'Indoor paddle sport', 1, 4),
(8, 'Kabaddi', 'Traditional Indian contact sport', 7, 14),
(9, 'Swimming', 'Individual and team aquatic sport', 1, 50),
(10, 'Cycling', 'Popular fitness and recreational activity', 1, 100);

-- ================================================
-- 3. USERS DATA (Pune-based)
-- ================================================

-- Sample Players (RoleID = 1)
INSERT IGNORE INTO Users (UserID, Name, Email, Gender, Password, PhoneNumber, Address, RoleID) VALUES 
(1, 'Rahul Sharma', 'rahul.player@gmail.com', 'Male', '$2b$10$Pupwre/dJCoSd0tXCxWp3.sKbod/LwkMQlYkFU3P7QcoJXhSc/w9C', '9876543210', 'Koregaon Park, Pune, Maharashtra 411001', 1),
(2, 'Priya Patel', 'priya.player@gmail.com', 'Female', '$2b$10$4SPnXLbsr7motXycF4L9m.ke9UJy/zt/U/Fg9CSuK/MZI4YQLuX3W', '9876543211', 'Baner, Pune, Maharashtra 411045', 1),
(3, 'Amit Kumar', 'amit.player@gmail.com', 'Male', '$2b$10$Te7v/.3U766NTRdnQMKaVOUxX58tyK5b4eTl1Z6QJzal3zBGHy3mK', '9876543212', 'Wakad, Pune, Maharashtra 411057', 1),
(4, 'Sneha Desai', 'sneha.player@gmail.com', 'Female', '$2b$10$pKu7C.gJOTX60m4Mxhp0besnOsAoPiJ/EOO65DEuUvG7PMrkOkgSm', '9876543213', 'Viman Nagar, Pune, Maharashtra 411014', 1),
(5, 'Vikram Joshi', 'vikram.player@gmail.com', 'Male', '$2b$10$kSd1ksdWl6VQ01KsadosX.tpxjkXKG3OLT6rrodxZuN5pR.3x1mtC', '9876543214', 'Aundh, Pune, Maharashtra 411007', 1),
(6, 'Kavya Nair', 'kavya.player@gmail.com', 'Female', '$2b$10$oNYrtfBuk2SP1E1ZU/OLue4iaO1P.dejPKw9qzEZtqlSTMF.tlXl6', '9876543215', 'Kothrud, Pune, Maharashtra 411038', 1),
(7, 'Arjun Patil', 'arjun.player@gmail.com', 'Male', '$2b$10$mJ38oGTXwHZfBOTDCwBTQeHUbxKkHWsGQTSM9eDX/GrK5sfqEJjLm', '9876543216', 'Deccan Gymkhana, Pune, Maharashtra 411004', 1),
(8, 'Ritu Singh', 'ritu.player@gmail.com', 'Female', '$2b$10$sL8uBbxT9tqtiLgLFcn8beDNVcNPUidatKkEny4sHtZpbZocNFAtG', '9876543217', 'Hadapsar, Pune, Maharashtra 411028', 1);

-- Sample Venue Owners (RoleID = 2)
INSERT IGNORE INTO Users (UserID, Name, Email, Gender, Password, PhoneNumber, Address, RoleID) VALUES 
(9, 'Suresh Venue Owner', 'suresh.venue@gmail.com', 'Male', '$2b$10$8bXIoelkWiaR3ewwpZLGYOCmpZ7ZsN30ugvf3mKrux/YLi3qUTeh6', '9876543218', 'Shivajinagar, Pune, Maharashtra 411005', 2),
(10, 'Meera Sports Complex', 'meera.venue@gmail.com', 'Female', '$2b$10$G7ti4ELbJUMQ5KarCVXoQ.M2BmvzWScF8/uJXTKlDB99FyYtrU8eq', '9876543219', 'Pune Camp, Pune, Maharashtra 411001', 2),
(11, 'Rajesh Grounds', 'rajesh.venue@gmail.com', 'Male', '$2b$10$5PXXBP/sYb7ciuzunQpfnOPp9Vp3NAzIjETjgbDRCuxEQ0IQDXGz6', '9876543220', 'Warje, Pune, Maharashtra 411052', 2),
(12, 'Pooja Recreation', 'pooja.venue@gmail.com', 'Female', '$2b$10$B8.LfksTwdGzOClEOhW3Y.eKj6NoiJ8PDBsWZw38TPARNZj7P6Wki', '9876543221', 'Hinjewadi, Pune, Maharashtra 411057', 2);

-- ================================================
-- 4. VENUES DATA (Pune Locations)
-- ================================================

INSERT IGNORE INTO Venues (VenueID, VenueName, Location, Address, ContactNumber, OwnerID, Capacity, PricePerHour, Amenities, IsActive) VALUES 
(1, 'Shivaji Park Cricket Ground', 'Shivajinagar', 'Near Shivaji Park, Shivajinagar, Pune 411005', '9876543218', 9, 50, 140.00, 'Cricket pitch, pavilion, parking, refreshments', TRUE),
(2, 'Deccan Badminton Academy', 'Deccan Gymkhana', 'FC Road, Deccan Gymkhana, Pune 411004', '9876543219', 10, 20, 100.00, '4 courts, AC, changing rooms, equipment rental', TRUE),
(3, 'Baner Football Turf', 'Baner', 'Baner Road, near Symbiosis, Pune 411045', '9876543220', 11, 22, 150.00, 'Artificial turf, floodlights, parking, canteen', TRUE),
(4, 'Aundh Sports Complex', 'Aundh', 'Aundh-Ravet Road, Aundh, Pune 411007', '9876543221', 12, 100, 120.00, 'Multi-sport facility, basketball, volleyball, tennis', TRUE),
(5, 'Koregaon Park Tennis Club', 'Koregaon Park', 'Lane 5, Koregaon Park, Pune 411001', '9876543218', 9, 16, 130.00, '4 tennis courts, pro shop, coaching available', TRUE),
(6, 'Wakad Swimming Pool', 'Wakad', 'Hinjewadi Road, Wakad, Pune 411057', '9876543219', 10, 30, 105.00, 'Olympic size pool, changing rooms, lockers', TRUE),
(7, 'Viman Nagar Basketball Court', 'Viman Nagar', 'Airport Road, Viman Nagar, Pune 411014', '9876543220', 11, 20, 110.00, 'Full court, scoreboard, seating area', TRUE),
(8, 'Kothrud Volleyball Ground', 'Kothrud', 'Karve Road, Kothrud, Pune 411038', '9876543221', 12, 30, 115.00, '2 courts, floodlights, equipment provided', TRUE);

-- ================================================
-- 5. TEAMS DATA
-- ================================================

INSERT IGNORE INTO Teams (TeamID, TeamName, SportID, CaptainID, Description, HomeLocation, MaxMembers, IsActive) VALUES 
(1, 'Pune Warriors Cricket', 1, 1, 'Competitive cricket team representing Pune in local tournaments', 'Koregaon Park', 15, TRUE),
(2, 'Baner United Football', 2, 3, 'Football club focusing on youth development in Baner area', 'Baner', 20, TRUE),
(3, 'Deccan Shuttlers', 3, 2, 'Badminton team for recreational and competitive players', 'Deccan Gymkhana', 8, TRUE),
(4, 'Aundh Aces Tennis', 4, 4, 'Tennis team for doubles and singles tournaments', 'Aundh', 12, TRUE),
(5, 'Wakad Hoops Basketball', 5, 5, 'Basketball team for local league competitions', 'Wakad', 15, TRUE),
(6, 'Viman Nagar Spikers', 6, 6, 'Volleyball team for recreational and competitive play', 'Viman Nagar', 12, TRUE);

-- ================================================
-- 6. TEAM MEMBERS DATA
-- ================================================

INSERT IGNORE INTO TeamMembers (TeamID, UserID, Position, IsActive) VALUES 
-- Pune Warriors Cricket (Team 1)
(1, 1, 'Captain', TRUE),
(1, 7, 'Batsman', TRUE),
(1, 8, 'Bowler', TRUE),

-- Baner United Football (Team 2)
(2, 3, 'Captain', TRUE),
(2, 5, 'Midfielder', TRUE),

-- Deccan Shuttlers (Team 3)
(3, 2, 'Captain', TRUE),
(3, 4, 'Singles Player', TRUE),

-- Aundh Aces Tennis (Team 4)
(4, 4, 'Captain', TRUE),
(4, 6, 'Doubles Partner', TRUE),

-- Wakad Hoops Basketball (Team 5)
(5, 5, 'Captain', TRUE),
(5, 1, 'Point Guard', TRUE),

-- Viman Nagar Spikers (Team 6)
(6, 6, 'Captain', TRUE),
(6, 2, 'Setter', TRUE);

-- ================================================
-- 7. TIMESLOTS DATA (Sample for next 30 days)
-- ================================================

-- Generate timeslots for Shivaji Park Cricket Ground (VenueID = 1)
INSERT IGNORE INTO Timeslots (VenueID, SlotDate, StartTime, EndTime, IsAvailable, PriceINR) VALUES 
-- Today and next few days
(1, CURDATE(), '06:00:00', '08:00:00', TRUE, 140.00),
(1, CURDATE(), '08:00:00', '10:00:00', TRUE, 140.00),
(1, CURDATE(), '16:00:00', '18:00:00', TRUE, 150.00),
(1, CURDATE(), '18:00:00', '20:00:00', TRUE, 150.00),

-- Deccan Badminton Academy (VenueID = 2)
(2, CURDATE(), '06:00:00', '07:00:00', TRUE, 100.00),
(2, CURDATE(), '07:00:00', '08:00:00', TRUE, 100.00),
(2, CURDATE(), '18:00:00', '19:00:00', TRUE, 110.00),
(2, CURDATE(), '19:00:00', '20:00:00', TRUE, 110.00),

-- Baner Football Turf (VenueID = 3)
(3, CURDATE(), '06:00:00', '08:00:00', TRUE, 150.00),
(3, CURDATE(), '16:00:00', '18:00:00', TRUE, 150.00),
(3, CURDATE(), '18:00:00', '20:00:00', TRUE, 150.00);

-- ================================================
-- 8. BOOKINGS DATA (Sample)
-- ================================================

INSERT IGNORE INTO Bookings (BookingID, UserID, VenueID, TimeslotID, BookingDate, StartTime, EndTime, TotalAmount, Status) VALUES 
(1, 1, 1, 1, CURDATE(), '06:00:00', '08:00:00', 280.00, 'Confirmed'),
(2, 2, 2, 5, CURDATE(), '06:00:00', '07:00:00', 100.00, 'Confirmed'),
(3, 3, 3, 9, CURDATE(), '06:00:00', '08:00:00', 300.00, 'Pending');

-- ================================================
-- 9. PAYMENTS DATA (Sample)
-- ================================================

INSERT IGNORE INTO Payments (PaymentID, BookingID, UserID, Amount, Currency, PaymentMethod, TransactionID, PaymentStatus) VALUES 
(1, 1, 1, 280.00, 'INR', 'UPI', 'TXN001PUNE2025', 'Success'),
(2, 2, 2, 100.00, 'INR', 'Card', 'TXN002PUNE2025', 'Success');

-- ================================================
-- 10. MATCHES DATA (Sample)
-- ================================================

INSERT IGNORE INTO Matches (MatchID, Team1ID, Team2ID, VenueID, MatchDate, MatchTime, SportID, Status, CreatedByUserID) VALUES 
(1, 1, 2, 1, DATE_ADD(CURDATE(), INTERVAL 7 DAY), '16:00:00', 1, 'Scheduled', 1),
(2, 3, 4, 2, DATE_ADD(CURDATE(), INTERVAL 10 DAY), '18:00:00', 3, 'Scheduled', 2);

-- ================================================
-- 11. FEEDBACK DATA (Sample)
-- ================================================

INSERT IGNORE INTO Feedback (FeedbackID, UserID, VenueID, Rating, Comments) VALUES 
(1, 1, 1, 5, 'Excellent cricket ground with good facilities. Well maintained pitch and friendly staff.'),
(2, 2, 2, 4, 'Good badminton courts with proper lighting. Could improve air conditioning.'),
(3, 3, 3, 5, 'Amazing football turf! Great for evening matches with floodlights.');

-- ================================================
-- 12. NOTIFICATIONS DATA (Sample)
-- ================================================

INSERT IGNORE INTO Notifications (NotificationID, UserID, Title, Message, Type, IsRead, RelatedEntityType, RelatedEntityID) VALUES 
(1, 1, 'Booking Confirmed', 'Your booking at Shivaji Park Cricket Ground has been confirmed for tomorrow 6:00 AM.', 'Success', FALSE, 'booking', 1),
(2, 2, 'Match Scheduled', 'Your team Deccan Shuttlers has a match scheduled on next Sunday.', 'Info', FALSE, 'match', 2),
(3, 3, 'Payment Pending', 'Please complete payment for your booking at Baner Football Turf.', 'Warning', FALSE, 'booking', 3);

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ================================================
-- 13. UPDATE STATISTICS
-- ================================================

-- Update auto-increment values to ensure proper sequencing
ALTER TABLE Users AUTO_INCREMENT = 13;
ALTER TABLE Venues AUTO_INCREMENT = 9;
ALTER TABLE Teams AUTO_INCREMENT = 7;
ALTER TABLE Bookings AUTO_INCREMENT = 4;
ALTER TABLE Payments AUTO_INCREMENT = 3;
ALTER TABLE Matches AUTO_INCREMENT = 3;
ALTER TABLE Feedback AUTO_INCREMENT = 4;
ALTER TABLE Notifications AUTO_INCREMENT = 4;

-- ================================================
-- SUCCESS MESSAGE AND STATISTICS
-- ================================================

SELECT 'Sample Data Insertion Complete!' as Status,
       (SELECT COUNT(*) FROM Users) as TotalUsers,
       (SELECT COUNT(*) FROM Venues) as TotalVenues,
       (SELECT COUNT(*) FROM Teams) as TotalTeams,
       (SELECT COUNT(*) FROM Bookings) as TotalBookings,
       (SELECT COUNT(*) FROM Sports) as TotalSports,
       'Pune Sports Management Data Ready!' as Message;

-- Show sample of inserted data
SELECT 'Sample Users:' as Info;
SELECT UserID, Name, Email, 
       CASE RoleID WHEN 1 THEN 'Player' WHEN 2 THEN 'Venue Owner' ELSE 'Other' END as Role,
       Address 
FROM Users 
LIMIT 5;

SELECT 'Sample Venues:' as Info;
SELECT VenueID, VenueName, Location, PricePerHour, Capacity 
FROM Venues 
LIMIT 5;

SELECT 'Sample Teams:' as Info;
SELECT t.TeamID, t.TeamName, s.SportName, u.Name as Captain, t.HomeLocation 
FROM Teams t 
JOIN Sports s ON t.SportID = s.SportID 
JOIN Users u ON t.CaptainID = u.UserID 
LIMIT 5;