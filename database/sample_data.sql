-- TeamTango Sample Data Generation Script
-- This script will populate the database with realistic sample data

USE dbms_cp;

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
DELETE FROM Users WHERE UserID != 1;  -- Keep admin user

-- Reset auto increment
ALTER TABLE Users AUTO_INCREMENT = 2;
ALTER TABLE Sports AUTO_INCREMENT = 1;
ALTER TABLE Venues AUTO_INCREMENT = 1;
ALTER TABLE Teams AUTO_INCREMENT = 1;
ALTER TABLE Bookings AUTO_INCREMENT = 1;
ALTER TABLE Payments AUTO_INCREMENT = 1;

-- 1. Sports Data (10 sports)
INSERT INTO Sports (SportName, Description) VALUES
('Football', 'Association football played with feet'),
('Cricket', 'Bat and ball game played between two teams'),
('Basketball', 'Team sport played on a court with hoops'),
('Tennis', 'Racquet sport played individually or in pairs'),
('Badminton', 'Racquet sport using shuttlecocks'),
('Table Tennis', 'Indoor racquet sport on a table'),
('Volleyball', 'Team sport with net separation'),
('Hockey', 'Team sport played with sticks and ball'),
('Squash', 'Racquet sport in enclosed court'),
('Swimming', 'Water-based sport and exercise');

-- 2. Users Data (25 users total: Players, Venue Owners)
-- Players (15 players - role ID 1)
INSERT INTO Users (Name, Email, PhoneNumber, Password, RoleID) VALUES
('Rahul Sharma', 'rahul.player@gmail.com', '9876543211', '$2b$10$example_hash_for_password123', 1),
('Priya Patel', 'priya.sports@gmail.com', '9876543212', '$2b$10$example_hash_for_password123', 1),
('Arjun Kumar', 'arjun.cricket@gmail.com', '9876543213', '$2b$10$example_hash_for_password123', 1),
('Sneha Reddy', 'sneha.tennis@gmail.com', '9876543214', '$2b$10$example_hash_for_password123', 1),
('Vikram Singh', 'vikram.football@gmail.com', '9876543215', '$2b$10$example_hash_for_password123', 1),
('Anita Joshi', 'anita.badminton@gmail.com', '9876543216', '$2b$10$example_hash_for_password123', 1),
('Rohan Mehta', 'rohan.basketball@gmail.com', '9876543217', '$2b$10$example_hash_for_password123', 1),
('Kavya Nair', 'kavya.volleyball@gmail.com', '9876543218', '$2b$10$example_hash_for_password123', 1),
('Deepak Gupta', 'deepak.hockey@gmail.com', '9876543219', '$2b$10$example_hash_for_password123', 1),
('Ritu Agarwal', 'ritu.squash@gmail.com', '9876543220', '$2b$10$example_hash_for_password123', 1),
('Siddharth Roy', 'sid.swimming@gmail.com', '9876543221', '$2b$10$example_hash_for_password123', 1),
('Meera Shah', 'meera.sports@gmail.com', '9876543222', '$2b$10$example_hash_for_password123', 1),
('Kiran Rao', 'kiran.player@gmail.com', '9876543223', '$2b$10$example_hash_for_password123', 1),
('Amit Desai', 'amit.games@gmail.com', '9876543224', '$2b$10$example_hash_for_password123', 1),
('Pooja Bansal', 'pooja.athletics@gmail.com', '9876543225', '$2b$10$example_hash_for_password123', 1),

-- Venue Owners (10 venue owners - role ID 2)
('Ramesh Choudhary', 'ramesh.venues@gmail.com', '9876543301', '$2b$10$example_hash_for_password123', 2),
('Sunita Kapoor', 'sunita.sports@gmail.com', '9876543302', '$2b$10$example_hash_for_password123', 2),
('Madhav Bhatt', 'madhav.grounds@gmail.com', '9876543303', '$2b$10$example_hash_for_password123', 2),
('Rekha Pandey', 'rekha.venues@gmail.com', '9876543304', '$2b$10$example_hash_for_password123', 2),
('Suresh Yadav', 'suresh.sports@gmail.com', '9876543305', '$2b$10$example_hash_for_password123', 2),
('Nisha Tiwari', 'nisha.grounds@gmail.com', '9876543306', '$2b$10$example_hash_for_password123', 2),
('Prakash Jain', 'prakash.venues@gmail.com', '9876543307', '$2b$10$example_hash_for_password123', 2),
('Geeta Malhotra', 'geeta.sports@gmail.com', '9876543308', '$2b$10$example_hash_for_password123', 2),
('Harish Verma', 'harish.grounds@gmail.com', '9876543309', '$2b$10$example_hash_for_password123', 2),
('Vidya Sinha', 'vidya.venues@gmail.com', '9876543310', '$2b$10$example_hash_for_password123', 2);

-- 3. Venues Data (25 venues across different sports and locations)
INSERT INTO Venues (VenueName, Location, Address, City, ContactNumber, OwnerID, PricePerHour, SportID) VALUES
-- Football Venues
('Swargate Football Club', 'Swargate', 'Shop No 15, Swargate Plaza, FC Road, Pune', 'Pune', '9876543101', 17, 75.00, 1),
('Deccan Sports Arena', 'Deccan', 'Plot 23, Deccan Gymkhana, Pune', 'Pune', '9876543102', 18, 85.00, 1),
('Kothrud Football Ground', 'Kothrud', 'Survey No 45, Kothrud, Pune', 'Pune', '9876543103', 19, 70.00, 1),
('Wakad Soccer Field', 'Wakad', 'Hinjewadi Phase 2, Wakad, Pune', 'Pune', '9876543104', 20, 90.00, 1),
('Baner Football Academy', 'Baner', 'Baner Road, near IT Park, Pune', 'Pune', '9876543105', 21, 95.00, 1),

-- Cricket Venues
('MCA Cricket Ground', 'Gahunje', 'MCA Stadium, Gahunje, Pune', 'Pune', '9876543106', 22, 120.00, 2),
('Deccan Cricket Club', 'Deccan', 'Deccan Gymkhana Club, Pune', 'Pune', '9876543107', 17, 100.00, 2),
('Kharadi Cricket Academy', 'Kharadi', 'EON IT Park, Kharadi, Pune', 'Pune', '9876543108', 23, 110.00, 2),
('Aundh Cricket Ground', 'Aundh', 'Aundh-Ravet Road, Pune', 'Pune', '9876543109', 24, 95.00, 2),
('Viman Nagar Cricket Club', 'Viman Nagar', 'Airport Road, Viman Nagar, Pune', 'Pune', '9876543110', 25, 105.00, 2),

-- Basketball Courts
('Deccan Basketball Court', 'Deccan', 'Deccan College, Pune', 'Pune', '9876543111', 18, 60.00, 3),
('Kothrud Sports Complex', 'Kothrud', 'Kothrud Sports Complex, Pune', 'Pune', '9876543112', 19, 65.00, 3),
('Baner Basketball Arena', 'Baner', 'Baner Hills, Pune', 'Pune', '9876543113', 26, 70.00, 3),
('Wakad Court', 'Wakad', 'Wakad Sports Club, Pune', 'Pune', '9876543114', 20, 55.00, 3),
('Magarpatta Basketball', 'Magarpatta', 'Magarpatta City, Pune', 'Pune', '9876543115', 21, 75.00, 3),

-- Tennis Courts
('Deccan Gymkhana Tennis', 'Deccan', 'Deccan Gymkhana, Pune', 'Pune', '9876543116', 17, 80.00, 4),
('Pune Club Tennis Courts', 'Camp', 'Pune Club, Pune Cantonment', 'Pune', '9876543117', 22, 90.00, 4),
('Balewadi Tennis Academy', 'Balewadi', 'Balewadi Sports Complex, Pune', 'Pune', '9876543118', 23, 85.00, 4),
('Kharadi Tennis Club', 'Kharadi', 'Kharadi Sports Club, Pune', 'Pune', '9876543119', 24, 75.00, 4),
('Aundh Tennis Courts', 'Aundh', 'Aundh Sports Complex, Pune', 'Pune', '9876543120', 25, 70.00, 4),

-- Badminton Courts
('Swargate Badminton Hall', 'Swargate', 'Tilak Road, Swargate, Pune', 'Pune', '9876543121', 26, 50.00, 5),
('Kothrud Shuttle Arena', 'Kothrud', 'Kothrud Sports Center, Pune', 'Pune', '9876543122', 19, 45.00, 5),
('Deccan Badminton Club', 'Deccan', 'FC Road, Deccan, Pune', 'Pune', '9876543123', 18, 55.00, 5),
('Wakad Badminton Center', 'Wakad', 'Wakad IT Hub, Pune', 'Pune', '9876543124', 20, 60.00, 5),
('Baner Shuttle Court', 'Baner', 'Baner Road, Pune', 'Pune', '9876543125', 21, 50.00, 5);

-- 4. Teams Data (20 teams across different sports)
INSERT INTO Teams (TeamName, SportID, CaptainID) VALUES
-- Football Teams
('Pune Warriors FC', 1, 2),
('Deccan Dynamos', 1, 5),
('Swargate Strikers', 1, 8),
('Kothrud Kings', 1, 11),

-- Cricket Teams
('Mumbai Indians Pune', 2, 3),
('Pune Superkings', 2, 6),
('Deccan Chargers', 2, 9),
('Maharashtra Tigers', 2, 12),

-- Basketball Teams
('Pune Pistons', 3, 7),
('Deccan Dunkers', 3, 10),
('Kothrud Cavaliers', 3, 13),
('Baner Blazers', 3, 16),

-- Tennis Teams
('Pune Tennis Club', 4, 4),
('Deccan Racqueters', 4, 14),
('Kharadi Tennis Academy', 4, 15),

-- Badminton Teams
('Swargate Shuttlers', 5, 6),
('Deccan Smashers', 5, 11),
('Wakad Warriors', 5, 12),

-- Mixed Sports Teams  
('Pune All-Stars', 1, 2),
('Deccan Sports Club', 2, 3);

-- 5. Team Members Data
INSERT INTO TeamMembers (TeamID, UserID, JoinedDate) VALUES
-- Team 1 members (Pune Warriors FC)
(1, 2, '2025-09-01'), (1, 5, '2025-09-02'), (1, 8, '2025-09-03'), (1, 11, '2025-09-04'),
-- Team 2 members (Deccan Dynamos)
(2, 5, '2025-09-05'), (2, 7, '2025-09-06'), (2, 9, '2025-09-07'), (2, 13, '2025-09-08'),
-- Team 3 members (Mumbai Indians Pune)
(5, 3, '2025-09-10'), (5, 6, '2025-09-11'), (5, 12, '2025-09-12'), (5, 15, '2025-09-13'),
-- Team 4 members (Pune Pistons)
(9, 7, '2025-09-15'), (9, 10, '2025-09-16'), (9, 14, '2025-09-17'), (9, 16, '2025-09-18'),
-- Team 5 members (Pune Tennis Club)
(13, 4, '2025-09-20'), (13, 8, '2025-09-21'), (13, 12, '2025-09-22'),
-- Additional members for other teams
(16, 6, '2025-09-25'), (16, 9, '2025-09-26'), (16, 13, '2025-09-27'),
(17, 11, '2025-09-28'), (17, 14, '2025-09-29'), (17, 16, '2025-09-30'),
(18, 12, '2025-10-01'), (18, 15, '2025-10-02'), (18, 2, '2025-10-03');

-- 6. Timeslots Data (30 timeslots for different venues and dates)
INSERT INTO Timeslots (VenueID, SlotDate, StartTime, EndTime, PriceINR, IsAvailable) VALUES
-- Football venue timeslots
(1, '2025-10-25', '06:00:00', '08:00:00', 150.00, 1),
(1, '2025-10-25', '08:00:00', '10:00:00', 150.00, 1),
(1, '2025-10-25', '16:00:00', '18:00:00', 150.00, 0),
(1, '2025-10-26', '06:00:00', '08:00:00', 150.00, 1),
(1, '2025-10-26', '18:00:00', '20:00:00', 150.00, 1),

-- Cricket venue timeslots  
(6, '2025-10-25', '09:00:00', '12:00:00', 360.00, 1),
(6, '2025-10-25', '14:00:00', '17:00:00', 360.00, 0),
(6, '2025-10-26', '09:00:00', '12:00:00', 360.00, 1),
(7, '2025-10-25', '10:00:00', '13:00:00', 300.00, 1),
(7, '2025-10-26', '15:00:00', '18:00:00', 300.00, 1),

-- Basketball court timeslots
(11, '2025-10-25', '07:00:00', '09:00:00', 120.00, 1),
(11, '2025-10-25', '19:00:00', '21:00:00', 120.00, 0),
(12, '2025-10-25', '08:00:00', '10:00:00', 130.00, 1),
(13, '2025-10-25', '17:00:00', '19:00:00', 140.00, 1),
(14, '2025-10-26', '06:00:00', '08:00:00', 110.00, 1),

-- Tennis court timeslots
(16, '2025-10-25', '06:30:00', '08:30:00', 160.00, 1),
(17, '2025-10-25', '09:00:00', '11:00:00', 180.00, 0),
(18, '2025-10-25', '16:30:00', '18:30:00', 170.00, 1),
(19, '2025-10-26', '07:00:00', '09:00:00', 150.00, 1),
(20, '2025-10-26', '18:00:00', '20:00:00', 140.00, 1),

-- Badminton court timeslots
(21, '2025-10-25', '06:00:00', '07:00:00', 50.00, 1),
(21, '2025-10-25', '19:00:00', '20:00:00', 50.00, 0),
(22, '2025-10-25', '07:30:00', '08:30:00', 45.00, 1),
(23, '2025-10-25', '18:00:00', '19:00:00', 55.00, 1),
(24, '2025-10-26', '06:30:00', '07:30:00', 60.00, 1),
(25, '2025-10-26', '19:30:00', '20:30:00', 50.00, 1),

-- Weekend slots
(1, '2025-10-27', '08:00:00', '10:00:00', 150.00, 1),
(6, '2025-10-27', '10:00:00', '13:00:00', 360.00, 1),
(11, '2025-10-27', '15:00:00', '17:00:00', 120.00, 1),
(21, '2025-10-27', '18:00:00', '19:00:00', 50.00, 1);

-- 7. Bookings Data (25 bookings with various statuses)
INSERT INTO Bookings (UserID, VenueID, TimeslotID, BookingDate, TotalAmount, BookingStatus) VALUES
(2, 1, 1, '2025-10-25', 150.00, 'Confirmed'),
(3, 6, 6, '2025-10-25', 360.00, 'Confirmed'), 
(4, 16, 16, '2025-10-25', 160.00, 'Pending'),
(5, 1, 3, '2025-10-25', 150.00, 'Confirmed'),
(6, 21, 22, '2025-10-25', 50.00, 'Confirmed'),
(7, 11, 12, '2025-10-25', 120.00, 'Confirmed'),
(8, 17, 17, '2025-10-25', 180.00, 'Confirmed'),
(9, 6, 7, '2025-10-25', 360.00, 'Pending'),
(10, 13, 14, '2025-10-25', 140.00, 'Confirmed'),
(11, 1, 2, '2025-10-25', 150.00, 'Confirmed'),
(12, 22, 23, '2025-10-25', 45.00, 'Confirmed'),
(13, 12, 13, '2025-10-25', 130.00, 'Pending'),
(14, 18, 18, '2025-10-25', 170.00, 'Confirmed'),
(15, 24, 25, '2025-10-26', 60.00, 'Confirmed'),
(16, 20, 20, '2025-10-26', 140.00, 'Pending'),
(2, 1, 4, '2025-10-26', 150.00, 'Confirmed'),
(3, 7, 10, '2025-10-26', 300.00, 'Confirmed'),
(4, 19, 19, '2025-10-26', 150.00, 'Confirmed'),
(5, 15, 15, '2025-10-26', 110.00, 'Confirmed'),
(6, 25, 26, '2025-10-26', 50.00, 'Pending'),
(7, 1, 27, '2025-10-27', 150.00, 'Confirmed'),
(8, 6, 28, '2025-10-27', 360.00, 'Confirmed'),
(9, 11, 29, '2025-10-27', 120.00, 'Pending'),
(10, 21, 30, '2025-10-27', 50.00, 'Confirmed'),
(11, 1, 5, '2025-10-26', 150.00, 'Confirmed');

-- 8. Payments Data (20 payments for confirmed bookings)
INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, PaymentDate) VALUES
(1, 150.00, 'UPI', 'Success', '2025-10-21 10:30:00'),
(2, 360.00, 'Card', 'Success', '2025-10-21 11:15:00'),
(4, 150.00, 'Cash', 'Success', '2025-10-21 12:00:00'),
(5, 50.00, 'UPI', 'Success', '2025-10-21 14:30:00'),
(6, 120.00, 'Card', 'Success', '2025-10-21 15:45:00'),
(7, 180.00, 'UPI', 'Success', '2025-10-21 16:20:00'),
(9, 140.00, 'Cash', 'Success', '2025-10-21 17:10:00'),
(10, 150.00, 'UPI', 'Success', '2025-10-21 18:00:00'),
(11, 45.00, 'Card', 'Success', '2025-10-21 19:15:00'),
(13, 170.00, 'UPI', 'Success', '2025-10-21 20:30:00'),
(14, 60.00, 'Cash', 'Success', '2025-10-22 09:00:00'),
(16, 150.00, 'UPI', 'Success', '2025-10-22 10:30:00'),
(17, 300.00, 'Card', 'Success', '2025-10-22 11:45:00'),
(18, 150.00, 'UPI', 'Success', '2025-10-22 14:20:00'),
(19, 110.00, 'Cash', 'Success', '2025-10-22 15:30:00'),
(21, 150.00, 'UPI', 'Success', '2025-10-22 16:45:00'),
(22, 360.00, 'Card', 'Success', '2025-10-22 18:00:00'),
(24, 50.00, 'UPI', 'Success', '2025-10-22 19:30:00'),
(25, 150.00, 'Cash', 'Success', '2025-10-22 20:15:00'),
-- Some pending payments
(3, 160.00, 'Card', 'Pending', '2025-10-23 10:00:00');

-- 9. Matches Data (15 matches between teams)
INSERT INTO Matches (MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime, Team1Score, Team2Score, MatchStatus) VALUES
('Pune Derby', 1, 2, 1, '2025-11-01', '18:00:00', 2, 1, 'Completed'),
('Cricket Championship', 5, 6, 6, '2025-11-02', '10:00:00', 185, 178, 'Completed'),
('Basketball Showdown', 9, 10, 11, '2025-11-03', '19:00:00', 78, 82, 'Completed'),
('Tennis Tournament Semi', 13, 14, 16, '2025-11-04', '16:00:00', 6, 4, 'Completed'),
('Badminton Finals', 16, 17, 21, '2025-11-05', '18:30:00', 21, 18, 'Completed'),
('Football League Match', 3, 4, 2, '2025-11-08', '17:00:00', NULL, NULL, 'Scheduled'),
('Cricket Super League', 7, 8, 7, '2025-11-09', '09:30:00', NULL, NULL, 'Scheduled'),
('Basketball Championship', 11, 12, 12, '2025-11-10', '20:00:00', NULL, NULL, 'Scheduled'),
('Weekend Football', 1, 3, 3, '2025-11-11', '16:30:00', NULL, NULL, 'Scheduled'),
('Tennis Doubles', 13, 15, 17, '2025-11-12', '15:00:00', NULL, NULL, 'Scheduled'),
('Badminton League', 18, 16, 23, '2025-11-13', '19:00:00', NULL, NULL, 'Scheduled'),
('Inter-Club Cricket', 5, 7, 8, '2025-11-15', '11:00:00', NULL, NULL, 'Scheduled'),
('Basketball Derby', 9, 11, 13, '2025-11-16', '18:00:00', NULL, NULL, 'Scheduled'),
('Football Cup Final', 1, 4, 1, '2025-11-20', '19:00:00', NULL, NULL, 'Scheduled'),
('All-Stars Match', 19, 20, 6, '2025-11-22', '14:00:00', NULL, NULL, 'Scheduled');

-- 10. Feedback Data (20 feedback entries)
INSERT INTO Feedback (UserID, VenueID, Rating, Comment, FeedbackDate) VALUES
(2, 1, 5, 'Excellent football ground with good facilities!', '2025-10-21 21:00:00'),
(3, 6, 4, 'Great cricket ground, pitch could be better maintained.', '2025-10-21 21:30:00'),
(4, 16, 5, 'Perfect tennis court, well maintained and clean.', '2025-10-22 08:00:00'),
(5, 1, 4, 'Good ground but parking is limited.', '2025-10-22 09:00:00'),
(6, 21, 5, 'Best badminton hall in the area!', '2025-10-22 10:00:00'),
(7, 11, 3, 'Basketball court is okay, lighting needs improvement.', '2025-10-22 11:00:00'),
(8, 17, 5, 'Fantastic tennis facilities with modern equipment.', '2025-10-22 12:00:00'),
(9, 6, 4, 'Good cricket venue, booking process was smooth.', '2025-10-22 13:00:00'),
(10, 13, 4, 'Nice basketball court, reasonable pricing.', '2025-10-22 14:00:00'),
(11, 1, 5, 'Love playing here, great atmosphere!', '2025-10-22 15:00:00'),
(12, 22, 4, 'Good badminton facility, could use better ventilation.', '2025-10-22 16:00:00'),
(13, 12, 3, 'Court is decent but could be cleaner.', '2025-10-22 17:00:00'),
(14, 18, 5, 'Excellent tennis court, highly recommend!', '2025-10-22 18:00:00'),
(15, 24, 4, 'Good badminton court, friendly staff.', '2025-10-22 19:00:00'),
(16, 20, 4, 'Nice tennis facilities, good value for money.', '2025-10-22 20:00:00'),
(2, 2, 5, 'Another great football venue!', '2025-10-23 08:00:00'),
(3, 7, 4, 'Solid cricket ground for practice sessions.', '2025-10-23 09:00:00'),
(4, 19, 5, 'Perfect for tennis matches and practice.', '2025-10-23 10:00:00'),
(5, 15, 3, 'Basketball court is average, could improve amenities.', '2025-10-23 11:00:00'),
(6, 25, 5, 'Excellent badminton facility with great coaching!', '2025-10-23 12:00:00');

-- 11. Notifications Data (25 notifications for various users)
INSERT INTO Notifications (UserID, Title, Message, NotificationDate, IsRead) VALUES
(2, 'Booking Confirmed', 'Your football ground booking for Oct 25 has been confirmed.', '2025-10-21 10:35:00', 1),
(3, 'Payment Successful', 'Payment of ₹360 for cricket ground booking completed.', '2025-10-21 11:20:00', 1),
(4, 'Booking Pending', 'Your tennis court booking is pending payment.', '2025-10-21 12:05:00', 0),
(5, 'Match Reminder', 'Football match tomorrow at Deccan Sports Arena.', '2025-10-31 18:00:00', 0),
(6, 'Team Invitation', 'You have been invited to join Swargate Shuttlers.', '2025-10-20 14:30:00', 1),
(7, 'Venue Available', 'New basketball court available in Baner area.', '2025-10-19 16:45:00', 1),
(8, 'Payment Reminder', 'Please complete payment for your tennis booking.', '2025-10-23 09:00:00', 0),
(9, 'Booking Confirmed', 'Cricket ground booking confirmed for Oct 27.', '2025-10-22 18:30:00', 1),
(10, 'Match Result', 'Your team won the basketball match 78-82!', '2025-11-03 20:30:00', 0),
(11, 'New Venue', 'Check out the new football ground in Wakad.', '2025-10-18 12:00:00', 1),
(12, 'Team Practice', 'Badminton team practice scheduled for this weekend.', '2025-10-24 15:00:00', 0),
(13, 'Booking Available', 'Your preferred tennis slot is now available.', '2025-10-25 08:00:00', 0),
(14, 'Payment Confirmed', 'Payment successful for basketball court booking.', '2025-10-21 17:15:00', 1),
(15, 'Match Scheduled', 'Tennis tournament match on Nov 12 at 3 PM.', '2025-11-10 10:00:00', 0),
(16, 'Venue Maintenance', 'Tennis court will be under maintenance tomorrow.', '2025-10-24 20:00:00', 1),
(2, 'Weekly Summary', 'You have 2 bookings this week.', '2025-10-21 06:00:00', 1),
(3, 'Team Captain', 'You are now captain of Mumbai Indians Pune!', '2025-09-10 12:00:00', 1),
(4, 'Venue Review', 'Please review your recent tennis court booking.', '2025-10-22 21:00:00', 0),
(5, 'Special Offer', '20% discount on weekend football bookings!', '2025-10-23 14:00:00', 0),
(6, 'Match Victory', 'Congratulations on winning the badminton match!', '2025-11-05 19:00:00', 0),
(7, 'Court Booking', 'Basketball court booking for Nov 16 confirmed.', '2025-11-15 10:00:00', 0),
(8, 'Tournament Entry', 'Tennis tournament registration now open.', '2025-10-20 11:00:00', 1),
(9, 'Weather Alert', 'Rain expected, outdoor cricket match may be postponed.', '2025-11-08 07:00:00', 0),
(10, 'Membership Renewal', 'Basketball club membership expires next month.', '2025-10-25 16:00:00', 0),
(11, 'New Feature', 'Check out the new mobile app for easier bookings!', '2025-10-22 12:00:00', 1);

SELECT 'Sample data inserted successfully!' as Status;