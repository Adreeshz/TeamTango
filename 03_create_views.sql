-- ================================================
-- TeamTango Database Views Creation Script
-- Purpose: Create useful views for analytics and reporting
-- Date: October 5, 2025
-- Usage: mysql -u root -p1234 dbms_cp < 03_create_views.sql
-- ================================================

USE dbms_cp;

-- 1. User Profile View (Simple user info with role)
CREATE OR REPLACE VIEW user_profile_view AS
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.PhoneNumber,
    u.Address,
    u.Gender,
    r.RoleName
FROM Users u
LEFT JOIN Roles r ON u.RoleID = r.RoleID;

-- 2. Venue Details View (Complete venue info)
CREATE OR REPLACE VIEW venue_details_view AS
SELECT 
    v.VenueID,
    v.VenueName,
    v.Address AS VenueAddress,
    u.Name AS OwnerName,
    u.Email AS OwnerEmail,
    u.PhoneNumber AS OwnerPhone
FROM Venues v
LEFT JOIN Users u ON v.OwnerID = u.UserID;

-- 3. Available Timeslots View (Only available slots)
CREATE OR REPLACE VIEW available_timeslots_view AS
SELECT 
    ts.SlotID,
    v.VenueName,
    v.Address AS VenueAddress,
    ts.StartTime,
    ts.EndTime,
    ts.Status,
    u.Name AS VenueOwner
FROM Timeslots ts
JOIN Venues v ON ts.VenueID = v.VenueID
LEFT JOIN Users u ON v.OwnerID = u.UserID
WHERE ts.Status = 'Available';

-- 4. Booking Summary View (Complete booking info)
CREATE OR REPLACE VIEW booking_summary_view AS
SELECT 
    b.BookingID,
    t.TeamName,
    t_captain.Name AS CaptainName,
    v.VenueName,
    v.Address AS VenueAddress,
    s.SportName,
    ts.StartTime,
    ts.EndTime,
    b.BookingCost,
    b.BookingDate,
    p.Status AS PaymentStatus
FROM Bookings b
JOIN Teams t ON b.TeamID = t.TeamID
LEFT JOIN Users t_captain ON t.CaptainID = t_captain.UserID
JOIN Timeslots ts ON b.SlotID = ts.SlotID
JOIN Venues v ON ts.VenueID = v.VenueID
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN Payments p ON b.PaymentID = p.PaymentID;

-- 5. Popular Sports View (Sports analytics)
CREATE OR REPLACE VIEW popular_sports_view AS
SELECT 
    s.SportID,
    s.SportName,
    COUNT(DISTINCT t.TeamID) AS TeamCount,
    COUNT(DISTINCT b.BookingID) AS BookingCount,
    SUM(b.BookingCost) AS TotalRevenue
FROM Sports s
LEFT JOIN Teams t ON s.SportID = t.SportID
LEFT JOIN Bookings b ON t.TeamID = b.TeamID
GROUP BY s.SportID, s.SportName
ORDER BY BookingCount DESC;

-- 6. Team Composition View (Team members with details)
CREATE OR REPLACE VIEW team_composition_view AS
SELECT 
    t.TeamID,
    t.TeamName,
    u_captain.Name AS CaptainName,
    u_captain.Email AS CaptainEmail,
    u_member.UserID AS MemberID,
    u_member.Name AS MemberName,
    u_member.Email AS MemberEmail,
    u_member.PhoneNumber AS MemberPhone,
    tm.Position,
    s.SportName
FROM Teams t
LEFT JOIN Users u_captain ON t.CaptainID = u_captain.UserID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID
LEFT JOIN Users u_member ON tm.UserID = u_member.UserID
LEFT JOIN Sports s ON t.SportID = s.SportID;

-- 7. Payment Summary View (Payment details)
CREATE OR REPLACE VIEW payment_summary_view AS
SELECT 
    p.PaymentID,
    p.Method,
    p.Amount,
    p.Status,
    p.TransactionDate,
    b.BookingID,
    b.BookingCost,
    t.TeamName,
    v.VenueName
FROM Payments p
LEFT JOIN Bookings b ON p.PaymentID = b.PaymentID
LEFT JOIN Teams t ON b.TeamID = t.TeamID
LEFT JOIN Timeslots ts ON b.SlotID = ts.SlotID
LEFT JOIN Venues v ON ts.VenueID = v.VenueID;

-- Show success message
SELECT 'Basic views created successfully! Ready for analytics and reporting.' as Status;