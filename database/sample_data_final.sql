-- TeamTango Sample Data Generation Script (Final Corrected Version)
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

-- 1. Sports Data (ensure we have all sports)
INSERT IGNORE INTO Sports (SportID, SportName, Description) VALUES
(1, 'Football', 'Association football played with feet'),
(2, 'Cricket', 'Bat and ball game played between two teams'),
(3, 'Basketball', 'Team sport played on a court with hoops'),
(4, 'Tennis', 'Racquet sport played individually or in pairs'),
(5, 'Badminton', 'Racquet sport using shuttlecocks'),
(6, 'Volleyball', 'Team sport played with a net');

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

-- 4. Timeslots Data (multiple slots per venue)
INSERT INTO Timeslots (VenueID, Date, StartTime, EndTime, IsAvailable) VALUES
-- Football venues (1-5)
(1, '2025-01-15', '09:00:00', '10:00:00', TRUE),
(1, '2025-01-15', '10:00:00', '11:00:00', FALSE),
(1, '2025-01-15', '17:00:00', '18:00:00', TRUE),
(2, '2025-01-15', '08:00:00', '09:00:00', TRUE),
(2, '2025-01-15', '18:00:00', '19:00:00', TRUE),
(3, '2025-01-16', '07:00:00', '08:00:00', TRUE),
(3, '2025-01-16', '19:00:00', '20:00:00', FALSE),
(4, '2025-01-17', '06:00:00', '07:00:00', TRUE),
(5, '2025-01-17', '20:00:00', '21:00:00', TRUE),
-- Cricket venues (6-10) - Need to add VenueIDs 6-10 first
(6, '2025-01-18', '09:00:00', '12:00:00', TRUE),
(6, '2025-01-18', '14:00:00', '17:00:00', FALSE),
(7, '2025-01-19', '08:00:00', '11:00:00', TRUE),
(8, '2025-01-20', '15:00:00', '18:00:00', TRUE),
(9, '2025-01-21', '10:00:00', '13:00:00', TRUE),
(10, '2025-01-22', '16:00:00', '19:00:00', FALSE),
-- Basketball venues (11-15)
(11, '2025-01-15', '18:00:00', '19:00:00', TRUE),
(12, '2025-01-16', '19:00:00', '20:00:00', TRUE),
(13, '2025-01-17', '20:00:00', '21:00:00', FALSE),
(14, '2025-01-18', '17:00:00', '18:00:00', TRUE),
(15, '2025-01-19', '21:00:00', '22:00:00', TRUE),
-- Tennis venues (16-18)
(16, '2025-01-20', '08:00:00', '09:00:00', TRUE),
(17, '2025-01-21', '09:00:00', '10:00:00', FALSE),
(18, '2025-01-22', '10:00:00', '11:00:00', TRUE),
-- Badminton venues (19-20)
(19, '2025-01-15', '19:00:00', '20:00:00', TRUE),
(20, '2025-01-16', '20:00:00', '21:00:00', TRUE);

-- 5. Teams Data (15 teams)
INSERT INTO Teams (TeamName, SportID, CaptainID) VALUES
('Pune Warriors FC', 1, 2),
('Deccan Dynamos', 1, 6),
('Swargate Strikers', 1, 9),
('Mumbai Indians Pune', 2, 3),
('Pune Superkings', 2, 7),
('Deccan Chargers', 2, 10),
('Pune Pistons', 3, 8),
('Deccan Dunkers', 3, 11),
('Kothrud Cavaliers', 3, 14),
('Pune Tennis Club', 4, 4),
('Deccan Racqueters', 4, 15),
('Swargate Shuttlers', 5, 7),
('Deccan Smashers', 5, 12),
('Wakad Warriors', 5, 13),
('Pune All-Stars', 1, 16);

-- 6. Team Members Data (30 memberships)
INSERT INTO TeamMembers (TeamID, UserID, JoinedDate) VALUES
(1, 2, '2025-09-01'), (1, 6, '2025-09-02'), (1, 9, '2025-09-03'),
(2, 6, '2025-09-05'), (2, 8, '2025-09-06'), (2, 10, '2025-09-07'),
(4, 3, '2025-09-10'), (4, 7, '2025-09-11'), (4, 13, '2025-09-12'),
(7, 8, '2025-09-15'), (7, 11, '2025-09-16'), (7, 15, '2025-09-17'),
(10, 4, '2025-09-20'), (10, 9, '2025-09-21'), (10, 13, '2025-09-22'),
(12, 7, '2025-09-25'), (12, 10, '2025-09-26'), (12, 14, '2025-09-27'),
(13, 12, '2025-09-28'), (13, 15, '2025-09-29'), (13, 16, '2025-09-30'),
(14, 13, '2025-10-01'), (14, 16, '2025-10-02'), (14, 2, '2025-10-03'),
(15, 16, '2025-10-04'), (15, 3, '2025-10-05'), (15, 4, '2025-10-06'),
(3, 9, '2025-10-07'), (3, 12, '2025-10-08'), (3, 16, '2025-10-09');

-- 7. Bookings Data (25 bookings)
INSERT INTO Bookings (UserID, VenueID, Date, StartTime, EndTime, TotalAmount, BookingStatus) VALUES
(2, 1, '2025-01-15', '10:00:00', '11:00:00', 75.00, 'confirmed'),
(3, 6, '2025-01-18', '14:00:00', '17:00:00', 360.00, 'confirmed'),
(4, 16, '2025-01-21', '09:00:00', '10:00:00', 90.00, 'pending'),
(6, 2, '2025-01-15', '18:00:00', '19:00:00', 85.00, 'confirmed'),
(7, 7, '2025-01-19', '08:00:00', '11:00:00', 300.00, 'confirmed'),
(8, 11, '2025-01-15', '18:00:00', '19:00:00', 60.00, 'confirmed'),
(9, 3, '2025-01-16', '19:00:00', '20:00:00', 70.00, 'pending'),
(10, 8, '2025-01-20', '15:00:00', '18:00:00', 330.00, 'confirmed'),
(11, 12, '2025-01-16', '19:00:00', '20:00:00', 65.00, 'confirmed'),
(12, 13, '2025-01-17', '20:00:00', '21:00:00', 70.00, 'cancelled'),
(13, 14, '2025-01-18', '17:00:00', '18:00:00', 55.00, 'confirmed'),
(14, 15, '2025-01-19', '21:00:00', '22:00:00', 75.00, 'confirmed'),
(15, 17, '2025-01-21', '09:00:00', '10:00:00', 90.00, 'pending'),
(16, 18, '2025-01-22', '10:00:00', '11:00:00', 85.00, 'confirmed'),
(17, 19, '2025-01-15', '19:00:00', '20:00:00', 50.00, 'confirmed'),
(2, 20, '2025-01-16', '20:00:00', '21:00:00', 45.00, 'confirmed'),
(3, 1, '2025-01-17', '17:00:00', '18:00:00', 75.00, 'confirmed'),
(4, 4, '2025-01-17', '06:00:00', '07:00:00', 90.00, 'pending'),
(6, 5, '2025-01-17', '20:00:00', '21:00:00', 95.00, 'confirmed'),
(7, 9, '2025-01-21', '10:00:00', '13:00:00', 285.00, 'confirmed'),
(8, 10, '2025-01-22', '16:00:00', '19:00:00', 315.00, 'cancelled'),
(9, 6, '2025-01-18', '09:00:00', '12:00:00', 360.00, 'confirmed'),
(10, 16, '2025-01-20', '08:00:00', '09:00:00', 80.00, 'confirmed'),
(11, 11, '2025-01-16', '18:00:00', '19:00:00', 60.00, 'pending'),
(12, 12, '2025-01-17', '19:00:00', '20:00:00', 65.00, 'confirmed');

-- 8. Payments Data (20 payments for confirmed bookings)
INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, TransactionDate) VALUES
(1, 75.00, 'credit_card', 'completed', '2025-01-10'),
(2, 360.00, 'upi', 'completed', '2025-01-12'),
(4, 85.00, 'debit_card', 'completed', '2025-01-13'),
(5, 300.00, 'upi', 'completed', '2025-01-14'),
(6, 60.00, 'credit_card', 'completed', '2025-01-14'),
(8, 330.00, 'upi', 'completed', '2025-01-15'),
(9, 65.00, 'debit_card', 'completed', '2025-01-16'),
(11, 55.00, 'upi', 'completed', '2025-01-17'),
(12, 75.00, 'credit_card', 'completed', '2025-01-18'),
(14, 85.00, 'upi', 'completed', '2025-01-19'),
(15, 50.00, 'debit_card', 'completed', '2025-01-14'),
(16, 45.00, 'upi', 'completed', '2025-01-15'),
(17, 75.00, 'credit_card', 'completed', '2025-01-16'),
(19, 95.00, 'upi', 'completed', '2025-01-16'),
(20, 285.00, 'debit_card', 'completed', '2025-01-20'),
(22, 360.00, 'upi', 'completed', '2025-01-17'),
(23, 80.00, 'credit_card', 'completed', '2025-01-19'),
(25, 65.00, 'upi', 'completed', '2025-01-16'),
(3, 90.00, 'upi', 'pending', '2025-01-20'),
(7, 70.00, 'credit_card', 'pending', '2025-01-16');

-- 9. Feedback Data (20 feedback entries)
INSERT INTO Feedback (UserID, VenueID, Rating, Comment, FeedbackDate) VALUES
(2, 1, 5, 'Excellent football ground with great facilities!', '2025-01-16'),
(3, 6, 4, 'Good cricket ground, but could use better lighting.', '2025-01-19'),
(6, 2, 5, 'Amazing venue with top-notch maintenance.', '2025-01-16'),
(7, 7, 4, 'Decent cricket facilities, friendly staff.', '2025-01-20'),
(8, 11, 3, 'Basketball court is okay, needs better flooring.', '2025-01-16'),
(10, 8, 5, 'Outstanding cricket academy with professional coaches.', '2025-01-21'),
(11, 12, 4, 'Good sports complex, well-organized.', '2025-01-17'),
(13, 14, 4, 'Nice court, good for casual games.', '2025-01-19'),
(14, 15, 5, 'Excellent basketball facilities, highly recommended!', '2025-01-20'),
(16, 18, 4, 'Great tennis academy, good coaching staff.', '2025-01-23'),
(17, 19, 3, 'Badminton hall is decent, but ventilation could be better.', '2025-01-16'),
(2, 20, 4, 'Good shuttle arena, reasonable prices.', '2025-01-17'),
(3, 1, 5, 'Love playing here! Great atmosphere.', '2025-01-18'),
(7, 9, 4, 'Nice cricket ground, well-maintained pitch.', '2025-01-22'),
(9, 6, 5, 'Perfect venue for cricket matches!', '2025-01-19'),
(10, 16, 4, 'Good tennis courts, needs better net quality.', '2025-01-21'),
(12, 12, 3, 'Average facilities, could be improved.', '2025-01-18'),
(4, 16, 5, 'Excellent tennis facilities and coaching!', '2025-01-22'),
(15, 17, 4, 'Great tennis club with good amenities.', '2025-01-22'),
(6, 2, 5, 'Always a pleasure to play at this venue!', '2025-01-17');

-- 10. Notifications Data (25 notifications)
INSERT INTO Notifications (UserID, Title, Message, NotificationType, IsRead, CreatedAt) VALUES
(2, 'Booking Confirmed', 'Your booking at Swargate Football Club has been confirmed for Jan 15.', 'booking', FALSE, '2025-01-10 14:30:00'),
(3, 'Payment Successful', 'Payment of ₹360 for MCA Cricket Ground booking completed.', 'payment', TRUE, '2025-01-12 16:45:00'),
(4, 'New Team Invitation', 'You have been invited to join Pune Tennis Club team.', 'team', FALSE, '2025-01-13 10:15:00'),
(6, 'Match Reminder', 'Your match with Deccan Dynamos is scheduled for tomorrow.', 'match', TRUE, '2025-01-14 18:00:00'),
(7, 'Venue Update', 'Deccan Cricket Club has updated their facilities.', 'venue', FALSE, '2025-01-14 12:30:00'),
(8, 'Booking Confirmed', 'Your booking at Deccan Basketball Court confirmed.', 'booking', TRUE, '2025-01-14 19:20:00'),
(9, 'Team Captain Update', 'You are now the captain of Swargate Strikers.', 'team', FALSE, '2025-01-15 11:45:00'),
(10, 'Payment Reminder', 'Please complete payment for your Kharadi Cricket booking.', 'payment', FALSE, '2025-01-15 09:30:00'),
(11, 'New Venue Available', 'Kothrud Sports Complex is now available for booking.', 'venue', TRUE, '2025-01-16 14:15:00'),
(12, 'Match Result', 'Deccan Smashers won the badminton match 21-19.', 'match', TRUE, '2025-01-16 20:30:00'),
(13, 'Booking Cancelled', 'Your booking at Wakad Court has been cancelled.', 'booking', FALSE, '2025-01-17 08:45:00'),
(14, 'Team Practice', 'Team practice scheduled at Magarpatta Basketball tomorrow.', 'team', FALSE, '2025-01-17 16:20:00'),
(15, 'Payment Successful', 'Payment of ₹55 completed for Wakad Court booking.', 'payment', TRUE, '2025-01-17 19:10:00'),
(16, 'New Member Added', 'Welcome to Pune All-Stars! Your membership is now active.', 'team', FALSE, '2025-01-18 13:25:00'),
(17, 'Venue Feedback', 'Thank you for rating Swargate Badminton Hall.', 'feedback', TRUE, '2025-01-16 21:15:00'),
(2, 'Special Offer', 'Get 20% off on weekend bookings at all football venues.', 'promotion', FALSE, '2025-01-19 10:00:00'),
(3, 'Tournament Announcement', 'Cricket tournament registration now open!', 'tournament', FALSE, '2025-01-19 15:30:00'),
(4, 'Booking Reminder', 'Your tennis court booking is tomorrow at 9 AM.', 'reminder', TRUE, '2025-01-20 18:45:00'),
(6, 'Team Meeting', 'Team meeting scheduled for this Saturday at 6 PM.', 'team', FALSE, '2025-01-20 12:20:00'),
(7, 'Weather Alert', 'Rain expected tomorrow, outdoor bookings may be affected.', 'weather', TRUE, '2025-01-21 07:30:00'),
(8, 'New Coach Available', 'Professional basketball coach now available for training.', 'coaching', FALSE, '2025-01-21 14:50:00'),
(9, 'Maintenance Notice', 'Kothrud Football Ground will be under maintenance on Jan 25.', 'maintenance', FALSE, '2025-01-22 09:15:00'),
(10, 'Achievement Unlock', 'Congratulations! You have played 10 matches this month.', 'achievement', TRUE, '2025-01-22 17:40:00'),
(11, 'Booking Confirmation', 'Your regular slot at Deccan Basketball Court is confirmed.', 'booking', FALSE, '2025-01-22 20:25:00'),
(12, 'Team Update', 'Deccan Smashers practice venue changed to Kothrud Shuttle Arena.', 'team', FALSE, '2025-01-23 11:30:00');

SELECT 'Sample data inserted successfully!' as Status;
SELECT COUNT(*) as TotalUsers FROM Users;
SELECT COUNT(*) as TotalVenues FROM Venues;  
SELECT COUNT(*) as TotalTeams FROM Teams;
SELECT COUNT(*) as TotalBookings FROM Bookings;
SELECT COUNT(*) as TotalPayments FROM Payments;
SELECT COUNT(*) as TotalFeedback FROM Feedback;
SELECT COUNT(*) as TotalNotifications FROM Notifications;