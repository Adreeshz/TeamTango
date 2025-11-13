

USE dbms_cp;

DELIMITER //

-- ================================================
-- SECTION 1: USER MANAGEMENT PROCEDURES
-- ================================================

-- Procedure: Register a new user
CREATE PROCEDURE RegisterUser(
    IN p_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255),
    IN p_phone VARCHAR(15),
    IN p_city VARCHAR(100),
    IN p_role_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM Users WHERE Email = p_email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email already registered';
    END IF;
    
    -- Insert new user
    INSERT INTO Users (Name, Email, Password, PhoneNumber, City, RoleID)
    VALUES (p_name, p_email, p_password, p_phone, p_city, p_role_id);
    
    COMMIT;
    
    SELECT 'User registered successfully!' as Message, LAST_INSERT_ID() as UserID;
END //

-- Procedure: User login validation
CREATE PROCEDURE LoginUser(
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_role_id INT;
    DECLARE v_name VARCHAR(100);
    
    -- Find user with email and password
    SELECT UserID, Name, RoleID 
    INTO v_user_id, v_name, v_role_id
    FROM Users 
    WHERE Email = p_email AND Password = p_password;
    
    IF v_user_id IS NULL THEN
        SELECT 'Invalid credentials' as Status, NULL as UserID, NULL as Name, NULL as Role;
    ELSE
        SELECT 'Login successful' as Status, v_user_id as UserID, v_name as Name, v_role_id as RoleID;
    END IF;
END //

-- Procedure: Update user profile
CREATE PROCEDURE UpdateUserProfile(
    IN p_user_id INT,
    IN p_name VARCHAR(100),
    IN p_phone VARCHAR(15),
    IN p_city VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    END IF;
    
    -- Update user information
    UPDATE Users 
    SET Name = p_name, PhoneNumber = p_phone, City = p_city
    WHERE UserID = p_user_id;
    
    COMMIT;
    
    SELECT 'Profile updated successfully!' as Message;
END //

-- ================================================
-- SECTION 2: VENUE MANAGEMENT PROCEDURES
-- ================================================

-- Procedure: Add a new venue
CREATE PROCEDURE AddVenue(
    IN p_name VARCHAR(200),
    IN p_location VARCHAR(200),
    IN p_city VARCHAR(100),
    IN p_contact VARCHAR(15),
    IN p_owner_id INT,
    IN p_price DECIMAL(10,2),
    IN p_sport_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate owner is a venue owner
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = p_owner_id AND RoleID = 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid venue owner';
    END IF;
    
    -- Insert new venue
    INSERT INTO Venues (VenueName, Location, City, ContactNumber, OwnerID, PricePerHour, SportID)
    VALUES (p_name, p_location, p_city, p_contact, p_owner_id, p_price, p_sport_id);
    
    COMMIT;
    
    SELECT 'Venue added successfully!' as Message, LAST_INSERT_ID() as VenueID;
END //

-- Procedure: Update venue pricing
CREATE PROCEDURE UpdateVenuePricing(
    IN p_venue_id INT,
    IN p_new_price DECIMAL(10,2),
    IN p_owner_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check if venue belongs to the owner
    IF NOT EXISTS (SELECT 1 FROM Venues WHERE VenueID = p_venue_id AND OwnerID = p_owner_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Venue not found or access denied';
    END IF;
    
    -- Update venue pricing
    UPDATE Venues 
    SET PricePerHour = p_new_price
    WHERE VenueID = p_venue_id;
    
    -- Update existing available timeslots with new pricing
    UPDATE Timeslots 
    SET PriceINR = p_new_price
    WHERE VenueID = p_venue_id AND IsAvailable = TRUE AND SlotDate >= CURDATE();
    
    COMMIT;
    
    SELECT 'Venue pricing updated successfully!' as Message;
END //

-- ================================================
-- SECTION 3: BOOKING PROCEDURES
-- ================================================

-- Procedure: Create a new booking
CREATE PROCEDURE CreateBooking(
    IN p_user_id INT,
    IN p_venue_id INT,
    IN p_timeslot_id INT,
    IN p_booking_date DATE
)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_available BOOLEAN;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check if timeslot is available
    SELECT PriceINR, IsAvailable 
    INTO v_price, v_available
    FROM Timeslots 
    WHERE TimeslotID = p_timeslot_id AND VenueID = p_venue_id;
    
    IF v_available IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Timeslot not found';
    END IF;
    
    IF v_available = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Timeslot not available';
    END IF;
    
    -- Create booking
    INSERT INTO Bookings (UserID, VenueID, TimeslotID, BookingDate, TotalAmount, BookingStatus)
    VALUES (p_user_id, p_venue_id, p_timeslot_id, p_booking_date, v_price, 'Pending');
    
    -- Mark timeslot as unavailable
    UPDATE Timeslots 
    SET IsAvailable = FALSE 
    WHERE TimeslotID = p_timeslot_id;
    
    -- Create notification for user
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (p_user_id, CONCAT('Booking created successfully for ', p_booking_date), FALSE);
    
    COMMIT;
    
    SELECT 'Booking created successfully!' as Message, LAST_INSERT_ID() as BookingID, v_price as Amount;
END //

-- Procedure: Cancel a booking
CREATE PROCEDURE CancelBooking(
    IN p_booking_id INT,
    IN p_user_id INT
)
BEGIN
    DECLARE v_timeslot_id INT;
    DECLARE v_booking_status VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get booking details
    SELECT TimeslotID, BookingStatus 
    INTO v_timeslot_id, v_booking_status
    FROM Bookings 
    WHERE BookingID = p_booking_id AND UserID = p_user_id;
    
    IF v_timeslot_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found or access denied';
    END IF;
    
    IF v_booking_status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking already cancelled';
    END IF;
    
    -- Update booking status
    UPDATE Bookings 
    SET BookingStatus = 'Cancelled'
    WHERE BookingID = p_booking_id;
    
    -- Make timeslot available again
    UPDATE Timeslots 
    SET IsAvailable = TRUE 
    WHERE TimeslotID = v_timeslot_id;
    
    -- Create notification
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (p_user_id, CONCAT('Booking #', p_booking_id, ' has been cancelled'), FALSE);
    
    COMMIT;
    
    SELECT 'Booking cancelled successfully!' as Message;
END //

-- ================================================
-- SECTION 4: PAYMENT PROCEDURES
-- ================================================

-- Procedure: Process payment for booking
CREATE PROCEDURE ProcessPayment(
    IN p_booking_id INT,
    IN p_amount DECIMAL(10,2),
    IN p_payment_method VARCHAR(20),
    IN p_user_id INT
)
BEGIN
    DECLARE v_booking_amount DECIMAL(10,2);
    DECLARE v_booking_user_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate booking
    SELECT TotalAmount, UserID 
    INTO v_booking_amount, v_booking_user_id
    FROM Bookings 
    WHERE BookingID = p_booking_id;
    
    IF v_booking_amount IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
    END IF;
    
    IF v_booking_user_id != p_user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Access denied';
    END IF;
    
    IF ABS(v_booking_amount - p_amount) > 0.01 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment amount mismatch';
    END IF;
    
    -- Create payment record
    INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, PaymentDate)
    VALUES (p_booking_id, p_amount, p_payment_method, 'Success', CURDATE());
    
    -- Update booking status
    UPDATE Bookings 
    SET BookingStatus = 'Confirmed'
    WHERE BookingID = p_booking_id;
    
    -- Create notification
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (p_user_id, CONCAT('Payment successful for booking #', p_booking_id), FALSE);
    
    COMMIT;
    
    SELECT 'Payment processed successfully!' as Message, LAST_INSERT_ID() as PaymentID;
END //

-- ================================================
-- SECTION 5: TEAM MANAGEMENT PROCEDURES
-- ================================================

-- Procedure: Get team members
CREATE PROCEDURE GetTeamMembers(IN teamId INT)
BEGIN
    SELECT 
        u.UserID,
        u.Name as MemberName,
        u.Email,
        u.PhoneNumber,
        u.Gender,
        u.Address,
        tm.JoinedDate,
        CASE 
            WHEN u.UserID = t.CaptainID
            THEN 'Captain'
            ELSE 'Member'
        END as Role
    FROM TeamMembers tm
    JOIN Users u ON tm.UserID = u.UserID
    JOIN Teams t ON tm.TeamID = t.TeamID
    WHERE tm.TeamID = teamId
    ORDER BY 
        CASE WHEN u.UserID = t.CaptainID THEN 0 ELSE 1 END,
        tm.JoinedDate;
END //

-- ================================================
-- SECTION 6: TIMESLOT MANAGEMENT PROCEDURES
-- ================================================

-- Procedure: Create timeslots for a venue
CREATE PROCEDURE CreateTimeslots(
    IN p_venue_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_start_time TIME,
    IN p_end_time TIME,
    IN p_owner_id INT
)
BEGIN
    DECLARE v_current_date DATE;
    DECLARE v_price DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate venue ownership
    SELECT PricePerHour INTO v_price
    FROM Venues 
    WHERE VenueID = p_venue_id AND OwnerID = p_owner_id;
    
    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Venue not found or access denied';
    END IF;
    
    -- Create timeslots for each date
    SET v_current_date = p_start_date;
    
    WHILE v_current_date <= p_end_date DO
        INSERT INTO Timeslots (VenueID, SlotDate, StartTime, EndTime, PriceINR, IsAvailable)
        VALUES (p_venue_id, v_current_date, p_start_time, p_end_time, v_price, TRUE);
        
        SET v_current_date = DATE_ADD(v_current_date, INTERVAL 1 DAY);
    END WHILE;
    
    COMMIT;
    
    SELECT 'Timeslots created successfully!' as Message, 
           DATEDIFF(p_end_date, p_start_date) + 1 as SlotsCreated;
END //

-- ================================================
-- SECTION 7: REPORTING PROCEDURES
-- ================================================

-- Procedure: Get venue revenue report
CREATE PROCEDURE GetVenueRevenueReport(
    IN p_owner_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        v.VenueID,
        v.VenueName,
        s.SportName,
        COUNT(b.BookingID) as TotalBookings,
        SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN b.TotalAmount ELSE 0 END) as Revenue,
        SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as CollectedAmount
    FROM Venues v
    INNER JOIN Sports s ON v.SportID = s.SportID
    LEFT JOIN Bookings b ON v.VenueID = b.VenueID 
        AND b.BookingDate BETWEEN p_start_date AND p_end_date
    LEFT JOIN Payments p ON b.BookingID = p.BookingID
    WHERE v.OwnerID = p_owner_id
    GROUP BY v.VenueID, v.VenueName, s.SportName
    ORDER BY Revenue DESC;
END //

-- Procedure: Get player activity report
CREATE PROCEDURE GetPlayerActivity(
    IN p_user_id INT
)
BEGIN
    SELECT 
        'Teams' as Category,
        COUNT(tm.TeamID) as Count,
        GROUP_CONCAT(t.TeamName SEPARATOR ', ') as Details
    FROM TeamMembers tm
    INNER JOIN Teams t ON tm.TeamID = t.TeamID
    WHERE tm.UserID = p_user_id
    
    UNION ALL
    
    SELECT 
        'Bookings' as Category,
        COUNT(b.BookingID) as Count,
        CONCAT('Total Spent: ₹', COALESCE(SUM(b.TotalAmount), 0)) as Details
    FROM Bookings b
    WHERE b.UserID = p_user_id
    
    UNION ALL
    
    SELECT 
        'Matches' as Category,
        COUNT(DISTINCT m.MatchID) as Count,
        'Upcoming and completed matches' as Details
    FROM Matches m
    INNER JOIN Teams t ON (m.Team1ID = t.TeamID OR m.Team2ID = t.TeamID)
    INNER JOIN TeamMembers tm ON t.TeamID = tm.TeamID
    WHERE tm.UserID = p_user_id;
END //

-- ================================================
-- SECTION 8: UTILITY PROCEDURES
-- ================================================

-- Procedure: Search venues by criteria
CREATE PROCEDURE SearchVenues(
    IN p_city VARCHAR(100),
    IN p_sport_name VARCHAR(100),
    IN p_max_price DECIMAL(10,2),
    IN p_date DATE
)
BEGIN
    SELECT 
        v.VenueID,
        v.VenueName,
        v.Location,
        v.City,
        s.SportName,
        v.PricePerHour,
        u.Name as OwnerName,
        COUNT(ts.TimeslotID) as AvailableSlots
    FROM Venues v
    INNER JOIN Sports s ON v.SportID = s.SportID
    INNER JOIN Users u ON v.OwnerID = u.UserID
    LEFT JOIN Timeslots ts ON v.VenueID = ts.VenueID 
        AND ts.IsAvailable = TRUE 
        AND ts.SlotDate = p_date
    WHERE 
        (p_city IS NULL OR v.City = p_city)
        AND (p_sport_name IS NULL OR s.SportName = p_sport_name)
        AND (p_max_price IS NULL OR v.PricePerHour <= p_max_price)
    GROUP BY v.VenueID, v.VenueName, v.Location, v.City, s.SportName, v.PricePerHour, u.Name
    HAVING AvailableSlots > 0 OR p_date IS NULL
    ORDER BY v.PricePerHour, v.VenueName;
END //

-- Procedure: Get available slots for a venue
CREATE PROCEDURE GetAvailableSlots(
    IN p_venue_id INT,
    IN p_date DATE
)
BEGIN
    SELECT 
        ts.TimeslotID,
        ts.SlotDate,
        ts.StartTime,
        ts.EndTime,
        ts.PriceINR,
        v.VenueName,
        s.SportName
    FROM Timeslots ts
    INNER JOIN Venues v ON ts.VenueID = v.VenueID
    INNER JOIN Sports s ON v.SportID = s.SportID
    WHERE ts.VenueID = p_venue_id
        AND ts.SlotDate = p_date
        AND ts.IsAvailable = TRUE
    ORDER BY ts.StartTime;
END //

DELIMITER ;

-- ================================================
-- SUCCESS MESSAGE
-- ================================================

SELECT 'Simplified Stored Procedures created successfully!' as Status,
       'All essential business logic procedures ready' as Message,
       'Procedures cover user, venue, booking, team, and payment operations' as Details;

-- Test a simple procedure
CALL SearchVenues('Pune', NULL, 2000.00, CURDATE());