
USE dbms_cp;

-- ================================================
-- SECTION 1: USER MANAGEMENT VIEWS
-- ================================================

-- View: All users with their roles
CREATE OR REPLACE VIEW UserDetails AS
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.PhoneNumber,
    u.City,
    r.RoleName as Role,
    r.Description as RoleDescription
FROM Users u
JOIN Roles r ON u.RoleID = r.RoleID;

-- View: Active players only
CREATE OR REPLACE VIEW Players AS
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.PhoneNumber,
    u.City
FROM Users u
WHERE u.RoleID = 1;  -- Players only

-- View: Venue owners with their venues
CREATE OR REPLACE VIEW VenueOwners AS
SELECT 
    u.UserID as OwnerID,
    u.Name as OwnerName,
    u.Email as OwnerEmail,
    u.PhoneNumber as OwnerPhone,
    u.City as OwnerCity,
    COUNT(v.VenueID) as TotalVenues
FROM Users u
LEFT JOIN Venues v ON u.UserID = v.OwnerID
WHERE u.RoleID = 2  -- Venue owners only
GROUP BY u.UserID, u.Name, u.Email, u.PhoneNumber, u.City;

-- ================================================
-- SECTION 2: VENUE AND SPORTS VIEWS
-- ================================================

-- View: Complete venue information
CREATE OR REPLACE VIEW VenueDetails AS
SELECT 
    v.VenueID,
    v.VenueName,
    v.Location,
    v.City,
    v.ContactNumber,
    v.PricePerHour,
    s.SportName,
    s.Category as SportCategory,
    u.Name as OwnerName,
    u.PhoneNumber as OwnerPhone
FROM Venues v
JOIN Sports s ON v.SportID = s.SportID
JOIN Users u ON v.OwnerID = u.UserID;

-- View: Available venues with pricing
CREATE OR REPLACE VIEW AvailableVenues AS
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
JOIN Sports s ON v.SportID = s.SportID
JOIN Users u ON v.OwnerID = u.UserID
LEFT JOIN Timeslots ts ON v.VenueID = ts.VenueID AND ts.IsAvailable = TRUE
GROUP BY v.VenueID, v.VenueName, v.Location, v.City, s.SportName, v.PricePerHour, u.Name
HAVING AvailableSlots > 0;

-- View: Sports with venue count
CREATE OR REPLACE VIEW SportsOverview AS
SELECT 
    s.SportID,
    s.SportName,
    s.Description,
    s.Category,
    COUNT(v.VenueID) as VenueCount,
    AVG(v.PricePerHour) as AvgPrice,
    MIN(v.PricePerHour) as MinPrice,
    MAX(v.PricePerHour) as MaxPrice
FROM Sports s
LEFT JOIN Venues v ON s.SportID = v.SportID
GROUP BY s.SportID, s.SportName, s.Description, s.Category;

-- ================================================
-- SECTION 3: TEAM MANAGEMENT VIEWS
-- ================================================

-- View: Complete team information
CREATE OR REPLACE VIEW TeamDetails AS
SELECT 
    t.TeamID,
    t.TeamName,
    s.SportName,
    u.Name as CaptainName,
    u.PhoneNumber as CaptainPhone,
    COUNT(tm.MemberID) as TotalMembers
FROM Teams t
JOIN Sports s ON t.SportID = s.SportID
JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID
GROUP BY t.TeamID, t.TeamName, s.SportName, u.Name, u.PhoneNumber;

-- View: Team members with details
CREATE OR REPLACE VIEW TeamMembership AS
SELECT 
    t.TeamID,
    t.TeamName,
    s.SportName,
    u.Name as MemberName,
    u.Email as MemberEmail,
    u.PhoneNumber as MemberPhone,
    tm.JoinedDate,
    CASE WHEN t.CaptainID = u.UserID THEN 'Captain' ELSE 'Member' END as Role
FROM TeamMembers tm
JOIN Teams t ON tm.TeamID = t.TeamID
JOIN Users u ON tm.UserID = u.UserID
JOIN Sports s ON t.SportID = s.SportID
ORDER BY t.TeamName, tm.JoinedDate;

-- View: Users and their team affiliations
CREATE OR REPLACE VIEW PlayerTeams AS
SELECT 
    u.UserID,
    u.Name as PlayerName,
    u.Email,
    GROUP_CONCAT(t.TeamName SEPARATOR ', ') as Teams,
    GROUP_CONCAT(s.SportName SEPARATOR ', ') as Sports,
    COUNT(tm.TeamID) as TeamCount
FROM Users u
LEFT JOIN TeamMembers tm ON u.UserID = tm.UserID
LEFT JOIN Teams t ON tm.TeamID = t.TeamID
LEFT JOIN Sports s ON t.SportID = s.SportID
WHERE u.RoleID = 1  -- Players only
GROUP BY u.UserID, u.Name, u.Email;

-- ================================================
-- SECTION 4: BOOKING AND SCHEDULE VIEWS
-- ================================================

-- View: Available time slots with venue details
CREATE OR REPLACE VIEW AvailableSlots AS
SELECT 
    ts.TimeslotID,
    v.VenueID,
    v.VenueName,
    v.Location,
    v.City,
    s.SportName,
    ts.SlotDate,
    ts.StartTime,
    ts.EndTime,
    ts.PriceINR,
    u.Name as OwnerName
FROM Timeslots ts
JOIN Venues v ON ts.VenueID = v.VenueID
JOIN Sports s ON v.SportID = s.SportID
JOIN Users u ON v.OwnerID = u.UserID
WHERE ts.IsAvailable = TRUE
AND ts.SlotDate >= CURDATE()
ORDER BY ts.SlotDate, ts.StartTime;

-- View: Complete booking information
CREATE OR REPLACE VIEW BookingDetails AS
SELECT 
    b.BookingID,
    u.Name as PlayerName,
    u.Email as PlayerEmail,
    u.PhoneNumber as PlayerPhone,
    v.VenueName,
    v.Location,
    v.City,
    s.SportName,
    b.BookingDate,
    ts.StartTime,
    ts.EndTime,
    b.TotalAmount,
    b.BookingStatus,
    p.PaymentMethod,
    p.PaymentStatus
FROM Bookings b
JOIN Users u ON b.UserID = u.UserID
JOIN Venues v ON b.VenueID = v.VenueID
JOIN Sports s ON v.SportID = s.SportID
JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
ORDER BY b.BookingDate DESC, ts.StartTime;

-- View: Today's bookings
CREATE OR REPLACE VIEW TodayBookings AS
SELECT 
    b.BookingID,
    u.Name as PlayerName,
    u.PhoneNumber,
    v.VenueName,
    v.Location,
    s.SportName,
    ts.StartTime,
    ts.EndTime,
    b.BookingStatus
FROM Bookings b
JOIN Users u ON b.UserID = u.UserID
JOIN Venues v ON b.VenueID = v.VenueID
JOIN Sports s ON v.SportID = s.SportID
JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
WHERE b.BookingDate = CURDATE()
ORDER BY ts.StartTime;

-- ================================================
-- SECTION 5: FINANCIAL VIEWS
-- ================================================

-- View: Payment summary
CREATE OR REPLACE VIEW PaymentSummary AS
SELECT 
    p.PaymentID,
    b.BookingID,
    u.Name as PlayerName,
    v.VenueName,
    p.Amount,
    p.PaymentMethod,
    p.PaymentStatus,
    p.PaymentDate
FROM Payments p
JOIN Bookings b ON p.BookingID = b.BookingID
JOIN Users u ON b.UserID = u.UserID
JOIN Venues v ON b.VenueID = v.VenueID
ORDER BY p.PaymentDate DESC;

-- View: Venue owner revenue
CREATE OR REPLACE VIEW VenueRevenue AS
SELECT 
    u.UserID as OwnerID,
    u.Name as OwnerName,
    v.VenueID,
    v.VenueName,
    COUNT(b.BookingID) as TotalBookings,
    SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN b.TotalAmount ELSE 0 END) as ConfirmedRevenue,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as CollectedRevenue
FROM Users u
JOIN Venues v ON u.UserID = v.OwnerID
LEFT JOIN Bookings b ON v.VenueID = b.VenueID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
WHERE u.RoleID = 2  -- Venue owners
GROUP BY u.UserID, u.Name, v.VenueID, v.VenueName
ORDER BY CollectedRevenue DESC;

-- ================================================
-- SECTION 6: MATCH AND COMPETITION VIEWS
-- ================================================

-- View: Upcoming matches
CREATE OR REPLACE VIEW UpcomingMatches AS
SELECT 
    m.MatchID,
    m.MatchTitle,
    t1.TeamName as Team1,
    t2.TeamName as Team2,
    v.VenueName,
    v.Location,
    m.MatchDate,
    m.MatchTime,
    m.MatchStatus,
    s.SportName
FROM Matches m
JOIN Teams t1 ON m.Team1ID = t1.TeamID
JOIN Teams t2 ON m.Team2ID = t2.TeamID
JOIN Venues v ON m.VenueID = v.VenueID
JOIN Sports s ON t1.SportID = s.SportID
WHERE m.MatchDate >= CURDATE()
ORDER BY m.MatchDate, m.MatchTime;

-- View: Match results
CREATE OR REPLACE VIEW MatchResults AS
SELECT 
    m.MatchID,
    m.MatchTitle,
    t1.TeamName as Team1,
    m.Team1Score,
    t2.TeamName as Team2,
    m.Team2Score,
    v.VenueName,
    m.MatchDate,
    m.MatchTime,
    s.SportName,
    CASE 
        WHEN m.Team1Score > m.Team2Score THEN t1.TeamName
        WHEN m.Team2Score > m.Team1Score THEN t2.TeamName
        ELSE 'Draw'
    END as Winner
FROM Matches m
JOIN Teams t1 ON m.Team1ID = t1.TeamID
JOIN Teams t2 ON m.Team2ID = t2.TeamID
JOIN Venues v ON m.VenueID = v.VenueID
JOIN Sports s ON t1.SportID = s.SportID
WHERE m.MatchStatus = 'Completed'
ORDER BY m.MatchDate DESC;

-- ================================================
-- SECTION 7: FEEDBACK AND RATING VIEWS
-- ================================================

-- View: Venue ratings and feedback
CREATE OR REPLACE VIEW VenueFeedback AS
SELECT 
    v.VenueID,
    v.VenueName,
    v.Location,
    v.City,
    s.SportName,
    AVG(f.Rating) as AverageRating,
    COUNT(f.FeedbackID) as TotalReviews,
    f.FeedbackID,
    u.Name as ReviewerName,
    f.Rating,
    f.Comment
FROM Venues v
JOIN Sports s ON v.SportID = s.SportID
LEFT JOIN Feedback f ON v.VenueID = f.VenueID
LEFT JOIN Users u ON f.UserID = u.UserID
GROUP BY v.VenueID, v.VenueName, v.Location, v.City, s.SportName, 
         f.FeedbackID, u.Name, f.Rating, f.Comment
ORDER BY AverageRating DESC, TotalReviews DESC;

-- View: Recent feedback
CREATE OR REPLACE VIEW RecentFeedback AS
SELECT 
    f.FeedbackID,
    u.Name as PlayerName,
    v.VenueName,
    v.Location,
    f.Rating,
    f.Comment
FROM Feedback f
JOIN Users u ON f.UserID = u.UserID
JOIN Venues v ON f.VenueID = v.VenueID
ORDER BY f.FeedbackID DESC
LIMIT 10;

-- ================================================
-- SECTION 8: DASHBOARD VIEWS
-- ================================================

-- View: Admin dashboard summary
CREATE OR REPLACE VIEW AdminDashboard AS
SELECT 
    (SELECT COUNT(*) FROM Users WHERE RoleID = 1) as TotalPlayers,
    (SELECT COUNT(*) FROM Users WHERE RoleID = 2) as TotalVenueOwners,
    (SELECT COUNT(*) FROM Venues) as TotalVenues,
    (SELECT COUNT(*) FROM Teams) as TotalTeams,
    (SELECT COUNT(*) FROM Bookings WHERE BookingDate = CURDATE()) as TodayBookings,
    (SELECT COUNT(*) FROM Matches WHERE MatchDate >= CURDATE()) as UpcomingMatches,
    (SELECT SUM(Amount) FROM Payments WHERE PaymentStatus = 'Success' AND PaymentDate >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)) as MonthlyRevenue;

-- View: Player activity summary
CREATE OR REPLACE VIEW PlayerActivity AS
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    COUNT(DISTINCT tm.TeamID) as TeamsJoined,
    COUNT(DISTINCT b.BookingID) as TotalBookings,
    COUNT(DISTINCT CASE WHEN b.BookingDate >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) THEN b.BookingID END) as RecentBookings,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as TotalSpent
FROM Users u
LEFT JOIN TeamMembers tm ON u.UserID = tm.UserID
LEFT JOIN Bookings b ON u.UserID = b.UserID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
WHERE u.RoleID = 1  -- Players only
GROUP BY u.UserID, u.Name, u.Email
ORDER BY RecentBookings DESC, TotalSpent DESC;

-- ================================================
-- SUCCESS MESSAGE
-- ================================================

SELECT 'Simplified Views created successfully!' as Status,
       'All essential views for student-friendly application' as Message,
       'Views are ready for frontend integration' as Details;

-- Show available views
SELECT 'Available Views:' as Info;
SHOW TABLES LIKE '%';

-- Sample view data
SELECT 'Sample Venue Details:' as Info;
SELECT * FROM VenueDetails LIMIT 3;

SELECT 'Sample Available Slots:' as Info;
SELECT * FROM AvailableSlots LIMIT 5;