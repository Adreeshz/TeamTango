USE dbms_cp;



-- Clear existing data (in proper order to handle foreign keys)
SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM AuditLog;
DELETE FROM Notifications;
DELETE FROM Feedback;
DELETE FROM Matches;
DELETE FROM Payments;
DELETE FROM Bookings;
DELETE FROM Timeslots;
DELETE FROM TeamMembers;
DELETE FROM Teams;
DELETE FROM Venues;
DELETE FROM Users WHERE UserID > 0;  -- Don't delete system users if any
SET FOREIGN_KEY_CHECKS = 1;

-- Reset auto-increment counters
ALTER TABLE Users AUTO_INCREMENT = 1;
ALTER TABLE Venues AUTO_INCREMENT = 1;
ALTER TABLE Teams AUTO_INCREMENT = 1;
ALTER TABLE TeamMembers AUTO_INCREMENT = 1;
ALTER TABLE Timeslots AUTO_INCREMENT = 1;
ALTER TABLE Bookings AUTO_INCREMENT = 1;
ALTER TABLE Payments AUTO_INCREMENT = 1;
ALTER TABLE Matches AUTO_INCREMENT = 1;
ALTER TABLE Feedback AUTO_INCREMENT = 1;
ALTER TABLE Notifications AUTO_INCREMENT = 1;
ALTER TABLE AuditLog AUTO_INCREMENT = 1;

-- ================================================
-- SECTION 1: INSERT COMPREHENSIVE SAMPLE DATA
-- ================================================

-- Insert demo users with proper password hashing (for demo - in production use bcrypt)
INSERT INTO Users (Name, Email, Gender, Password, PhoneNumber, Address, RoleID) VALUES

-- ============ DEMO PLAYERS (Role ID: 1) ============
('Demo Player', 'player@example.com', 'Male', '$2b$10$rQZ8vNzE3K2yF5L7x9Qo8.8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bC', '9876543210', 'FC Road, Pune, Maharashtra', 1),
('Rahul Sharma', 'rahul.player@gmail.com', 'Male', '$2b$10$K8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bCrQZ8vNzE3K2yF5L7x9Qo8', '9876543211', 'Koregaon Park, Pune', 1),
('Priya Patel', 'priya.player@gmail.com', 'Female', '$2b$10$M3nP4rS6tU8vW9xY1zA2bCrQZ8vNzE3K2yF5L7x9Qo8K8vF7xY2Zq', '9876543212', 'Aundh, Pune', 1),
('Amit Kumar', 'amit.cricket@gmail.com', 'Male', '$2b$10$P4rS6tU8vW9xY1zA2bCrQZ8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3n', '9876543213', 'Baner, Pune', 1),
('Sneha Desai', 'sneha.badminton@yahoo.com', 'Female', '$2b$10$S6tU8vW9xY1zA2bCrQZ8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4r', '9876543214', 'Hadapsar, Pune', 1),
('Rohit Kulkarni', 'rohit.footballer@hotmail.com', 'Male', '$2b$10$U8vW9xY1zA2bCrQZ8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6t', '9876543215', 'Kothrud, Pune', 1),
('Kavya Singh', 'kavya.tennis@gmail.com', 'Female', '$2b$10$W9xY1zA2bCrQZ8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8v', '9876543216', 'Wakad, Pune', 1),
('Arjun Mehta', 'arjun.basketball@gmail.com', 'Male', '$2b$10$Y1zA2bCrQZ8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8vW9x', '9876543217', 'Viman Nagar, Pune', 1),
('Neha Gupta', 'neha.volleyball@gmail.com', 'Female', '$2b$10$A2bCrQZ8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8vW9xY1z', '9876543218', 'Shivaji Nagar, Pune', 1),
('Vikash Yadav', 'vikash.sports@hotmail.com', 'Male', '$2b$10$CrQZ8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2b', '9876543219', 'Karve Nagar, Pune', 1),

-- ============ DEMO VENUE OWNERS (Role ID: 2) ============
('Demo Owner', 'owner@example.com', 'Male', '$2b$10$rQZ8vNzE3K2yF5L7x9Qo8.8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bC', '9876543300', 'Camp Area, Pune, Maharashtra', 2),
('Suresh Patil', 'suresh.venue@gmail.com', 'Male', '$2b$10$QZ8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bCr', '9876543301', 'Deccan Gymkhana, Pune', 2),
('Meera Joshi', 'meera.venue@gmail.com', 'Female', '$2b$10$8vNzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bCrQ', '9876543302', 'Koregaon Park, Pune', 2),
('Rajesh Jadhav', 'rajesh.venue@gmail.com', 'Male', '$2b$10$NzE3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bCrQZ8v', '9876543303', 'Baner, Pune', 2),
('Anita Sharma', 'anita.sports@gmail.com', 'Female', '$2b$10$E3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bCrQZ8vNz', '9876543304', 'Aundh, Pune', 2),

-- ============ DEMO ADMIN (Role ID: 3) ============
('Demo Admin', 'admin@example.com', 'Male', '$2b$10$rQZ8vNzE3K2yF5L7x9Qo8.8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bC', '9876543400', 'FC Road, Pune, Maharashtra', 3),
('System Admin', 'admin@teamtango.com', 'Other', '$2b$10$3K2yF5L7x9Qo8K8vF7xY2ZqM3nP4rS6tU8vW9xY1zA2bCrQZ8vNzE', '9876543401', 'TeamTango HQ, Pune', 3);

-- ============ INSERT COMPREHENSIVE VENUES ============
INSERT INTO Venues (VenueName, Address, OwnerID) VALUES

-- Demo Owner's Venues (ID: 11)
('Shiv Chhatrapati Sports Complex Basketball Courts', 'FC Road, Pune, Maharashtra', 11),
('Cooperage Football Ground', 'Camp Area, Pune, Maharashtra', 11),

-- Suresh Patil's Venues (ID: 12)
('Deccan Gymkhana Cricket Ground', 'Deccan Gymkhana Club, Pune', 12),
('Deccan Tennis Academy Courts', 'Deccan Gymkhana, Pune', 12),

-- Meera Joshi's Venues (ID: 13)  
('Sanas Badminton Club Premium Courts', 'Koregaon Park, Pune', 13),
('Koregaon Park Volleyball Courts', 'Koregaon Park, Pune', 13),

-- Rajesh Jadhav's Venues (ID: 14)
('Baner Football Turf Ground', 'Baner IT Park, Pune', 14),
('Baner Sports Complex Multi-Court', 'Baner, Pune', 14),

-- Anita Sharma's Venues (ID: 15)
('Aundh Basketball Arena', 'Aundh, Pune', 15),
('MCA Cricket Academy Nets', 'Aundh, Pune', 15),
('Elite Tennis Club Aundh', 'Aundh, Pune', 15),
('Aundh Badminton Center', 'Aundh IT Park, Pune', 15);

-- ============ INSERT COMPREHENSIVE TEAMS ============
INSERT INTO Teams (TeamName, SportID, CaptainID) VALUES
-- Cricket Teams (SportID: 5)
('Pune Warriors Cricket Club', 5, 2),        -- Rahul Sharma as captain
('Deccan Gladiators', 5, 4),                 -- Amit Kumar as captain

-- Football Teams (SportID: 1) 
('Baner United FC', 1, 6),                   -- Rohit Kulkarni as captain
('FC Pune City', 1, 10),                     -- Vikash Yadav as captain

-- Basketball Teams (SportID: 2)
('Pune Hoopsters', 2, 8),                    -- Arjun Mehta as captain
('Court Kings', 2, 4),                       -- Amit Kumar as captain

-- Tennis Teams (SportID: 3)
('Ace Tennis Club', 3, 7),                   -- Kavya Singh as captain
('Pune Racquet Masters', 3, 3),              -- Priya Patel as captain

-- Badminton Teams (SportID: 4)
('Shuttlers United', 4, 5),                  -- Sneha Desai as captain
('Pune Smashers', 4, 9),                     -- Neha Gupta as captain

-- Volleyball Teams (SportID: 6)
('Spike Warriors', 6, 9),                    -- Neha Gupta as captain  
('Net Crushers', 6, 2);                      -- Rahul Sharma as captain

-- ============ INSERT COMPREHENSIVE TEAM MEMBERS ============
INSERT INTO TeamMembers (TeamID, UserID, JoinedDate) VALUES
-- Pune Warriors Cricket Club (TeamID: 1)
(1, 2, '2024-01-15'),   -- Captain Rahul Sharma
(1, 4, '2024-01-20'),   -- Amit Kumar  
(1, 6, '2024-01-25'),   -- Rohit Kulkarni
(1, 8, '2024-02-01'),   -- Arjun Mehta
(1, 10, '2024-02-05'),  -- Vikash Yadav

-- Deccan Gladiators Cricket (TeamID: 2)
(2, 4, '2024-01-12'),   -- Captain Amit Kumar
(2, 2, '2024-01-18'),   -- Rahul Sharma
(2, 6, '2024-01-22'),   -- Rohit Kulkarni

-- Baner United FC (TeamID: 3)
(3, 6, '2024-01-10'),   -- Captain Rohit Kulkarni
(3, 2, '2024-01-15'),   -- Rahul Sharma
(3, 4, '2024-01-20'),   -- Amit Kumar
(3, 8, '2024-01-25'),   -- Arjun Mehta
(3, 10, '2024-01-30'),  -- Vikash Yadav

-- FC Pune City (TeamID: 4) 
(4, 10, '2024-01-08'),  -- Captain Vikash Yadav
(4, 2, '2024-01-12'),   -- Rahul Sharma
(4, 4, '2024-01-16'),   -- Amit Kumar

-- Pune Hoopsters Basketball (TeamID: 5)
(5, 8, '2024-01-05'),   -- Captain Arjun Mehta
(5, 2, '2024-01-10'),   -- Rahul Sharma
(5, 4, '2024-01-15'),   -- Amit Kumar
(5, 6, '2024-01-20'),   -- Rohit Kulkarni

-- Court Kings Basketball (TeamID: 6)
(6, 4, '2024-01-03'),   -- Captain Amit Kumar
(6, 8, '2024-01-08'),   -- Arjun Mehta
(6, 10, '2024-01-12'),  -- Vikash Yadav

-- Ace Tennis Club (TeamID: 7)
(7, 7, '2024-01-01'),   -- Captain Kavya Singh
(7, 3, '2024-01-05'),   -- Priya Patel
(7, 5, '2024-01-10'),   -- Sneha Desai

-- Pune Racquet Masters (TeamID: 8)
(8, 3, '2024-01-02'),   -- Captain Priya Patel
(8, 7, '2024-01-07'),   -- Kavya Singh

-- Shuttlers United Badminton (TeamID: 9)
(9, 5, '2024-01-01'),   -- Captain Sneha Desai
(9, 3, '2024-01-05'),   -- Priya Patel
(9, 7, '2024-01-10'),   -- Kavya Singh
(9, 9, '2024-01-15'),   -- Neha Gupta

-- Pune Smashers Badminton (TeamID: 10)
(10, 9, '2024-01-03'),  -- Captain Neha Gupta
(10, 5, '2024-01-08'),  -- Sneha Desai
(10, 3, '2024-01-12'),  -- Priya Patel

-- Spike Warriors Volleyball (TeamID: 11)
(11, 9, '2024-01-01'),  -- Captain Neha Gupta
(11, 3, '2024-01-05'),  -- Priya Patel
(11, 5, '2024-01-10'),  -- Sneha Desai
(11, 7, '2024-01-15'),  -- Kavya Singh

-- Net Crushers Volleyball (TeamID: 12)
(12, 2, '2024-01-02'),  -- Captain Rahul Sharma
(12, 6, '2024-01-07'),  -- Rohit Kulkarni
(12, 8, '2024-01-12'),  -- Arjun Mehta
(12, 10, '2024-01-17'); -- Vikash Yadav
-- ============ INSERT COMPREHENSIVE BOOKINGS ============
INSERT INTO Bookings (UserID, VenueID, TeamID, BookingDate, StartTime, EndTime, Status) VALUES

-- Recent Confirmed Bookings (Last 7 days)
(1, 3, 3, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '06:00:00', '08:00:00', 'Confirmed'),     -- Demo Player - Football
(2, 5, 9, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '07:00:00', '08:00:00', 'Confirmed'),     -- Rahul - Badminton  
(3, 4, 8, DATE_SUB(CURDATE(), INTERVAL 2 DAY), '18:00:00', '19:00:00', 'Confirmed'),     -- Priya - Tennis
(4, 3, 1, DATE_SUB(CURDATE(), INTERVAL 2 DAY), '17:00:00', '19:00:00', 'Confirmed'),     -- Amit - Cricket
(5, 12, 10, DATE_SUB(CURDATE(), INTERVAL 3 DAY), '08:00:00', '09:00:00', 'Confirmed'),   -- Sneha - Badminton
(6, 8, 3, DATE_SUB(CURDATE(), INTERVAL 3 DAY), '16:00:00', '18:00:00', 'Confirmed'),     -- Rohit - Football
(7, 11, 7, DATE_SUB(CURDATE(), INTERVAL 4 DAY), '19:00:00', '20:00:00', 'Confirmed'),    -- Kavya - Tennis
(8, 9, 5, DATE_SUB(CURDATE(), INTERVAL 4 DAY), '08:00:00', '10:00:00', 'Confirmed'),     -- Arjun - Basketball
(9, 6, 11, DATE_SUB(CURDATE(), INTERVAL 5 DAY), '18:00:00', '19:00:00', 'Confirmed'),    -- Neha - Volleyball
(10, 1, 5, DATE_SUB(CURDATE(), INTERVAL 5 DAY), '06:00:00', '08:00:00', 'Confirmed'),    -- Vikash - Basketball

-- Current Pending Bookings (Today and upcoming)
(1, 2, 3, CURDATE(), '17:00:00', '19:00:00', 'Pending'),                                 -- Demo Player - Football
(2, 3, 1, CURDATE(), '06:00:00', '08:00:00', 'Pending'),                                 -- Rahul - Cricket
(3, 11, 8, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '19:00:00', '20:00:00', 'Pending'),     -- Priya - Tennis
(4, 9, 6, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '08:00:00', '10:00:00', 'Pending'),      -- Amit - Basketball
(5, 5, 9, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '07:00:00', '08:00:00', 'Pending'),      -- Sneha - Badminton

-- Future Confirmed Bookings (Next week)
(6, 8, 4, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '17:00:00', '19:00:00', 'Confirmed'),    -- Rohit - Football
(7, 4, 7, DATE_ADD(CURDATE(), INTERVAL 4 DAY), '18:00:00', '19:00:00', 'Confirmed'),    -- Kavya - Tennis
(8, 1, 5, DATE_ADD(CURDATE(), INTERVAL 5 DAY), '06:00:00', '08:00:00', 'Confirmed'),    -- Arjun - Basketball
(9, 12, 10, DATE_ADD(CURDATE(), INTERVAL 6 DAY), '08:00:00', '09:00:00', 'Confirmed'),  -- Neha - Badminton
(10, 3, 2, DATE_ADD(CURDATE(), INTERVAL 7 DAY), '16:00:00', '18:00:00', 'Confirmed'),   -- Vikash - Cricket

-- Some individual bookings (no team)
(2, 1, NULL, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '06:00:00', '08:00:00', 'Confirmed'),  -- Rahul individual
(4, 5, NULL, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '07:00:00', '08:00:00', 'Pending'),    -- Amit individual
(6, 11, NULL, DATE_ADD(CURDATE(), INTERVAL 4 DAY), '19:00:00', '20:00:00', 'Confirmed'), -- Rohit individual

-- Some cancelled bookings for demo
(3, 9, 6, DATE_SUB(CURDATE(), INTERVAL 6 DAY), '08:00:00', '10:00:00', 'Cancelled'),     -- Priya cancelled
(5, 4, 7, DATE_SUB(CURDATE(), INTERVAL 7 DAY), '18:00:00', '19:00:00', 'Cancelled');    -- Sneha cancelled

-- ============ INSERT COMPREHENSIVE PAYMENTS ============  
INSERT INTO Payments (BookingID, Amount, PaymentMethod, Status, PaymentDate) VALUES

-- Payments for confirmed past bookings
(1, 150.00, 'UPI', 'Completed', DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
(2, 100.00, 'Card', 'Completed', DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
(3, 130.00, 'UPI', 'Completed', DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
(4, 140.00, 'Cash', 'Completed', DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
(5, 100.00, 'UPI', 'Completed', DATE_SUB(CURDATE(), INTERVAL 3 DAY)),
(6, 150.00, 'Card', 'Completed', DATE_SUB(CURDATE(), INTERVAL 3 DAY)),
(7, 130.00, 'UPI', 'Completed', DATE_SUB(CURDATE(), INTERVAL 4 DAY)),
(8, 120.00, 'UPI', 'Completed', DATE_SUB(CURDATE(), INTERVAL 4 DAY)),
(9, 110.00, 'Card', 'Completed', DATE_SUB(CURDATE(), INTERVAL 5 DAY)),
(10, 120.00, 'Cash', 'Completed', DATE_SUB(CURDATE(), INTERVAL 5 DAY)),

-- Payments for future confirmed bookings
(16, 150.00, 'UPI', 'Completed', DATE_ADD(CURDATE(), INTERVAL 2 DAY)),
(17, 130.00, 'Card', 'Completed', DATE_ADD(CURDATE(), INTERVAL 3 DAY)),
(18, 120.00, 'UPI', 'Completed', DATE_ADD(CURDATE(), INTERVAL 4 DAY)),
(19, 100.00, 'UPI', 'Completed', DATE_ADD(CURDATE(), INTERVAL 5 DAY)),
(20, 140.00, 'Card', 'Completed', DATE_ADD(CURDATE(), INTERVAL 6 DAY)),

-- Individual booking payments
(21, 140.00, 'UPI', 'Completed', DATE_ADD(CURDATE(), INTERVAL 2 DAY)),
(23, 130.00, 'Card', 'Completed', DATE_ADD(CURDATE(), INTERVAL 4 DAY)),

-- Pending payments for pending bookings
(11, 150.00, 'UPI', 'Pending', CURDATE()),
(12, 140.00, 'Card', 'Pending', CURDATE()),
(13, 130.00, 'UPI', 'Pending', DATE_ADD(CURDATE(), INTERVAL 1 DAY)),
(14, 120.00, 'UPI', 'Pending', DATE_ADD(CURDATE(), INTERVAL 1 DAY)),
(15, 100.00, 'Card', 'Pending', DATE_ADD(CURDATE(), INTERVAL 2 DAY)),
(22, 100.00, 'UPI', 'Pending', DATE_ADD(CURDATE(), INTERVAL 3 DAY));

-- ============ INSERT COMPREHENSIVE MATCHES ============
INSERT INTO Matches (Team1ID, Team2ID, VenueID, MatchDate, StartTime, EndTime, Status, WinnerID) VALUES

-- Completed Matches (Past week)
(1, 2, 1, DATE_SUB(CURDATE(), INTERVAL 6 DAY), '06:00:00', '08:00:00', 'Completed', 1),    -- Cricket: Mumbai vs Pune
(3, 4, 2, DATE_SUB(CURDATE(), INTERVAL 5 DAY), '17:00:00', '19:00:00', 'Completed', 3),    -- Football: City vs United
(5, 6, 9, DATE_SUB(CURDATE(), INTERVAL 4 DAY), '08:00:00', '10:00:00', 'Completed', 5),    -- Basketball: Hoops vs Dunkers
(7, 8, 4, DATE_SUB(CURDATE(), INTERVAL 3 DAY), '18:00:00', '19:00:00', 'Completed', 8),    -- Tennis: Masters vs Aces
(9, 10, 5, DATE_SUB(CURDATE(), INTERVAL 2 DAY), '07:00:00', '08:00:00', 'Completed', 9),   -- Badminton: Shuttlers vs Smash
(11, 1, 6, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '18:00:00', '19:00:00', 'Completed', 11),  -- Volleyball: Spikers vs Mumbai

-- Ongoing/Scheduled Matches (Today and future)
(2, 3, 3, CURDATE(), '17:00:00', '19:00:00', 'Scheduled', NULL),                          -- Cricket vs Football today
(4, 5, 8, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '16:00:00', '18:00:00', 'Scheduled', NULL), -- United vs Hoops
(6, 7, 9, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '08:00:00', '10:00:00', 'Scheduled', NULL), -- Dunkers vs Masters
(8, 9, 11, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '19:00:00', '20:00:00', 'Scheduled', NULL), -- Aces vs Shuttlers
(10, 11, 12, DATE_ADD(CURDATE(), INTERVAL 4 DAY), '08:00:00', '09:00:00', 'Scheduled', NULL), -- Smash vs Spikers

-- Some cancelled matches
(1, 3, 7, DATE_SUB(CURDATE(), INTERVAL 7 DAY), '06:00:00', '08:00:00', 'Cancelled', NULL), -- Mumbai vs City (cancelled)
(5, 8, 10, DATE_SUB(CURDATE(), INTERVAL 8 DAY), '19:00:00', '20:00:00', 'Cancelled', NULL); -- Hoops vs Aces (cancelled)

-- ============ INSERT COMPREHENSIVE FEEDBACK ============
INSERT INTO Feedback (UserID, VenueID, Rating, Comments, FeedbackDate) VALUES

-- Recent venue feedback from various users
(1, 1, 4, 'Great cricket ground with good facilities. Well maintained pitch.', DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
(2, 5, 5, 'Excellent badminton court! Clean and well-lit. Will book again.', DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
(3, 4, 3, 'Tennis court surface needs improvement. Net was in good condition.', DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
(4, 3, 5, 'Amazing football turf! Perfect for matches. Great drainage system.', DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
(5, 12, 4, 'Good badminton facilities. Air conditioning could be better.', DATE_SUB(CURDATE(), INTERVAL 3 DAY)),
(6, 8, 5, 'Fantastic football ground with excellent lighting for evening games.', DATE_SUB(CURDATE(), INTERVAL 3 DAY)),
(7, 11, 4, 'Tennis club has good amenities. Court booking system is efficient.', DATE_SUB(CURDATE(), INTERVAL 4 DAY)),
(8, 9, 3, 'Basketball court is decent but could use better flooring.', DATE_SUB(CURDATE(), INTERVAL 4 DAY)),
(9, 6, 5, 'Outstanding volleyball court with great team facilities!', DATE_SUB(CURDATE(), INTERVAL 5 DAY)),
(10, 1, 4, 'Cricket ground is good for practice. Parking space is adequate.', DATE_SUB(CURDATE(), INTERVAL 5 DAY)),

-- More feedback from different users
(2, 2, 5, 'Love this football turf! Perfect grass quality and great atmosphere.', DATE_SUB(CURDATE(), INTERVAL 6 DAY)),
(3, 7, 4, 'Basketball arena is spacious with good sound system for matches.', DATE_SUB(CURDATE(), INTERVAL 6 DAY)),
(4, 10, 3, 'Tennis court is okay but needs better maintenance of the surface.', DATE_SUB(CURDATE(), INTERVAL 7 DAY)),
(5, 13, 5, 'Excellent volleyball facilities with comfortable seating area.', DATE_SUB(CURDATE(), INTERVAL 7 DAY)),
(6, 14, 4, 'Nice badminton courts with good ventilation and clean changing rooms.', DATE_SUB(CURDATE(), INTERVAL 8 DAY)),

-- Recent positive feedback
(7, 15, 5, 'Best cricket ground in the area! Professional quality pitch and facilities.', DATE_SUB(CURDATE(), INTERVAL 8 DAY)),
(8, 1, 3, 'Cricket ground is good but parking can be challenging during peak hours.', DATE_SUB(CURDATE(), INTERVAL 9 DAY)),
(9, 3, 5, 'Absolutely love this football turf! Great for team training sessions.', DATE_SUB(CURDATE(), INTERVAL 9 DAY)),
(10, 5, 4, 'Badminton court has good flooring but lighting could be brighter.', DATE_SUB(CURDATE(), INTERVAL 10 DAY)),
(1, 9, 5, 'Excellent basketball facilities with modern equipment and clean washrooms.', DATE_SUB(CURDATE(), INTERVAL 10 DAY));

-- ============ INSERT COMPREHENSIVE NOTIFICATIONS ============
INSERT INTO Notifications (UserID, Type, Title, Message, IsRead, CreatedAt) VALUES

-- Booking confirmation notifications
(1, 'Booking', 'Booking Confirmed', 'Your booking at Green Football Turf for today 5:00 PM - 7:00 PM has been confirmed.', FALSE, NOW()),
(2, 'Booking', 'Booking Confirmed', 'Your booking at Elite Cricket Ground for tomorrow 6:00 AM - 8:00 AM has been confirmed.', TRUE, DATE_SUB(NOW(), INTERVAL 1 HOUR)),
(3, 'Booking', 'Booking Pending', 'Your booking at City Tennis Club is pending payment. Please complete payment to confirm.', FALSE, DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(4, 'Booking', 'Booking Confirmed', 'Your booking at Urban Basketball Court has been confirmed for tomorrow 8:00 AM - 10:00 AM.', TRUE, DATE_SUB(NOW(), INTERVAL 3 HOUR)),
(5, 'Booking', 'Booking Cancelled', 'Your booking at Premier Badminton Academy has been cancelled due to venue maintenance.', FALSE, DATE_SUB(NOW(), INTERVAL 4 HOUR)),

-- Match notifications
(1, 'Match', 'Match Scheduled', 'Your team has a match scheduled for today at 5:00 PM at Green Football Turf.', FALSE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 'Match', 'Match Result', 'Your team won the match against Pune Cricketers! Congratulations!', TRUE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 'Match', 'Match Reminder', 'Reminder: Your tennis match is scheduled for tomorrow at 7:00 PM.', FALSE, DATE_SUB(NOW(), INTERVAL 6 HOUR)),
(4, 'Match', 'Match Cancelled', 'Your basketball match scheduled for this weekend has been cancelled due to weather.', TRUE, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(6, 'Match', 'Match Victory', 'Your team Green Football Squad won against City United FC 3-1!', TRUE, DATE_SUB(NOW(), INTERVAL 2 DAY)),

-- Payment notifications
(1, 'Payment', 'Payment Successful', 'Payment of ₹150 for your football turf booking has been processed successfully.', TRUE, DATE_SUB(NOW(), INTERVAL 30 MINUTE)),
(2, 'Payment', 'Payment Due', 'Payment of ₹140 is due for your upcoming cricket ground booking.', FALSE, DATE_SUB(NOW(), INTERVAL 1 HOUR)),
(3, 'Payment', 'Payment Failed', 'Payment for tennis court booking failed. Please try again or contact support.', FALSE, DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(4, 'Payment', 'Refund Processed', 'Refund of ₹120 for cancelled basketball booking has been processed.', TRUE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(5, 'Payment', 'Payment Reminder', 'Your payment of ₹100 for badminton court booking is pending.', FALSE, DATE_SUB(NOW(), INTERVAL 3 HOUR)),

-- Team notifications
(2, 'Team', 'Team Invitation', 'You have been invited to join Mumbai Cricketers team by captain Rahul.', FALSE, DATE_SUB(NOW(), INTERVAL 5 HOUR)),
(3, 'Team', 'New Team Member', 'Amit has joined your tennis team City Masters.', TRUE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(4, 'Team', 'Team Captain', 'You have been promoted to team captain of Urban Hoopers basketball team.', TRUE, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(6, 'Team', 'Team Activity', 'Your football team has 3 new booking requests for this week.', FALSE, DATE_SUB(NOW(), INTERVAL 4 HOUR)),
(7, 'Team', 'Team Achievement', 'Your tennis team has won 5 consecutive matches! Great performance!', TRUE, DATE_SUB(NOW(), INTERVAL 3 DAY)),

-- System notifications
(11, 'System', 'Welcome to Playo', 'Welcome to Playo! Complete your profile to start booking venues.', FALSE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(12, 'System', 'Profile Update', 'Your venue owner profile has been approved. You can now list your venues.', TRUE, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(13, 'System', 'Maintenance Notice', 'System maintenance scheduled for this weekend from 2 AM to 6 AM.', FALSE, DATE_SUB(NOW(), INTERVAL 6 HOUR)),
(1, 'System', 'Feature Update', 'New feature: Team chat is now available! Connect with your teammates.', TRUE, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(5, 'System', 'Feedback Request', 'Please rate your recent booking experience to help us improve.', FALSE, DATE_SUB(NOW(), INTERVAL 1 DAY));

-- ============ INSERT COMPREHENSIVE AUDIT LOG ============
INSERT INTO AuditLog (TableName, RecordID, Action, UserID, Timestamp, OldValues, NewValues) VALUES

-- User registration and login activities
('Users', 1, 'CREATE', 1, DATE_SUB(NOW(), INTERVAL 10 DAY), NULL, 'User registered: player@example.com'),
('Users', 11, 'CREATE', 11, DATE_SUB(NOW(), INTERVAL 9 DAY), NULL, 'Venue owner registered: owner@example.com'),
('Users', 13, 'CREATE', 13, DATE_SUB(NOW(), INTERVAL 8 DAY), NULL, 'Admin registered: admin@example.com'),
('Users', 2, 'UPDATE', 2, DATE_SUB(NOW(), INTERVAL 5 DAY), 'ProfileComplete: false', 'ProfileComplete: true'),
('Users', 3, 'UPDATE', 3, DATE_SUB(NOW(), INTERVAL 4 DAY), 'Phone: null', 'Phone: +91-9876543210'),

-- Venue management activities
('Venues', 1, 'CREATE', 11, DATE_SUB(NOW(), INTERVAL 7 DAY), NULL, 'Elite Cricket Ground created'),
('Venues', 2, 'CREATE', 11, DATE_SUB(NOW(), INTERVAL 6 DAY), NULL, 'Green Football Turf created'),
('Venues', 3, 'UPDATE', 11, DATE_SUB(NOW(), INTERVAL 3 DAY), 'Status: Active', 'Status: Under Maintenance'),
('Venues', 4, 'UPDATE', 12, DATE_SUB(NOW(), INTERVAL 2 DAY), 'PricePerHour: 120', 'PricePerHour: 130'),
('Venues', 5, 'CREATE', 12, DATE_SUB(NOW(), INTERVAL 5 DAY), NULL, 'Premier Badminton Academy created'),

-- Booking activities
('Bookings', 1, 'CREATE', 1, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL, 'Booking created for Elite Cricket Ground'),
('Bookings', 2, 'CREATE', 2, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL, 'Booking created for Premier Badminton Academy'),
('Bookings', 3, 'UPDATE', 3, DATE_SUB(NOW(), INTERVAL 2 DAY), 'Status: Pending', 'Status: Confirmed'),
('Bookings', 4, 'UPDATE', 4, DATE_SUB(NOW(), INTERVAL 2 DAY), 'Status: Pending', 'Status: Confirmed'),
('Bookings', 24, 'UPDATE', 3, DATE_SUB(NOW(), INTERVAL 6 DAY), 'Status: Confirmed', 'Status: Cancelled'),

-- Team management activities
('Teams', 1, 'CREATE', 2, DATE_SUB(NOW(), INTERVAL 8 DAY), NULL, 'Mumbai Cricketers team created'),
('Teams', 3, 'CREATE', 1, DATE_SUB(NOW(), INTERVAL 7 DAY), NULL, 'Green Football Squad created'),
('TeamMembers', 1, 'CREATE', 2, DATE_SUB(NOW(), INTERVAL 8 DAY), NULL, 'Captain assigned to Mumbai Cricketers'),
('TeamMembers', 5, 'CREATE', 4, DATE_SUB(NOW(), INTERVAL 5 DAY), NULL, 'New member joined Urban Hoopers'),
('Teams', 5, 'UPDATE', 4, DATE_SUB(NOW(), INTERVAL 2 DAY), 'CaptainID: 4', 'CaptainID: 8'),

-- Payment processing
('Payments', 1, 'CREATE', 1, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL, 'Payment processed: ₹150 via UPI'),
('Payments', 2, 'CREATE', 2, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL, 'Payment processed: ₹100 via Card'),
('Payments', 3, 'UPDATE', 3, DATE_SUB(NOW(), INTERVAL 2 DAY), 'Status: Pending', 'Status: Completed'),
('Payments', 14, 'UPDATE', 5, DATE_SUB(NOW(), INTERVAL 6 DAY), 'Status: Completed', 'Status: Refunded'),
('Payments', 11, 'CREATE', 1, NOW(), NULL, 'Payment pending: ₹150 via UPI'),

-- Match management
('Matches', 1, 'CREATE', 2, DATE_SUB(NOW(), INTERVAL 6 DAY), NULL, 'Match scheduled: Mumbai vs Pune Cricketers'),
('Matches', 1, 'UPDATE', 13, DATE_SUB(NOW(), INTERVAL 5 DAY), 'Status: Scheduled', 'Status: Completed, Winner: Mumbai'),
('Matches', 7, 'CREATE', 1, CURDATE(), NULL, 'Match scheduled for today: Pune vs Green Football'),
('Matches', 12, 'UPDATE', 13, DATE_SUB(NOW(), INTERVAL 7 DAY), 'Status: Scheduled', 'Status: Cancelled'),
('Matches', 2, 'UPDATE', 13, DATE_SUB(NOW(), INTERVAL 4 DAY), 'Status: Scheduled', 'Status: Completed, Winner: City FC'),

-- Feedback submissions
('Feedback', 1, 'CREATE', 1, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL, 'Feedback submitted for Elite Cricket Ground: 4 stars'),
('Feedback', 5, 'CREATE', 5, DATE_SUB(NOW(), INTERVAL 3 DAY), NULL, 'Feedback submitted for Premier Badminton: 4 stars'),
('Feedback', 10, 'CREATE', 10, DATE_SUB(NOW(), INTERVAL 5 DAY), NULL, 'Feedback submitted for Elite Cricket Ground: 4 stars'),
('Feedback', 15, 'CREATE', 6, DATE_SUB(NOW(), INTERVAL 8 DAY), NULL, 'Feedback submitted for Premier Badminton: 4 stars'),

-- System administration
('Users', 5, 'UPDATE', 13, DATE_SUB(NOW(), INTERVAL 3 DAY), 'Role: Player', 'Role: Venue Owner'),
('Venues', 8, 'UPDATE', 13, DATE_SUB(NOW(), INTERVAL 4 DAY), 'Status: Active', 'Status: Suspended'),
('Users', 6, 'UPDATE', 13, DATE_SUB(NOW(), INTERVAL 2 DAY), 'IsActive: true', 'IsActive: false'),
('Venues', 10, 'DELETE', 13, DATE_SUB(NOW(), INTERVAL 1 DAY), 'Venue deleted', NULL),
('Bookings', 15, 'UPDATE', 13, DATE_SUB(NOW(), INTERVAL 6 HOUR), 'Status: Pending', 'Status: Cancelled by Admin');

-- Display completion message
SELECT 'Database populated with comprehensive sample data successfully!' as Status;

-- Insert matches
INSERT INTO Matches (MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime, Team1Score, Team2Score, MatchStatus) VALUES
('Pune Derby Cricket Match', 1, 1, 1, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '16:00:00', 0, 0, 'Scheduled'),
('Inter-City Football Championship', 2, 2, 3, DATE_ADD(CURDATE(), INTERVAL 5 DAY), '17:00:00', 0, 0, 'Scheduled'),
('Badminton Tournament Final', 3, 3, 2, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '18:00:00', 0, 0, 'Scheduled');

-- Insert feedback
INSERT INTO Feedback (UserID, VenueID, Rating, Comment) VALUES
(1, 1, 5, 'Excellent cricket ground with great facilities!'),
(2, 2, 4, 'Good badminton courts, well maintained.'),
(3, 4, 4, 'Nice basketball court, could use better lighting.'),
(4, 5, 5, 'Perfect tennis club, professional courts.'),
(5, 3, 3, 'Football turf is okay, but needs better drainage.');

-- Insert notifications
INSERT INTO Notifications (UserID, Message, IsRead) VALUES
(1, 'Your cricket ground booking has been confirmed for today 6:00 AM.', FALSE),
(2, 'Your badminton court booking has been confirmed for today 7:00 AM.', FALSE),
(3, 'Your basketball court booking has been confirmed for today 8:00 AM.', TRUE),
(4, 'Your tennis court booking is pending payment confirmation.', FALSE),
(5, 'Your football turf booking is pending venue owner approval.', FALSE);

-- Insert audit logs
INSERT INTO AuditLog (UserID, Action, TableName) VALUES
(1, 'INSERT', 'Bookings'),
(2, 'INSERT', 'Bookings'),
(3, 'INSERT', 'Bookings'),
(6, 'UPDATE', 'Venues'),
(9, 'INSERT', 'Users');

-- ================================================
-- SECTION 2: UPDATE OPERATIONS
-- ================================================

-- Update user information
UPDATE Users 
SET PhoneNumber = '9876543299', City = 'Mumbai'
WHERE UserID = 1;

-- Update venue pricing
UPDATE Venues 
SET PricePerHour = PricePerHour * 1.1  -- 10% price increase
WHERE SportID = 1;  -- Football venues

-- Update booking status
UPDATE Bookings 
SET BookingStatus = 'Confirmed' 
WHERE BookingID = 3 AND BookingStatus = 'Pending';

-- Update match scores
UPDATE Matches 
SET Team1Score = 156, Team2Score = 148, MatchStatus = 'Completed'
WHERE MatchID = 1;

-- Update timeslot availability after booking
UPDATE Timeslots 
SET IsAvailable = FALSE 
WHERE TimeslotID IN (SELECT TimeslotID FROM Bookings WHERE BookingStatus = 'Confirmed');

-- Mark notifications as read
UPDATE Notifications 
SET IsRead = TRUE 
WHERE UserID = 1;

-- ================================================
-- SECTION 3: DELETE OPERATIONS
-- ================================================

-- Delete old timeslots
DELETE FROM Timeslots 
WHERE SlotDate < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
AND TimeslotID NOT IN (SELECT TimeslotID FROM Bookings);

-- Remove team member
DELETE FROM TeamMembers 
WHERE TeamID = 5 AND UserID = 2;  -- Remove Priya from Tennis Masters

-- Cancel and delete old pending bookings
DELETE FROM Bookings 
WHERE BookingStatus = 'Pending' 
AND BookingDate < CURDATE();

-- Delete read notifications older than 30 days
DELETE FROM Notifications 
WHERE IsRead = TRUE 
AND TIMESTAMP < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- ================================================
-- SECTION 4: COMPLEX OPERATIONS
-- ================================================

-- Create a booking with payment in transaction
START TRANSACTION;

INSERT INTO Bookings (UserID, VenueID, TimeslotID, BookingDate, TotalAmount, BookingStatus)
VALUES (2, 3, 11, DATE_ADD(CURDATE(), INTERVAL 1 DAY), 1200.00, 'Pending');

SET @booking_id = LAST_INSERT_ID();

INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, PaymentDate)
VALUES (@booking_id, 1200.00, 'UPI', 'Success', CURDATE());

UPDATE Bookings 
SET BookingStatus = 'Confirmed' 
WHERE BookingID = @booking_id;

UPDATE Timeslots 
SET IsAvailable = FALSE 
WHERE TimeslotID = 11;

INSERT INTO Notifications (UserID, Message, IsRead)
VALUES (2, CONCAT('Your booking #', @booking_id, ' has been confirmed and paid.'), FALSE);

COMMIT;

-- Bulk update team captains
UPDATE Teams t
JOIN Users u ON t.CaptainID = u.UserID
SET t.CaptainID = (
    SELECT tm.UserID 
    FROM TeamMembers tm 
    WHERE tm.TeamID = t.TeamID 
    AND tm.UserID != t.CaptainID 
    LIMIT 1
)
WHERE u.Name = 'Rohit Kulkarni';  -- Change captain if Rohit leaves

-- ================================================
-- SECTION 5: DATA VALIDATION
-- ================================================

-- Fix any inconsistent data
UPDATE Bookings b
JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
SET b.TotalAmount = ts.PriceINR
WHERE ABS(b.TotalAmount - ts.PriceINR) > 0.01;

-- Update team member counts (would be automated with triggers)
-- This is manual for demonstration

-- ================================================
-- SUCCESS MESSAGE
-- ================================================

SELECT 'Simplified DML Operations completed successfully!' as Status,
       'All sample data inserted and operations executed' as Message,
       'Ready for application integration' as Details;

-- Show sample data
SELECT 'Users in system:' as Info;
SELECT u.UserID, u.Name, u.Email, u.City,
       CASE u.RoleID 
         WHEN 1 THEN 'Player' 
         WHEN 2 THEN 'Venue Owner' 
         WHEN 3 THEN 'Admin' 
       END as Role
FROM Users u
ORDER BY u.RoleID, u.UserID;

SELECT 'Available venues:' as Info;
SELECT v.VenueID, v.VenueName, v.Location, v.City, 
       s.SportName, v.PricePerHour,
       u.Name as OwnerName
FROM Venues v
JOIN Sports s ON v.SportID = s.SportID
JOIN Users u ON v.OwnerID = u.UserID
ORDER BY v.City, v.VenueName;

SELECT 'Recent bookings:' as Info;
SELECT b.BookingID, u.Name as PlayerName, v.VenueName, 
       b.BookingDate, b.TotalAmount, b.BookingStatus
FROM Bookings b
JOIN Users u ON b.UserID = u.UserID
JOIN Venues v ON b.VenueID = v.VenueID
ORDER BY b.BookingDate DESC, b.BookingID DESC;