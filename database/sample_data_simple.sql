-- TeamTango Simple Sample Data Script
-- This script will add sample data directly without clearing existing data

USE dbms_cp;

-- 1. Insert additional sports if needed
INSERT IGNORE INTO Sports (SportID, SportName, Description) VALUES
(1, 'Football', 'Association football played with feet'),
(2, 'Cricket', 'Bat and ball game played between two teams'),
(3, 'Basketball', 'Team sport played on a court with hoops'),
(4, 'Tennis', 'Racquet sport played individually or in pairs'),
(5, 'Badminton', 'Racquet sport using shuttlecocks');

-- 2. Insert Users (20 new users)
INSERT INTO Users (Name, Email, PhoneNumber, Password, RoleID) VALUES
('Rahul Sharma', 'rahul.player@gmail.com', '9876543211', '$2b$10$hashedpassword', 1),
('Priya Patel', 'priya.sports@gmail.com', '9876543212', '$2b$10$hashedpassword', 1),
('Arjun Kumar', 'arjun.cricket@gmail.com', '9876543213', '$2b$10$hashedpassword', 1),
('Sneha Reddy', 'sneha.tennis@gmail.com', '9876543214', '$2b$10$hashedpassword', 1),
('Vikram Singh', 'vikram.football@gmail.com', '9876543215', '$2b$10$hashedpassword', 1),
('Anita Joshi', 'anita.badminton@gmail.com', '9876543216', '$2b$10$hashedpassword', 1),
('Rohan Mehta', 'rohan.basketball@gmail.com', '9876543217', '$2b$10$hashedpassword', 1),
('Kavya Nair', 'kavya.volleyball@gmail.com', '9876543218', '$2b$10$hashedpassword', 1),
('Deepak Gupta', 'deepak.hockey@gmail.com', '9876543219', '$2b$10$hashedpassword', 1),
('Ritu Agarwal', 'ritu.squash@gmail.com', '9876543220', '$2b$10$hashedpassword', 1),
('Siddharth Roy', 'sid.swimming@gmail.com', '9876543221', '$2b$10$hashedpassword', 1),
('Meera Shah', 'meera.sports@gmail.com', '9876543222', '$2b$10$hashedpassword', 1),
('Kiran Rao', 'kiran.player@gmail.com', '9876543223', '$2b$10$hashedpassword', 1),
('Amit Desai', 'amit.games@gmail.com', '9876543224', '$2b$10$hashedpassword', 1),
('Pooja Bansal', 'pooja.athletics@gmail.com', '9876543225', '$2b$10$hashedpassword', 1),
('Ramesh Choudhary', 'ramesh.venues@gmail.com', '9876543301', '$2b$10$hashedpassword', 2),
('Sunita Kapoor', 'sunita.sports@gmail.com', '9876543302', '$2b$10$hashedpassword', 2),
('Madhav Bhatt', 'madhav.grounds@gmail.com', '9876543303', '$2b$10$hashedpassword', 2),
('Rekha Pandey', 'rekha.venues@gmail.com', '9876543304', '$2b$10$hashedpassword', 2),
('Suresh Yadav', 'suresh.sports@gmail.com', '9876543305', '$2b$10$hashedpassword', 2);

-- 3. Get the current max UserID to use for venue owners
SET @last_user_id = (SELECT MAX(UserID) FROM Users);

-- 4. Insert Venues (20 venues) - Using dynamic user IDs
INSERT INTO Venues (VenueName, Location, Address, City, ContactNumber, OwnerID, PricePerHour, SportID) VALUES
('Swargate Football Club', 'Swargate', 'Shop No 15, Swargate Plaza, FC Road, Pune', 'Pune', '9876543101', @last_user_id-4, 75.00, 1),
('Deccan Sports Arena', 'Deccan', 'Plot 23, Deccan Gymkhana, Pune', 'Pune', '9876543102', @last_user_id-3, 85.00, 1),
('Kothrud Football Ground', 'Kothrud', 'Survey No 45, Kothrud, Pune', 'Pune', '9876543103', @last_user_id-2, 70.00, 1),
('Wakad Soccer Field', 'Wakad', 'Hinjewadi Phase 2, Wakad, Pune', 'Pune', '9876543104', @last_user_id-1, 90.00, 1),
('Baner Football Academy', 'Baner', 'Baner Road, near IT Park, Pune', 'Pune', '9876543105', @last_user_id, 95.00, 1),
('MCA Cricket Ground', 'Gahunje', 'MCA Stadium, Gahunje, Pune', 'Pune', '9876543106', @last_user_id-4, 120.00, 2),
('Deccan Cricket Club', 'Deccan', 'Deccan Gymkhana Club, Pune', 'Pune', '9876543107', @last_user_id-3, 100.00, 2),
('Kharadi Cricket Academy', 'Kharadi', 'EON IT Park, Kharadi, Pune', 'Pune', '9876543108', @last_user_id-2, 110.00, 2),
('Aundh Cricket Ground', 'Aundh', 'Aundh-Ravet Road, Pune', 'Pune', '9876543109', @last_user_id-1, 95.00, 2),
('Viman Nagar Cricket Club', 'Viman Nagar', 'Airport Road, Viman Nagar, Pune', 'Pune', '9876543110', @last_user_id, 105.00, 2),
('Deccan Basketball Court', 'Deccan', 'Deccan College, Pune', 'Pune', '9876543111', @last_user_id-4, 60.00, 3),
('Kothrud Sports Complex', 'Kothrud', 'Kothrud Sports Complex, Pune', 'Pune', '9876543112', @last_user_id-3, 65.00, 3),
('Baner Basketball Arena', 'Baner', 'Baner Hills, Pune', 'Pune', '9876543113', @last_user_id-2, 70.00, 3),
('Wakad Court', 'Wakad', 'Wakad Sports Club, Pune', 'Pune', '9876543114', @last_user_id-1, 55.00, 3),
('Magarpatta Basketball', 'Magarpatta', 'Magarpatta City, Pune', 'Pune', '9876543115', @last_user_id, 75.00, 3),
('Deccan Gymkhana Tennis', 'Deccan', 'Deccan Gymkhana, Pune', 'Pune', '9876543116', @last_user_id-4, 80.00, 4),
('Pune Club Tennis Courts', 'Camp', 'Pune Club, Pune Cantonment', 'Pune', '9876543117', @last_user_id-3, 90.00, 4),
('Balewadi Tennis Academy', 'Balewadi', 'Balewadi Sports Complex, Pune', 'Pune', '9876543118', @last_user_id-2, 85.00, 4),
('Swargate Badminton Hall', 'Swargate', 'Tilak Road, Swargate, Pune', 'Pune', '9876543121', @last_user_id-1, 50.00, 5),
('Kothrud Shuttle Arena', 'Kothrud', 'Kothrud Sports Center, Pune', 'Pune', '9876543122', @last_user_id, 45.00, 5);

-- 5. Get venue and user ranges for subsequent inserts
SET @first_venue_id = (SELECT MIN(VenueID) FROM Venues WHERE VenueName LIKE '%Swargate Football%');
SET @first_player_id = (SELECT MIN(UserID) FROM Users WHERE Email LIKE '%rahul.player%');

-- 6. Insert Teams (15 teams)
INSERT INTO Teams (TeamName, SportID, CaptainID) VALUES
('Pune Warriors FC', 1, @first_player_id),
('Deccan Dynamos', 1, @first_player_id + 4),
('Swargate Strikers', 1, @first_player_id + 7),
('Mumbai Indians Pune', 2, @first_player_id + 2),
('Pune Superkings', 2, @first_player_id + 5),
('Deccan Chargers', 2, @first_player_id + 8),
('Pune Pistons', 3, @first_player_id + 6),
('Deccan Dunkers', 3, @first_player_id + 9),
('Kothrud Cavaliers', 3, @first_player_id + 12),
('Pune Tennis Club', 4, @first_player_id + 3),
('Deccan Racqueters', 4, @first_player_id + 13),
('Swargate Shuttlers', 5, @first_player_id + 5),
('Deccan Smashers', 5, @first_player_id + 10),
('Wakad Warriors', 5, @first_player_id + 11),
('Pune All-Stars', 1, @first_player_id + 14);

-- 7. Get first team ID for team members
SET @first_team_id = (SELECT MIN(TeamID) FROM Teams WHERE TeamName LIKE '%Pune Warriors%');

-- 8. Insert Team Members (30 memberships)
INSERT INTO TeamMembers (TeamID, UserID, JoinedDate) VALUES
(@first_team_id, @first_player_id, '2025-09-01'),
(@first_team_id, @first_player_id + 4, '2025-09-02'),
(@first_team_id + 1, @first_player_id + 4, '2025-09-05'),
(@first_team_id + 1, @first_player_id + 6, '2025-09-06'),
(@first_team_id + 3, @first_player_id + 2, '2025-09-10'),
(@first_team_id + 3, @first_player_id + 5, '2025-09-11'),
(@first_team_id + 6, @first_player_id + 6, '2025-09-15'),
(@first_team_id + 6, @first_player_id + 9, '2025-09-16'),
(@first_team_id + 9, @first_player_id + 3, '2025-09-20'),
(@first_team_id + 9, @first_player_id + 7, '2025-09-21'),
(@first_team_id + 11, @first_player_id + 5, '2025-09-25'),
(@first_team_id + 11, @first_player_id + 8, '2025-09-26'),
(@first_team_id + 12, @first_player_id + 10, '2025-09-28'),
(@first_team_id + 12, @first_player_id + 13, '2025-09-29'),
(@first_team_id + 13, @first_player_id + 11, '2025-10-01'),
(@first_team_id + 13, @first_player_id + 14, '2025-10-02'),
(@first_team_id + 14, @first_player_id + 14, '2025-10-04'),
(@first_team_id + 14, @first_player_id + 2, '2025-10-05'),
(@first_team_id + 2, @first_player_id + 7, '2025-10-07'),
(@first_team_id + 2, @first_player_id + 10, '2025-10-08');

-- 9. Insert Timeslots (25 slots)
INSERT INTO Timeslots (VenueID, Date, StartTime, EndTime, IsAvailable) VALUES
(@first_venue_id, '2025-01-15', '09:00:00', '10:00:00', TRUE),
(@first_venue_id, '2025-01-15', '10:00:00', '11:00:00', FALSE),
(@first_venue_id + 1, '2025-01-15', '08:00:00', '09:00:00', TRUE),
(@first_venue_id + 2, '2025-01-16', '07:00:00', '08:00:00', TRUE),
(@first_venue_id + 3, '2025-01-17', '06:00:00', '07:00:00', TRUE),
(@first_venue_id + 5, '2025-01-18', '09:00:00', '12:00:00', TRUE),
(@first_venue_id + 6, '2025-01-19', '08:00:00', '11:00:00', TRUE),
(@first_venue_id + 7, '2025-01-20', '15:00:00', '18:00:00', TRUE),
(@first_venue_id + 10, '2025-01-15', '18:00:00', '19:00:00', TRUE),
(@first_venue_id + 11, '2025-01-16', '19:00:00', '20:00:00', TRUE),
(@first_venue_id + 12, '2025-01-17', '20:00:00', '21:00:00', FALSE),
(@first_venue_id + 13, '2025-01-18', '17:00:00', '18:00:00', TRUE),
(@first_venue_id + 14, '2025-01-19', '21:00:00', '22:00:00', TRUE),
(@first_venue_id + 15, '2025-01-20', '08:00:00', '09:00:00', TRUE),
(@first_venue_id + 16, '2025-01-21', '09:00:00', '10:00:00', FALSE),
(@first_venue_id + 17, '2025-01-22', '10:00:00', '11:00:00', TRUE),
(@first_venue_id + 18, '2025-01-15', '19:00:00', '20:00:00', TRUE),
(@first_venue_id + 19, '2025-01-16', '20:00:00', '21:00:00', TRUE),
(@first_venue_id, '2025-01-17', '17:00:00', '18:00:00', TRUE),
(@first_venue_id + 1, '2025-01-18', '18:00:00', '19:00:00', TRUE),
(@first_venue_id + 4, '2025-01-17', '20:00:00', '21:00:00', TRUE),
(@first_venue_id + 8, '2025-01-21', '10:00:00', '13:00:00', TRUE),
(@first_venue_id + 9, '2025-01-22', '16:00:00', '19:00:00', FALSE),
(@first_venue_id + 5, '2025-01-18', '09:00:00', '12:00:00', TRUE),
(@first_venue_id + 15, '2025-01-20', '08:00:00', '09:00:00', TRUE);

-- 10. Insert Bookings (25 bookings)
INSERT INTO Bookings (UserID, VenueID, Date, StartTime, EndTime, TotalAmount, BookingStatus) VALUES
(@first_player_id, @first_venue_id, '2025-01-15', '10:00:00', '11:00:00', 75.00, 'confirmed'),
(@first_player_id + 2, @first_venue_id + 5, '2025-01-18', '14:00:00', '17:00:00', 360.00, 'confirmed'),
(@first_player_id + 3, @first_venue_id + 15, '2025-01-21', '09:00:00', '10:00:00', 90.00, 'pending'),
(@first_player_id + 4, @first_venue_id + 1, '2025-01-15', '18:00:00', '19:00:00', 85.00, 'confirmed'),
(@first_player_id + 5, @first_venue_id + 6, '2025-01-19', '08:00:00', '11:00:00', 300.00, 'confirmed'),
(@first_player_id + 6, @first_venue_id + 10, '2025-01-15', '18:00:00', '19:00:00', 60.00, 'confirmed'),
(@first_player_id + 7, @first_venue_id + 2, '2025-01-16', '19:00:00', '20:00:00', 70.00, 'pending'),
(@first_player_id + 8, @first_venue_id + 7, '2025-01-20', '15:00:00', '18:00:00', 330.00, 'confirmed'),
(@first_player_id + 9, @first_venue_id + 11, '2025-01-16', '19:00:00', '20:00:00', 65.00, 'confirmed'),
(@first_player_id + 10, @first_venue_id + 12, '2025-01-17', '20:00:00', '21:00:00', 70.00, 'cancelled'),
(@first_player_id + 11, @first_venue_id + 13, '2025-01-18', '17:00:00', '18:00:00', 55.00, 'confirmed'),
(@first_player_id + 12, @first_venue_id + 14, '2025-01-19', '21:00:00', '22:00:00', 75.00, 'confirmed'),
(@first_player_id + 13, @first_venue_id + 16, '2025-01-21', '09:00:00', '10:00:00', 90.00, 'pending'),
(@first_player_id + 14, @first_venue_id + 17, '2025-01-22', '10:00:00', '11:00:00', 85.00, 'confirmed'),
(@first_player_id, @first_venue_id + 18, '2025-01-15', '19:00:00', '20:00:00', 50.00, 'confirmed'),
(@first_player_id + 1, @first_venue_id + 19, '2025-01-16', '20:00:00', '21:00:00', 45.00, 'confirmed'),
(@first_player_id + 2, @first_venue_id, '2025-01-17', '17:00:00', '18:00:00', 75.00, 'confirmed'),
(@first_player_id + 3, @first_venue_id + 3, '2025-01-17', '06:00:00', '07:00:00', 90.00, 'pending'),
(@first_player_id + 4, @first_venue_id + 4, '2025-01-17', '20:00:00', '21:00:00', 95.00, 'confirmed'),
(@first_player_id + 5, @first_venue_id + 8, '2025-01-21', '10:00:00', '13:00:00', 285.00, 'confirmed'),
(@first_player_id + 6, @first_venue_id + 9, '2025-01-22', '16:00:00', '19:00:00', 315.00, 'cancelled'),
(@first_player_id + 7, @first_venue_id + 5, '2025-01-18', '09:00:00', '12:00:00', 360.00, 'confirmed'),
(@first_player_id + 8, @first_venue_id + 15, '2025-01-20', '08:00:00', '09:00:00', 80.00, 'confirmed'),
(@first_player_id + 9, @first_venue_id + 10, '2025-01-16', '18:00:00', '19:00:00', 60.00, 'pending'),
(@first_player_id + 10, @first_venue_id + 11, '2025-01-17', '19:00:00', '20:00:00', 65.00, 'confirmed');

-- Get the first booking ID for payments
SET @first_booking_id = (SELECT MIN(BookingID) FROM Bookings WHERE UserID = @first_player_id);

-- 11. Insert Payments (20 payments)
INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, TransactionDate) VALUES
(@first_booking_id, 75.00, 'credit_card', 'completed', '2025-01-10'),
(@first_booking_id + 1, 360.00, 'upi', 'completed', '2025-01-12'),
(@first_booking_id + 3, 85.00, 'debit_card', 'completed', '2025-01-13'),
(@first_booking_id + 4, 300.00, 'upi', 'completed', '2025-01-14'),
(@first_booking_id + 5, 60.00, 'credit_card', 'completed', '2025-01-14'),
(@first_booking_id + 7, 330.00, 'upi', 'completed', '2025-01-15'),
(@first_booking_id + 8, 65.00, 'debit_card', 'completed', '2025-01-16'),
(@first_booking_id + 10, 55.00, 'upi', 'completed', '2025-01-17'),
(@first_booking_id + 11, 75.00, 'credit_card', 'completed', '2025-01-18'),
(@first_booking_id + 13, 85.00, 'upi', 'completed', '2025-01-19'),
(@first_booking_id + 14, 50.00, 'debit_card', 'completed', '2025-01-14'),
(@first_booking_id + 15, 45.00, 'upi', 'completed', '2025-01-15'),
(@first_booking_id + 16, 75.00, 'credit_card', 'completed', '2025-01-16'),
(@first_booking_id + 18, 95.00, 'upi', 'completed', '2025-01-16'),
(@first_booking_id + 19, 285.00, 'debit_card', 'completed', '2025-01-20'),
(@first_booking_id + 21, 360.00, 'upi', 'completed', '2025-01-17'),
(@first_booking_id + 22, 80.00, 'credit_card', 'completed', '2025-01-19'),
(@first_booking_id + 24, 65.00, 'upi', 'completed', '2025-01-16'),
(@first_booking_id + 2, 90.00, 'upi', 'pending', '2025-01-20'),
(@first_booking_id + 6, 70.00, 'credit_card', 'pending', '2025-01-16');

-- 12. Insert Feedback (20 feedback entries)
INSERT INTO Feedback (UserID, VenueID, Rating, Comment, FeedbackDate) VALUES
(@first_player_id, @first_venue_id, 5, 'Excellent football ground with great facilities!', '2025-01-16'),
(@first_player_id + 2, @first_venue_id + 5, 4, 'Good cricket ground, but could use better lighting.', '2025-01-19'),
(@first_player_id + 4, @first_venue_id + 1, 5, 'Amazing venue with top-notch maintenance.', '2025-01-16'),
(@first_player_id + 5, @first_venue_id + 6, 4, 'Decent cricket facilities, friendly staff.', '2025-01-20'),
(@first_player_id + 6, @first_venue_id + 10, 3, 'Basketball court is okay, needs better flooring.', '2025-01-16'),
(@first_player_id + 8, @first_venue_id + 7, 5, 'Outstanding cricket academy with professional coaches.', '2025-01-21'),
(@first_player_id + 9, @first_venue_id + 11, 4, 'Good sports complex, well-organized.', '2025-01-17'),
(@first_player_id + 11, @first_venue_id + 13, 4, 'Nice court, good for casual games.', '2025-01-19'),
(@first_player_id + 12, @first_venue_id + 14, 5, 'Excellent basketball facilities, highly recommended!', '2025-01-20'),
(@first_player_id + 14, @first_venue_id + 17, 4, 'Great tennis academy, good coaching staff.', '2025-01-23'),
(@first_player_id, @first_venue_id + 18, 3, 'Badminton hall is decent, but ventilation could be better.', '2025-01-16'),
(@first_player_id + 1, @first_venue_id + 19, 4, 'Good shuttle arena, reasonable prices.', '2025-01-17'),
(@first_player_id + 2, @first_venue_id, 5, 'Love playing here! Great atmosphere.', '2025-01-18'),
(@first_player_id + 5, @first_venue_id + 8, 4, 'Nice cricket ground, well-maintained pitch.', '2025-01-22'),
(@first_player_id + 7, @first_venue_id + 5, 5, 'Perfect venue for cricket matches!', '2025-01-19'),
(@first_player_id + 8, @first_venue_id + 15, 4, 'Good tennis courts, needs better net quality.', '2025-01-21'),
(@first_player_id + 10, @first_venue_id + 11, 3, 'Average facilities, could be improved.', '2025-01-18'),
(@first_player_id + 3, @first_venue_id + 15, 5, 'Excellent tennis facilities and coaching!', '2025-01-22'),
(@first_player_id + 13, @first_venue_id + 16, 4, 'Great tennis club with good amenities.', '2025-01-22'),
(@first_player_id + 4, @first_venue_id + 1, 5, 'Always a pleasure to play at this venue!', '2025-01-17');

-- 13. Insert Notifications (25 notifications)
INSERT INTO Notifications (UserID, Title, Message, NotificationType, IsRead, CreatedAt) VALUES
(@first_player_id, 'Booking Confirmed', 'Your booking at Swargate Football Club has been confirmed for Jan 15.', 'booking', FALSE, '2025-01-10 14:30:00'),
(@first_player_id + 2, 'Payment Successful', 'Payment of ₹360 for MCA Cricket Ground booking completed.', 'payment', TRUE, '2025-01-12 16:45:00'),
(@first_player_id + 3, 'New Team Invitation', 'You have been invited to join Pune Tennis Club team.', 'team', FALSE, '2025-01-13 10:15:00'),
(@first_player_id + 4, 'Match Reminder', 'Your match with Deccan Dynamos is scheduled for tomorrow.', 'match', TRUE, '2025-01-14 18:00:00'),
(@first_player_id + 5, 'Venue Update', 'Deccan Cricket Club has updated their facilities.', 'venue', FALSE, '2025-01-14 12:30:00'),
(@first_player_id + 6, 'Booking Confirmed', 'Your booking at Deccan Basketball Court confirmed.', 'booking', TRUE, '2025-01-14 19:20:00'),
(@first_player_id + 7, 'Team Captain Update', 'You are now the captain of Swargate Strikers.', 'team', FALSE, '2025-01-15 11:45:00'),
(@first_player_id + 8, 'Payment Reminder', 'Please complete payment for your Kharadi Cricket booking.', 'payment', FALSE, '2025-01-15 09:30:00'),
(@first_player_id + 9, 'New Venue Available', 'Kothrud Sports Complex is now available for booking.', 'venue', TRUE, '2025-01-16 14:15:00'),
(@first_player_id + 10, 'Match Result', 'Deccan Smashers won the badminton match 21-19.', 'match', TRUE, '2025-01-16 20:30:00'),
(@first_player_id + 11, 'Booking Cancelled', 'Your booking at Wakad Court has been cancelled.', 'booking', FALSE, '2025-01-17 08:45:00'),
(@first_player_id + 12, 'Team Practice', 'Team practice scheduled at Magarpatta Basketball tomorrow.', 'team', FALSE, '2025-01-17 16:20:00'),
(@first_player_id + 13, 'Payment Successful', 'Payment of ₹55 completed for Wakad Court booking.', 'payment', TRUE, '2025-01-17 19:10:00'),
(@first_player_id + 14, 'New Member Added', 'Welcome to Pune All-Stars! Your membership is now active.', 'team', FALSE, '2025-01-18 13:25:00'),
(@first_player_id, 'Venue Feedback', 'Thank you for rating Swargate Badminton Hall.', 'feedback', TRUE, '2025-01-16 21:15:00'),
(@first_player_id + 1, 'Special Offer', 'Get 20% off on weekend bookings at all football venues.', 'promotion', FALSE, '2025-01-19 10:00:00'),
(@first_player_id + 2, 'Tournament Announcement', 'Cricket tournament registration now open!', 'tournament', FALSE, '2025-01-19 15:30:00'),
(@first_player_id + 3, 'Booking Reminder', 'Your tennis court booking is tomorrow at 9 AM.', 'reminder', TRUE, '2025-01-20 18:45:00'),
(@first_player_id + 4, 'Team Meeting', 'Team meeting scheduled for this Saturday at 6 PM.', 'team', FALSE, '2025-01-20 12:20:00'),
(@first_player_id + 5, 'Weather Alert', 'Rain expected tomorrow, outdoor bookings may be affected.', 'weather', TRUE, '2025-01-21 07:30:00'),
(@first_player_id + 6, 'New Coach Available', 'Professional basketball coach now available for training.', 'coaching', FALSE, '2025-01-21 14:50:00'),
(@first_player_id + 7, 'Maintenance Notice', 'Kothrud Football Ground will be under maintenance on Jan 25.', 'maintenance', FALSE, '2025-01-22 09:15:00'),
(@first_player_id + 8, 'Achievement Unlock', 'Congratulations! You have played 10 matches this month.', 'achievement', TRUE, '2025-01-22 17:40:00'),
(@first_player_id + 9, 'Booking Confirmation', 'Your regular slot at Deccan Basketball Court is confirmed.', 'booking', FALSE, '2025-01-22 20:25:00'),
(@first_player_id + 10, 'Team Update', 'Deccan Smashers practice venue changed to Kothrud Shuttle Arena.', 'team', FALSE, '2025-01-23 11:30:00');

SELECT 'Sample data insertion completed successfully!' as Status;
SELECT COUNT(*) as TotalUsers FROM Users;
SELECT COUNT(*) as TotalVenues FROM Venues;  
SELECT COUNT(*) as TotalTeams FROM Teams;
SELECT COUNT(*) as TotalBookings FROM Bookings;
SELECT COUNT(*) as TotalPayments FROM Payments;