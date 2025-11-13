## Booking Creation Queries:
### 1. Check Venue Availability:
```sql
SELECT VenueID, VenueName, PricePerHour 
FROM Venues 
WHERE VenueID = ?
```

### 2. Find or Create Timeslot:
```sql
-- Check if timeslot exists
SELECT TimeslotID, PriceINR, IsAvailable 
FROM Timeslots 
WHERE VenueID = ? 
  AND SlotDate = ? 
  AND StartTime = ? 
  AND EndTime = ?

-- If doesn't exist, create new timeslot
INSERT INTO Timeslots (VenueID, SlotDate, StartTime, EndTime, PriceINR, IsAvailable)
VALUES (?, ?, ?, ?, ?, 1)
```

### 3. Check for Booking Conflicts:
```sql
SELECT BookingID 
FROM Bookings 
WHERE TimeslotID = ? 
  AND BookingStatus IN ('Confirmed', 'Pending')
```

### 4. Create Booking:
```sql
INSERT INTO Bookings (UserID, VenueID, TimeslotID, BookingDate, TotalAmount, BookingStatus)
VALUES (?, ?, ?, ?, ?, 'Pending')
```

### 5. Create Pending Payment Record:
```sql
INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, PaymentDate)
VALUES (?, ?, 'Cash', 'Pending', CURDATE())
```

### 6. Mark Timeslot as Unavailable:
```sql
UPDATE Timeslots 
SET IsAvailable = 0 
WHERE TimeslotID = ?
```

### 7. Booking Creation Notification (Trigger):
```sql
DELIMITER //

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

DELIMITER ;
```

### 8. Notify Venue Owner (Trigger):
```sql
DELIMITER //

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

DELIMITER ;
```

## Reading Booking Data Queries:
### 1. All Bookings with Role-Based Filtering (Using View):
```sql
-- Using booking_details view
SELECT 
    BookingID,
    BookingDate,
    StartTime,
    EndTime,
    BookingStatus as Status,
    UserID,
    PlayerName,
    VenueName,
    VenueLocation as VenueAddress,
    TotalAmount as PaymentAmount,
    PaymentStatus
FROM booking_details
WHERE UserID = ?  -- For players
-- OR WHERE VenueID IN (SELECT VenueID FROM Venues WHERE OwnerID = ?)  -- For venue owners
-- No WHERE clause for admins (see all bookings)
ORDER BY BookingDate DESC, StartTime DESC
```

### 2. User's Own Bookings:
```sql
SELECT 
    BookingID,
    BookingDate,
    TotalAmount,
    StartTime,
    EndTime,
    BookingStatus as Status,
    VenueName,
    VenueLocation as VenueAddress,
    TotalAmount as PaymentAmount,
    PaymentStatus
FROM booking_details
WHERE UserID = ?
ORDER BY BookingDate DESC, StartTime DESC
```

### 3. Single Booking Details with Full Information:
```sql
SELECT 
    b.*,
    u.Name as PlayerName,
    u.Email as PlayerEmail,
    u.PhoneNumber as PlayerPhone,
    v.VenueName,
    v.Address as VenueAddress,
    v.OwnerID,
    vo.Name as VenueOwnerName,
    ts.SlotDate,
    ts.StartTime,
    ts.EndTime,
    p.Amount as PaymentAmount,
    p.PaymentStatus as PaymentStatus,
    p.PaymentMethod,
    f.Rating as FeedbackRating,
    f.Comment as FeedbackComments
FROM Bookings b
LEFT JOIN Users u ON b.UserID = u.UserID
LEFT JOIN Venues v ON b.VenueID = v.VenueID
LEFT JOIN Users vo ON v.OwnerID = vo.UserID
LEFT JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
LEFT JOIN Feedback f ON f.VenueID = v.VenueID AND f.UserID = b.UserID
WHERE b.BookingID = ?
```

### 4. Bookings for Specific Venue (Owner View):
```sql
SELECT 
    b.BookingID,
    b.BookingDate,
    b.BookingStatus,
    b.TotalAmount,
    ts.StartTime,
    ts.EndTime,
    u.Name as PlayerName,
    u.Email as PlayerEmail,
    u.PhoneNumber as PlayerPhone,
    p.Amount as PaymentAmount,
    p.PaymentStatus as PaymentStatus
FROM Bookings b
LEFT JOIN Users u ON b.UserID = u.UserID
LEFT JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
WHERE b.VenueID = ?
ORDER BY b.BookingDate DESC, ts.StartTime DESC
```

## Booking Update Queries:
### 1. Check Booking Ownership:
```sql
SELECT b.*, v.OwnerID 
FROM Bookings b 
LEFT JOIN Venues v ON b.VenueID = v.VenueID 
WHERE b.BookingID = ?
```

### 2. Update Booking Status (Venue Owner/Admin):
```sql
UPDATE Bookings 
SET BookingStatus = ? 
WHERE BookingID = ?
```

### 3. Update Booking Details (User - Only if Pending):
```sql
UPDATE Bookings 
SET StartTime = ?, 
    EndTime = ?, 
    TeamID = ? 
WHERE BookingID = ? 
  AND BookingStatus = 'Pending' 
  AND UserID = ?
```

### 4. Auto-Confirm Booking on Payment Success (Trigger):
```sql
DELIMITER //

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

DELIMITER ;
```

### 5. Make Timeslot Unavailable on Confirmation (Trigger):
```sql
DELIMITER //

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

DELIMITER ;
```

## Booking Cancellation Queries:
### 1. Check Cancellation Permission:
```sql
SELECT b.BookingID, b.UserID, b.BookingStatus, v.OwnerID
FROM Bookings b 
LEFT JOIN Venues v ON b.VenueID = v.VenueID 
WHERE b.BookingID = ?
```

### 2. Cancel Booking (Soft Delete):
```sql
UPDATE Bookings 
SET BookingStatus = 'Cancelled' 
WHERE BookingID = ?
```

### 3. Make Timeslot Available Again (Trigger):
```sql
DELIMITER //

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

DELIMITER ;
```

### 4. Using Stored Procedure for Cancellation:
```sql
DELIMITER //

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

DELIMITER ;

-- Call the procedure
CALL CancelBooking(?, ?)
```

## Booking Validation Queries:
### 1. Validate Booking Amount Matches Timeslot (Trigger):
```sql
DELIMITER //

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

DELIMITER ;
```

### 2. Audit Log for Booking Creation (Trigger):
```sql
DELIMITER //

CREATE TRIGGER tr_booking_insert_audit
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (NEW.UserID, 'INSERT', 'Bookings', NOW());
END //

DELIMITER ;
```

## Complete Booking Creation Procedure:
```sql
DELIMITER //

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

DELIMITER ;

-- Call the procedure
CALL CreateBooking(?, ?, ?, ?)
```
