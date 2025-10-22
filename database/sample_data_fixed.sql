-- TeamTango Sample Data Generation Script (Fixed)
-- This script will populate the database with realistic sample data

USE dbms_cp;

-- Temporarily disable foreign key checks
SET FOREIGN_KEY_CHECKS = 0;

-- Clear existing data (except admin user)
DELETE FROM Payments;
DELETE FROM Feedback;
DELETE FROM Notifications;
DELETE FROM Bookings;
DELETE FROM TeamMembers;
DELETE FROM Matches;
DELETE FROM Teams;
DELETE FROM Timeslots;
DELETE FROM Venues;
DELETE FROM Users WHERE UserID != 1;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Reset auto increment
ALTER TABLE Users AUTO_INCREMENT = 2;

-- 1. Sports Data (ensure we have sports)
INSERT IGNORE INTO Sports (SportID, SportName, Description) VALUES
(1, 'Football', 'Association football played with feet'),
(2, 'Cricket', 'Bat and ball game played between two teams'),
(3, 'Basketball', 'Team sport played on a court with hoops'),
(4, 'Tennis', 'Racquet sport played individually or in pairs'),
(5, 'Badminton', 'Racquet sport using shuttlecocks');

-- 2. Users Data (20 users: 15 players, 5 venue owners)
INSERT INTO Users (Name, Email, PhoneNumber, Password, RoleID) VALUES
-- Players (role ID 1)
('Rahul Sharma', 'rahul.player@gmail.com', '9876543211', '$2b$10$hash123', 1),
('Priya Patel', 'priya.sports@gmail.com', '9876543212', '$2b$10$hash123', 1),
('Arjun Kumar', 'arjun.cricket@gmail.com', '9876543213', '$2b$10$hash123', 1),
('Sneha Reddy', 'sneha.tennis@gmail.com', '9876543214', '$2b$10$hash123', 1),
('Vikram Singh', 'vikram.football@gmail.com', '9876543215', '$2b$10$hash123', 1),
('Anita Joshi', 'anita.badminton@gmail.com', '9876543216', '$2b$10$hash123', 1),
('Rohan Mehta', 'rohan.basketball@gmail.com', '9876543217', '$2b$10$hash123', 1),
('Kavya Nair', 'kavya.volleyball@gmail.com', '9876543218', '$2b$10$hash123', 1),
('Deepak Gupta', 'deepak.hockey@gmail.com', '9876543219', '$2b$10$hash123', 1),
('Ritu Agarwal', 'ritu.squash@gmail.com', '9876543220', '$2b$10$hash123', 1),
('Siddharth Roy', 'sid.swimming@gmail.com', '9876543221', '$2b$10$hash123', 1),
('Meera Shah', 'meera.sports@gmail.com', '9876543222', '$2b$10$hash123', 1),
('Kiran Rao', 'kiran.player@gmail.com', '9876543223', '$2b$10$hash123', 1),
('Amit Desai', 'amit.games@gmail.com', '9876543224', '$2b$10$hash123', 1),
('Pooja Bansal', 'pooja.athletics@gmail.com', '9876543225', '$2b$10$hash123', 1),

-- Venue Owners (role ID 2)  
('Ramesh Choudhary', 'ramesh.venues@gmail.com', '9876543301', '$2b$10$hash123', 2),
('Sunita Kapoor', 'sunita.sports@gmail.com', '9876543302', '$2b$10$hash123', 2),
('Madhav Bhatt', 'madhav.grounds@gmail.com', '9876543303', '$2b$10$hash123', 2),
('Rekha Pandey', 'rekha.venues@gmail.com', '9876543304', '$2b$10$hash123', 2),
('Suresh Yadav', 'suresh.sports@gmail.com', '9876543305', '$2b$10$hash123', 2);

-- 3. Venues Data (20 venues)
INSERT INTO Venues (VenueName, Location, Address, City, ContactNumber, OwnerID, PricePerHour, SportID) VALUES
('Swargate Football Club', 'Swargate', 'Shop No 15, Swargate Plaza, FC Road, Pune', 'Pune', '9876543101', 17, 75.00, 1),
('Deccan Sports Arena', 'Deccan', 'Plot 23, Deccan Gymkhana, Pune', 'Pune', '9876543102', 18, 85.00, 1),
('Kothrud Football Ground', 'Kothrud', 'Survey No 45, Kothrud, Pune', 'Pune', '9876543103', 19, 70.00, 1),
('Wakad Soccer Field', 'Wakad', 'Hinjewadi Phase 2, Wakad, Pune', 'Pune', '9876543104', 20, 90.00, 1),
('Baner Football Academy', 'Baner', 'Baner Road, near IT Park, Pune', 'Pune', '9876543105', 21, 95.00, 1),
('MCA Cricket Ground', 'Gahunje', 'MCA Stadium, Gahunje, Pune', 'Pune', '9876543106', 17, 120.00, 2),
('Deccan Cricket Club', 'Deccan', 'Deccan Gymkhana Club, Pune', 'Pune', '9876543107', 18, 100.00, 2),
('Kharadi Cricket Academy', 'Kharadi', 'EON IT Park, Kharadi, Pune', 'Pune', '9876543108', 19, 110.00, 2),
('Aundh Cricket Ground', 'Aundh', 'Aundh-Ravet Road, Pune', 'Pune', '9876543109', 20, 95.00, 2),
('Viman Nagar Cricket Club', 'Viman Nagar', 'Airport Road, Viman Nagar, Pune', 'Pune', '9876543110', 21, 105.00, 2),
('Deccan Basketball Court', 'Deccan', 'Deccan College, Pune', 'Pune', '9876543111', 17, 60.00, 3),
('Kothrud Sports Complex', 'Kothrud', 'Kothrud Sports Complex, Pune', 'Pune', '9876543112', 18, 65.00, 3),
('Baner Basketball Arena', 'Baner', 'Baner Hills, Pune', 'Pune', '9876543113', 19, 70.00, 3),
('Wakad Court', 'Wakad', 'Wakad Sports Club, Pune', 'Pune', '9876543114', 20, 55.00, 3),
('Magarpatta Basketball', 'Magarpatta', 'Magarpatta City, Pune', 'Pune', '9876543115', 21, 75.00, 3),
('Deccan Gymkhana Tennis', 'Deccan', 'Deccan Gymkhana, Pune', 'Pune', '9876543116', 17, 80.00, 4),
('Pune Club Tennis Courts', 'Camp', 'Pune Club, Pune Cantonment', 'Pune', '9876543117', 18, 90.00, 4),
('Balewadi Tennis Academy', 'Balewadi', 'Balewadi Sports Complex, Pune', 'Pune', '9876543118', 19, 85.00, 4),
('Swargate Badminton Hall', 'Swargate', 'Tilak Road, Swargate, Pune', 'Pune', '9876543121', 20, 50.00, 5),
('Kothrud Shuttle Arena', 'Kothrud', 'Kothrud Sports Center, Pune', 'Pune', '9876543122', 21, 45.00, 5);

-- 4. Teams Data (15 teams)
INSERT INTO Teams (TeamName, SportID, CaptainID) VALUES
('Pune Warriors FC', 1, 2),
('Deccan Dynamos', 1, 5),
('Swargate Strikers', 1, 8),
('Mumbai Indians Pune', 2, 3),
('Pune Superkings', 2, 6),
('Deccan Chargers', 2, 9),
('Pune Pistons', 3, 7),
('Deccan Dunkers', 3, 10),
('Kothrud Cavaliers', 3, 13),
('Pune Tennis Club', 4, 4),
('Deccan Racqueters', 4, 14),
('Swargate Shuttlers', 5, 6),
('Deccan Smashers', 5, 11),
('Wakad Warriors', 5, 12),
('Pune All-Stars', 1, 15);

-- 5. Team Members Data (30 memberships)
INSERT INTO TeamMembers (TeamID, UserID, JoinedDate) VALUES
(1, 2, '2025-09-01'), (1, 5, '2025-09-02'), (1, 8, '2025-09-03'),
(2, 5, '2025-09-05'), (2, 7, '2025-09-06'), (2, 9, '2025-09-07'),
(4, 3, '2025-09-10'), (4, 6, '2025-09-11'), (4, 12, '2025-09-12'),
(7, 7, '2025-09-15'), (7, 10, '2025-09-16'), (7, 14, '2025-09-17'),
(10, 4, '2025-09-20'), (10, 8, '2025-09-21'), (10, 12, '2025-09-22'),
(12, 6, '2025-09-25'), (12, 9, '2025-09-26'), (12, 13, '2025-09-27'),
(13, 11, '2025-09-28'), (13, 14, '2025-09-29'), (13, 16, '2025-09-30'),
(14, 12, '2025-10-01'), (14, 15, '2025-10-02'), (14, 2, '2025-10-03'),
(15, 15, '2025-10-04'), (15, 3, '2025-10-05'), (15, 4, '2025-10-06'),
(3, 8, '2025-10-07'), (3, 11, '2025-10-08'), (3, 16, '2025-10-09');

SELECT 'Sample data inserted successfully!' as Status;
SELECT COUNT(*) as TotalUsers FROM Users;
SELECT COUNT(*) as TotalVenues FROM Venues;  
SELECT COUNT(*) as TotalTeams FROM Teams;