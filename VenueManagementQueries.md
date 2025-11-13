## Venue Creation Queries:
### 1. Create New Venue Query:
```sql
INSERT INTO Venues (VenueName, Location, City, ContactNumber, OwnerID, PricePerHour, SportID)
VALUES (?, ?, ?, ?, ?, ?, ?)
```

### 2. Venue Owner Validation (Handled by a trigger):
```sql
DELIMITER //

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

DELIMITER ;
```

### 3. Log Venue Creation (Audit Trigger):
```sql
DELIMITER //

CREATE TRIGGER tr_venue_insert_audit
AFTER INSERT ON Venues
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (NEW.OwnerID, 'INSERT', 'Venues', NOW());
END //

DELIMITER ;
```

## Reading Venue Data Queries:
### 1. All Venues with Complete Information (Public Browse):
```sql
-- Using venue_summary view for pre-aggregated data
SELECT 
    VenueID, 
    VenueName, 
    Location, 
    OwnerID,
    OwnerName,
    COALESCE(SportName, 'Multi-Sport') as SportType,
    PricePerHour,
    COALESCE(AverageRating, 4.5) as Rating,
    TotalBookings,
    TotalReviews,
    AvailableSlots
FROM venue_summary
ORDER BY VenueName
```

### 2. Venues Owned by Current User (Venue Owner Dashboard):
```sql
SELECT 
    v.VenueID, 
    v.VenueName, 
    v.Address, 
    v.Location,
    v.ContactNumber,
    v.PricePerHour,
    v.City,
    v.OwnerID,
    u.Name as OwnerName,
    (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID) as TotalBookings,
    (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID AND b.BookingStatus = 'Confirmed') as ConfirmedBookings,
    (SELECT COALESCE(SUM(p.Amount), 0) 
     FROM Payments p 
     JOIN Bookings b ON p.BookingID = b.BookingID 
     WHERE b.VenueID = v.VenueID AND p.PaymentStatus = 'Success') as TotalRevenue
FROM Venues v 
LEFT JOIN Users u ON v.OwnerID = u.UserID
WHERE v.OwnerID = ?
ORDER BY v.VenueID DESC
```

### 3. Single Venue Details with Ownership Check:
```sql
SELECT 
    v.VenueID, 
    v.VenueName, 
    v.Address, 
    v.Location,
    v.ContactNumber,
    v.PricePerHour,
    v.City,
    v.OwnerID,
    u.Name as OwnerName,
    u.Email as OwnerEmail,
    u.PhoneNumber as OwnerPhone,
    (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID) as TotalBookings,
    (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID AND b.BookingStatus = 'Confirmed') as ConfirmedBookings,
    (SELECT AVG(f.Rating) FROM Feedback f WHERE f.VenueID = v.VenueID) as AverageRating
FROM Venues v 
LEFT JOIN Users u ON v.OwnerID = u.UserID
WHERE v.VenueID = ? AND v.OwnerID = ?
```

### 4. Search Venues by Multiple Criteria:
```sql
SELECT 
    VenueID, 
    VenueName, 
    Location, 
    OwnerID,
    OwnerName,
    OwnerPhone,
    COALESCE(SportName, 'Multi-Sport') as SportType,
    PricePerHour,
    COALESCE(AverageRating, 4.5) as Rating,
    TotalBookings,
    TotalReviews,
    AvailableSlots
FROM venue_summary
WHERE VenueName LIKE ? 
   OR Location LIKE ? 
   OR OwnerName LIKE ? 
   OR OwnerPhone LIKE ?
   OR CAST(VenueID AS CHAR) LIKE ?
   OR CAST(PricePerHour AS CHAR) LIKE ?
   OR SportName LIKE ?
ORDER BY VenueName
```

### 5. Venue Revenue Summary (Using View):
```sql
-- Using venue_revenue view
SELECT 
    OwnerID,
    OwnerName,
    VenueID,
    VenueName,
    TotalBookings,
    ConfirmedBookings,
    PendingBookings,
    TotalRevenue,
    MonthlyRevenue
FROM venue_revenue
WHERE OwnerID = ?
ORDER BY TotalRevenue DESC
```

## Venue Updating:
### 1. Check Venue Ownership Permission:
```sql
SELECT VenueID, VenueName, OwnerID 
FROM Venues 
WHERE VenueID = ? AND OwnerID = ?
```

### 2. Update Venue Information:
```sql
UPDATE Venues 
SET VenueName = ?, 
    Location = ?, 
    ContactNumber = ?, 
    PricePerHour = ?, 
    SportID = ?
WHERE VenueID = ? AND OwnerID = ?
```

### 3. Update Venue Pricing (Using Stored Procedure):
```sql
DELIMITER //

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

DELIMITER ;

-- Call the procedure
CALL UpdateVenuePricing(?, ?, ?)
```

## Venue Deletion:
### 1. Check Ownership Before Deletion:
```sql
SELECT VenueID, VenueName, OwnerID 
FROM Venues 
WHERE VenueID = ? AND OwnerID = ?
```

### 2. Check for Active Bookings:
```sql
SELECT COUNT(*) as ActiveBookings
FROM Bookings 
WHERE VenueID = ? 
  AND BookingStatus IN ('Pending', 'Confirmed')
```

### 3. Cleanup Trigger (Removes Available Timeslots):
```sql
DELIMITER //

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

DELIMITER ;
```

### 4. Delete Venue:
```sql
DELETE FROM Venues 
WHERE VenueID = ? AND OwnerID = ?
```

## Venue Analytics Queries:
### 1. Get Bookings for Specific Venue:
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

### 2. Venue Revenue Report (Using Stored Procedure):
```sql
DELIMITER //

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

DELIMITER ;

-- Call the procedure
CALL GetVenueRevenueReport(?, ?, ?)
```

### 3. Search Venues with Filters (Advanced):
```sql
DELIMITER //

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

DELIMITER ;

-- Call the procedure
CALL SearchVenues(?, ?, ?, ?)
```
