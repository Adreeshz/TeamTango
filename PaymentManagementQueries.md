## Payment Processing Queries:
### 1. Check Booking Exists and Get Details:
```sql
SELECT 
    b.BookingID,
    b.UserID,
    b.BookingStatus,
    b.TotalAmount,
    v.VenueName
FROM Bookings b
LEFT JOIN Venues v ON b.VenueID = v.VenueID
WHERE b.BookingID = ?
```

### 2. Check for Existing Payments:
```sql
SELECT PaymentID, PaymentStatus 
FROM Payments 
WHERE BookingID = ?
```

### 3. Create New Payment Record:
```sql
INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, PaymentDate)
VALUES (?, ?, ?, 'Success', CURDATE())
```

### 4. Update Existing Payment:
```sql
UPDATE Payments 
SET Amount = ?, 
    PaymentMethod = ?, 
    PaymentStatus = ?, 
    PaymentDate = CURDATE() 
WHERE PaymentID = ?
```

### 5. Update Booking Status to Confirmed:
```sql
UPDATE Bookings 
SET BookingStatus = 'Confirmed' 
WHERE BookingID = ?
```

### 6. Payment Success Notification (Trigger):
```sql
DELIMITER //

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

DELIMITER ;
```

### 7. Complete Payment Processing Procedure:
```sql
DELIMITER //

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

DELIMITER ;

-- Call the procedure
CALL ProcessPayment(?, ?, ?, ?)
```

## Reading Payment Data Queries:
### 1. All Payments with Role-Based Filtering:
```sql
SELECT 
    p.PaymentID,
    p.BookingID,
    p.Amount,
    p.PaymentMethod,
    p.PaymentStatus as Status,
    p.PaymentDate as TransactionDate,
    b.BookingDate,
    t.StartTime,
    t.EndTime,
    b.UserID as PayerID,
    u.Name as PayerName,
    v.VenueName,
    v.OwnerID as VenueOwnerID
FROM Payments p
LEFT JOIN Bookings b ON p.BookingID = b.BookingID
LEFT JOIN Users u ON b.UserID = u.UserID
LEFT JOIN Venues v ON b.VenueID = v.VenueID
LEFT JOIN Timeslots t ON b.TimeslotID = t.TimeslotID
WHERE b.UserID = ?  -- For players
-- OR WHERE v.OwnerID = ?  -- For venue owners
-- No WHERE clause for admins (see all payments)
ORDER BY p.PaymentDate DESC
```

### 2. User's Own Payments:
```sql
SELECT 
    p.PaymentID,
    p.BookingID,
    p.Amount,
    p.PaymentMethod,
    p.PaymentStatus as Status,
    p.PaymentDate as TransactionDate,
    b.BookingDate,
    t.StartTime,
    t.EndTime,
    v.VenueName,
    v.Location as VenueAddress
FROM Payments p
LEFT JOIN Bookings b ON p.BookingID = b.BookingID
LEFT JOIN Venues v ON b.VenueID = v.VenueID
LEFT JOIN Timeslots t ON b.TimeslotID = t.TimeslotID
WHERE b.UserID = ?
ORDER BY p.PaymentDate DESC
```

### 3. Single Payment Details:
```sql
SELECT 
    p.*,
    b.BookingDate,
    t.StartTime,
    t.EndTime,
    b.UserID as PayerID,
    u.Name as PayerName,
    u.Email as PayerEmail,
    v.VenueName,
    v.Location as VenueAddress,
    v.OwnerID as VenueOwnerID,
    vo.Name as VenueOwnerName
FROM Payments p
LEFT JOIN Bookings b ON p.BookingID = b.BookingID
LEFT JOIN Users u ON b.UserID = u.UserID
LEFT JOIN Venues v ON b.VenueID = v.VenueID
LEFT JOIN Timeslots t ON b.TimeslotID = t.TimeslotID
LEFT JOIN Users vo ON v.OwnerID = vo.UserID
WHERE p.PaymentID = ?
```

### 4. Payments for Specific Venue (Owner Analytics):
```sql
SELECT 
    p.*,
    b.BookingDate,
    t.StartTime,
    t.EndTime,
    u.Name as PayerName,
    u.Email as PayerEmail
FROM Payments p
LEFT JOIN Bookings b ON p.BookingID = b.BookingID
LEFT JOIN Users u ON b.UserID = u.UserID
LEFT JOIN Timeslots t ON b.TimeslotID = t.TimeslotID
WHERE b.VenueID = ?
ORDER BY p.PaymentDate DESC
```

### 5. Calculate Total Revenue for Venue:
```sql
SELECT 
    COUNT(*) as TotalPayments,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as TotalRevenue,
    AVG(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE NULL END) as AverageRevenue
FROM Payments p
LEFT JOIN Bookings b ON p.BookingID = b.BookingID
WHERE b.VenueID = ?
```

## Payment Update Queries:
### 1. Update Payment Status (Admin Only):
```sql
-- Check payment exists first
SELECT * FROM Payments WHERE PaymentID = ?

-- Update payment status
UPDATE Payments 
SET PaymentStatus = ?, 
    PaymentMethod = ? 
WHERE PaymentID = ?
```

### 2. Validate Payment Status Values:
```sql
-- Payment status must be one of: 'Pending', 'Success', 'Failed', 'Refunded'
UPDATE Payments 
SET PaymentStatus = ? 
WHERE PaymentID = ? 
  AND ? IN ('Pending', 'Success', 'Failed', 'Refunded')
```

## Payment Refund Queries:
### 1. Get Payment Details for Refund:
```sql
SELECT 
    p.*,
    b.BookingID,
    b.BookingStatus
FROM Payments p
LEFT JOIN Bookings b ON p.BookingID = b.BookingID
WHERE p.PaymentID = ?
```

### 2. Process Refund (Transaction):
```sql
-- Start transaction
START TRANSACTION;

-- Update payment status to refunded
UPDATE Payments 
SET PaymentStatus = 'Refunded' 
WHERE PaymentID = ?;

-- Update booking status to cancelled
UPDATE Bookings 
SET BookingStatus = 'Cancelled' 
WHERE BookingID = ?;

-- Commit transaction
COMMIT;
```

### 3. Complete Refund Procedure:
```sql
DELIMITER //

CREATE PROCEDURE ProcessRefund(
    IN p_payment_id INT,
    IN p_reason TEXT,
    IN p_admin_id INT
)
BEGIN
    DECLARE v_booking_id INT;
    DECLARE v_payment_status VARCHAR(20);
    DECLARE v_user_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get payment details
    SELECT p.BookingID, p.PaymentStatus, b.UserID
    INTO v_booking_id, v_payment_status, v_user_id
    FROM Payments p
    LEFT JOIN Bookings b ON p.BookingID = b.BookingID
    WHERE p.PaymentID = p_payment_id;
    
    IF v_booking_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment not found';
    END IF;
    
    IF v_payment_status != 'Success' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can only refund completed payments';
    END IF;
    
    -- Update payment status
    UPDATE Payments 
    SET PaymentStatus = 'Refunded'
    WHERE PaymentID = p_payment_id;
    
    -- Update booking status
    UPDATE Bookings 
    SET BookingStatus = 'Cancelled'
    WHERE BookingID = v_booking_id;
    
    -- Create notification
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (v_user_id, CONCAT('Refund processed for payment #', p_payment_id, '. Reason: ', p_reason), FALSE);
    
    -- Log the refund
    INSERT INTO AuditLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (p_admin_id, 'REFUND', 'Payments', p_payment_id, p_reason);
    
    COMMIT;
    
    SELECT 'Refund processed successfully!' as Message;
END //

DELIMITER ;

-- Call the procedure
CALL ProcessRefund(?, ?, ?)
```

## Payment Analytics Queries:
### 1. Daily Revenue Report:
```sql
SELECT 
    DATE(p.PaymentDate) as PaymentDate,
    COUNT(*) as TotalTransactions,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as DailyRevenue,
    COUNT(CASE WHEN p.PaymentStatus = 'Success' THEN 1 END) as SuccessfulPayments,
    COUNT(CASE WHEN p.PaymentStatus = 'Failed' THEN 1 END) as FailedPayments
FROM Payments p
WHERE p.PaymentDate BETWEEN ? AND ?
GROUP BY DATE(p.PaymentDate)
ORDER BY PaymentDate DESC
```

### 2. Payment Method Analysis:
```sql
SELECT 
    PaymentMethod,
    COUNT(*) as TransactionCount,
    SUM(CASE WHEN PaymentStatus = 'Success' THEN Amount ELSE 0 END) as TotalRevenue,
    AVG(CASE WHEN PaymentStatus = 'Success' THEN Amount ELSE NULL END) as AverageAmount
FROM Payments
WHERE PaymentDate BETWEEN ? AND ?
GROUP BY PaymentMethod
ORDER BY TotalRevenue DESC
```

### 3. Venue-wise Payment Summary:
```sql
SELECT 
    v.VenueID,
    v.VenueName,
    v.OwnerID,
    u.Name as OwnerName,
    COUNT(p.PaymentID) as TotalPayments,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as TotalRevenue,
    SUM(CASE WHEN p.PaymentStatus = 'Pending' THEN p.Amount ELSE 0 END) as PendingRevenue,
    SUM(CASE WHEN p.PaymentStatus = 'Refunded' THEN p.Amount ELSE 0 END) as RefundedAmount
FROM Venues v
LEFT JOIN Users u ON v.OwnerID = u.UserID
LEFT JOIN Bookings b ON v.VenueID = b.VenueID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
WHERE v.OwnerID = ?
GROUP BY v.VenueID, v.VenueName, v.OwnerID, u.Name
ORDER BY TotalRevenue DESC
```

### 4. Monthly Revenue Trend:
```sql
SELECT 
    YEAR(p.PaymentDate) as Year,
    MONTH(p.PaymentDate) as Month,
    MONTHNAME(p.PaymentDate) as MonthName,
    COUNT(DISTINCT b.VenueID) as ActiveVenues,
    COUNT(p.PaymentID) as TotalTransactions,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as MonthlyRevenue,
    COUNT(DISTINCT b.UserID) as UniqueCustomers
FROM Payments p
LEFT JOIN Bookings b ON p.BookingID = b.BookingID
WHERE p.PaymentDate >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY YEAR(p.PaymentDate), MONTH(p.PaymentDate), MONTHNAME(p.PaymentDate)
ORDER BY Year DESC, Month DESC
```

### 5. Top Paying Customers:
```sql
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    COUNT(p.PaymentID) as TotalPayments,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as TotalSpent,
    MAX(p.PaymentDate) as LastPaymentDate
FROM Users u
INNER JOIN Bookings b ON u.UserID = b.UserID
INNER JOIN Payments p ON b.BookingID = p.BookingID
WHERE p.PaymentStatus = 'Success'
GROUP BY u.UserID, u.Name, u.Email
ORDER BY TotalSpent DESC
LIMIT 10
```

## Payment Validation Queries:
### 1. Validate Payment Amount Matches Booking:
```sql
SELECT 
    b.BookingID,
    b.TotalAmount as BookingAmount,
    p.Amount as PaymentAmount,
    ABS(b.TotalAmount - p.Amount) as Difference
FROM Bookings b
LEFT JOIN Payments p ON b.BookingID = p.BookingID
WHERE b.BookingID = ?
HAVING Difference > 0.01
```

### 2. Check for Duplicate Payments:
```sql
SELECT 
    BookingID,
    COUNT(*) as PaymentCount
FROM Payments
WHERE PaymentStatus = 'Success'
GROUP BY BookingID
HAVING PaymentCount > 1
```

### 3. Identify Pending Payments Older Than 24 Hours:
```sql
SELECT 
    p.PaymentID,
    p.BookingID,
    p.Amount,
    p.PaymentDate,
    b.BookingDate,
    u.Name as PlayerName,
    u.Email as PlayerEmail,
    v.VenueName
FROM Payments p
LEFT JOIN Bookings b ON p.BookingID = b.BookingID
LEFT JOIN Users u ON b.UserID = u.UserID
LEFT JOIN Venues v ON b.VenueID = v.VenueID
WHERE p.PaymentStatus = 'Pending'
  AND p.PaymentDate < DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY p.PaymentDate
```

### 4. Payment Audit Report:
```sql
SELECT 
    al.LogID,
    al.Timestamp,
    al.Action,
    al.UserID,
    u.Name as UserName,
    al.RecordID as PaymentID,
    p.Amount,
    p.PaymentStatus,
    al.ActionDetails
FROM AuditLog al
LEFT JOIN Users u ON al.UserID = u.UserID
LEFT JOIN Payments p ON al.RecordID = p.PaymentID
WHERE al.TableName = 'Payments'
ORDER BY al.Timestamp DESC
LIMIT 100
```
