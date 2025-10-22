

USE dbms_cp;

DELIMITER //

-- ================================================
-- SECTION 1: AUDIT TRIGGERS
-- ================================================

-- Trigger: Log user creation
CREATE TRIGGER tr_user_insert_audit
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (NEW.UserID, 'INSERT', 'Users', NOW());
END //

-- Trigger: Log user updates
CREATE TRIGGER tr_user_update_audit
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (NEW.UserID, 'UPDATE', 'Users', NOW());
END //

-- Trigger: Log venue creation
CREATE TRIGGER tr_venue_insert_audit
AFTER INSERT ON Venues
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (NEW.OwnerID, 'INSERT', 'Venues', NOW());
END //

-- Trigger: Log booking creation
CREATE TRIGGER tr_booking_insert_audit
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (NEW.UserID, 'INSERT', 'Bookings', NOW());
END //

-- ================================================
-- SECTION 2: NOTIFICATION TRIGGERS
-- ================================================

-- Trigger: Send notification when user registers
CREATE TRIGGER tr_user_welcome_notification
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    DECLARE welcome_message TEXT;
    
    SET welcome_message = CASE NEW.RoleID
        WHEN 1 THEN 'Welcome to TeamTango! Start exploring venues and join teams.'
        WHEN 2 THEN 'Welcome to TeamTango! You can now list your venues and manage bookings.'
        WHEN 3 THEN 'Admin access granted. Welcome to TeamTango administration.'
        ELSE 'Welcome to TeamTango!'
    END;
    
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (NEW.UserID, welcome_message, FALSE);
END //

-- Trigger: Notify user when booking is created
CREATE TRIGGER tr_booking_notification
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE venue_name VARCHAR(200);
    DECLARE notification_msg TEXT;
    
    -- Get venue name
    SELECT VenueName INTO venue_name
    FROM Venues WHERE VenueID = NEW.VenueID;
    
    SET notification_msg = CONCAT('Your booking at ', venue_name, ' for ', NEW.BookingDate, ' has been created.');
    
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (NEW.UserID, notification_msg, FALSE);
END //

-- Trigger: Notify venue owner when booking is made
CREATE TRIGGER tr_booking_owner_notification
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE owner_id INT;
    DECLARE venue_name VARCHAR(200);
    DECLARE player_name VARCHAR(100);
    DECLARE notification_msg TEXT;
    
    -- Get venue owner and venue name
    SELECT v.OwnerID, v.VenueName INTO owner_id, venue_name
    FROM Venues v WHERE v.VenueID = NEW.VenueID;
    
    -- Get player name
    SELECT Name INTO player_name
    FROM Users WHERE UserID = NEW.UserID;
    
    SET notification_msg = CONCAT('New booking at ', venue_name, ' by ', player_name, ' for ', NEW.BookingDate);
    
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (owner_id, notification_msg, FALSE);
END //

-- Trigger: Notify when payment is successful
CREATE TRIGGER tr_payment_success_notification
AFTER INSERT ON Payments
FOR EACH ROW
BEGIN
    DECLARE user_id INT;
    DECLARE notification_msg TEXT;
    
    IF NEW.PaymentStatus = 'Success' THEN
        -- Get user ID from booking
        SELECT UserID INTO user_id
        FROM Bookings WHERE BookingID = NEW.BookingID;
        
        SET notification_msg = CONCAT('Payment of ₹', NEW.Amount, ' processed successfully for booking #', NEW.BookingID);
        
        INSERT INTO Notifications (UserID, Message, IsRead)
        VALUES (user_id, notification_msg, FALSE);
    END IF;
END //

-- ================================================
-- SECTION 3: DATA VALIDATION TRIGGERS
-- ================================================

-- Trigger: Validate booking amount matches timeslot price
CREATE TRIGGER tr_booking_amount_validation
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE slot_price DECIMAL(10,2);
    
    -- Get timeslot price
    SELECT PriceINR INTO slot_price
    FROM Timeslots WHERE TimeslotID = NEW.TimeslotID;
    
    -- Validate amount
    IF ABS(NEW.TotalAmount - slot_price) > 0.01 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Booking amount does not match timeslot price';
    END IF;
END //

-- Trigger: Validate team captain is a player
CREATE TRIGGER tr_team_captain_validation
BEFORE INSERT ON Teams
FOR EACH ROW
BEGIN
    DECLARE captain_role INT;
    
    -- Get captain's role
    SELECT RoleID INTO captain_role
    FROM Users WHERE UserID = NEW.CaptainID;
    
    -- Validate captain is a player
    IF captain_role != 1 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Team captain must be a player (RoleID = 1)';
    END IF;
END //

-- Trigger: Validate venue owner role
CREATE TRIGGER tr_venue_owner_validation
BEFORE INSERT ON Venues
FOR EACH ROW
BEGIN
    DECLARE owner_role INT;
    
    -- Get owner's role
    SELECT RoleID INTO owner_role
    FROM Users WHERE UserID = NEW.OwnerID;
    
    -- Validate owner is venue owner
    IF owner_role != 2 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Venue owner must have RoleID = 2';
    END IF;
END //

-- ================================================
-- SECTION 4: BUSINESS LOGIC TRIGGERS
-- ================================================

-- Trigger: Auto-confirm booking when payment is successful
CREATE TRIGGER tr_auto_confirm_booking
AFTER UPDATE ON Payments
FOR EACH ROW
BEGIN
    IF NEW.PaymentStatus = 'Success' AND OLD.PaymentStatus != 'Success' THEN
        UPDATE Bookings 
        SET BookingStatus = 'Confirmed'
        WHERE BookingID = NEW.BookingID AND BookingStatus = 'Pending';
    END IF;
END //

-- Trigger: Make timeslot unavailable when booking is confirmed
CREATE TRIGGER tr_booking_confirm_timeslot
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF NEW.BookingStatus = 'Confirmed' AND OLD.BookingStatus != 'Confirmed' THEN
        UPDATE Timeslots 
        SET IsAvailable = FALSE
        WHERE TimeslotID = NEW.TimeslotID;
    END IF;
END //

-- Trigger: Make timeslot available when booking is cancelled
CREATE TRIGGER tr_booking_cancel_timeslot
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF NEW.BookingStatus = 'Cancelled' AND OLD.BookingStatus != 'Cancelled' THEN
        UPDATE Timeslots 
        SET IsAvailable = TRUE
        WHERE TimeslotID = NEW.TimeslotID;
    END IF;
END //

-- ================================================
-- SECTION 5: CLEANUP TRIGGERS
-- ================================================

-- Trigger: Clean up team members when team is deleted
CREATE TRIGGER tr_team_delete_cleanup
BEFORE DELETE ON Teams
FOR EACH ROW
BEGIN
    -- Remove all team members
    DELETE FROM TeamMembers WHERE TeamID = OLD.TeamID;
    
    -- Log the deletion
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (OLD.CaptainID, 'DELETE', 'Teams', NOW());
END //

-- Trigger: Clean up timeslots when venue is deleted
CREATE TRIGGER tr_venue_delete_cleanup
BEFORE DELETE ON Venues
FOR EACH ROW
BEGIN
    -- Remove all available timeslots (keep booked ones for history)
    DELETE FROM Timeslots 
    WHERE VenueID = OLD.VenueID AND IsAvailable = TRUE;
    
    -- Log the deletion
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (OLD.OwnerID, 'DELETE', 'Venues', NOW());
END //

-- ================================================
-- SECTION 6: MATCH-RELATED TRIGGERS
-- ================================================

-- Trigger: Validate match teams are different
CREATE TRIGGER tr_match_team_validation
BEFORE INSERT ON Matches
FOR EACH ROW
BEGIN
    IF NEW.Team1ID = NEW.Team2ID THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Team1 and Team2 must be different';
    END IF;
END //

-- Trigger: Validate match teams play the same sport
CREATE TRIGGER tr_match_sport_validation
BEFORE INSERT ON Matches
FOR EACH ROW
BEGIN
    DECLARE team1_sport INT;
    DECLARE team2_sport INT;
    
    -- Get sports for both teams
    SELECT SportID INTO team1_sport FROM Teams WHERE TeamID = NEW.Team1ID;
    SELECT SportID INTO team2_sport FROM Teams WHERE TeamID = NEW.Team2ID;
    
    -- Validate same sport
    IF team1_sport != team2_sport THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Both teams must play the same sport';
    END IF;
END //

-- Trigger: Notify teams when match is scheduled
CREATE TRIGGER tr_match_team_notification
AFTER INSERT ON Matches
FOR EACH ROW
BEGIN
    DECLARE team1_captain INT;
    DECLARE team2_captain INT;
    DECLARE notification_msg TEXT;
    
    -- Get team captains
    SELECT CaptainID INTO team1_captain FROM Teams WHERE TeamID = NEW.Team1ID;
    SELECT CaptainID INTO team2_captain FROM Teams WHERE TeamID = NEW.Team2ID;
    
    SET notification_msg = CONCAT('Match scheduled: ', NEW.MatchTitle, ' on ', NEW.MatchDate, ' at ', NEW.MatchTime);
    
    -- Notify both captains
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (team1_captain, notification_msg, FALSE);
    
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (team2_captain, notification_msg, FALSE);
END //

-- ================================================
-- SECTION 7: FEEDBACK TRIGGERS
-- ================================================

-- Trigger: Validate feedback rating range
CREATE TRIGGER tr_feedback_rating_validation
BEFORE INSERT ON Feedback
FOR EACH ROW
BEGIN
    IF NEW.Rating < 1 OR NEW.Rating > 5 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;
END //

-- Trigger: Notify venue owner of new feedback
CREATE TRIGGER tr_feedback_owner_notification
AFTER INSERT ON Feedback
FOR EACH ROW
BEGIN
    DECLARE owner_id INT;
    DECLARE venue_name VARCHAR(200);
    DECLARE player_name VARCHAR(100);
    DECLARE notification_msg TEXT;
    
    -- Get venue owner and details
    SELECT v.OwnerID, v.VenueName INTO owner_id, venue_name
    FROM Venues v WHERE v.VenueID = NEW.VenueID;
    
    -- Get player name
    SELECT Name INTO player_name
    FROM Users WHERE UserID = NEW.UserID;
    
    SET notification_msg = CONCAT('New ', NEW.Rating, '-star review from ', player_name, ' for ', venue_name);
    
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (owner_id, notification_msg, FALSE);
END //

-- ================================================
-- SECTION 8: TIMESLOT TRIGGERS
-- ================================================

-- Trigger: Validate timeslot times
CREATE TRIGGER tr_timeslot_time_validation
BEFORE INSERT ON Timeslots
FOR EACH ROW
BEGIN
    IF NEW.StartTime >= NEW.EndTime THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Start time must be before end time';
    END IF;
    
    IF NEW.SlotDate < CURDATE() THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot create timeslots for past dates';
    END IF;
END //

-- Trigger: Auto-set timeslot price from venue
CREATE TRIGGER tr_timeslot_auto_price
BEFORE INSERT ON Timeslots
FOR EACH ROW
BEGIN
    DECLARE venue_price DECIMAL(10,2);
    
    -- Get venue price if not provided
    IF NEW.PriceINR IS NULL OR NEW.PriceINR = 0 THEN
        SELECT PricePerHour INTO venue_price
        FROM Venues WHERE VenueID = NEW.VenueID;
        
        SET NEW.PriceINR = venue_price;
    END IF;
END //

DELIMITER ;

-- ================================================
-- SUCCESS MESSAGE
-- ================================================

SELECT 'Simplified Triggers created successfully!' as Status,
       'All essential triggers for automation and validation' as Message,
       'Triggers handle audit, notifications, validation, and business logic' as Details;

-- Show created triggers
SELECT 'Database Triggers:' as Info;
SHOW TRIGGERS;

-- Test trigger by inserting a user
INSERT INTO Users (Name, Email, Password, PhoneNumber, City, RoleID)
VALUES ('Test User', 'test@example.com', 'password123', '1234567890', 'Pune', 1);

-- Check if audit log and notification were created
SELECT 'Recent Audit Logs:' as Info;
SELECT * FROM AuditLog ORDER BY Timestamp DESC LIMIT 3;

SELECT 'Recent Notifications:' as Info;
SELECT * FROM Notifications ORDER BY NotificationID DESC LIMIT 3;