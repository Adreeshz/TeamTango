

USE dbms_cp;

-- ================================================
-- SECTION 1: BASIC JOINS
-- ================================================

-- Inner Join: Users with their roles
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.City,
    r.RoleName
FROM Users u
INNER JOIN Roles r ON u.RoleID = r.RoleID
ORDER BY u.Name;

-- Inner Join: Venues with sports and owners
SELECT 
    v.VenueID,
    v.VenueName,
    v.Location,
    s.SportName,
    u.Name as OwnerName,
    v.PricePerHour
FROM Venues v
INNER JOIN Sports s ON v.SportID = s.SportID
INNER JOIN Users u ON v.OwnerID = u.UserID
ORDER BY v.City, v.VenueName;

-- Inner Join: Teams with captains and sports
SELECT 
    t.TeamID,
    t.TeamName,
    s.SportName,
    u.Name as CaptainName,
    u.PhoneNumber as CaptainPhone
FROM Teams t
INNER JOIN Sports s ON t.SportID = s.SportID
INNER JOIN Users u ON t.CaptainID = u.UserID
ORDER BY s.SportName, t.TeamName;

-- ================================================
-- SECTION 2: LEFT JOINS
-- ================================================

-- Left Join: All users with their team memberships (if any)
SELECT 
    u.UserID,
    u.Name as PlayerName,
    t.TeamName,
    s.SportName,
    tm.JoinedDate
FROM Users u
LEFT JOIN TeamMembers tm ON u.UserID = tm.UserID
LEFT JOIN Teams t ON tm.TeamID = t.TeamID
LEFT JOIN Sports s ON t.SportID = s.SportID
WHERE u.RoleID = 1  -- Players only
ORDER BY u.Name, tm.JoinedDate;

-- Left Join: All venues with their available timeslots
SELECT 
    v.VenueID,
    v.VenueName,
    v.Location,
    ts.SlotDate,
    ts.StartTime,
    ts.EndTime,
    ts.PriceINR,
    ts.IsAvailable
FROM Venues v
LEFT JOIN Timeslots ts ON v.VenueID = ts.VenueID 
    AND ts.SlotDate >= CURDATE()
    AND ts.IsAvailable = TRUE
ORDER BY v.VenueName, ts.SlotDate, ts.StartTime;

-- Left Join: All bookings with payment status
SELECT 
    b.BookingID,
    u.Name as PlayerName,
    v.VenueName,
    b.BookingDate,
    b.TotalAmount,
    b.BookingStatus,
    p.PaymentMethod,
    p.PaymentStatus,
    p.PaymentDate
FROM Bookings b
INNER JOIN Users u ON b.UserID = u.UserID
INNER JOIN Venues v ON b.VenueID = v.VenueID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
ORDER BY b.BookingDate DESC;

-- ================================================
-- SECTION 3: MULTIPLE TABLE JOINS
-- ================================================

-- Complete booking information with all related tables
SELECT 
    b.BookingID,
    u.Name as PlayerName,
    u.Email as PlayerEmail,
    u.PhoneNumber as PlayerPhone,
    v.VenueName,
    v.Location,
    v.City as VenueCity,
    s.SportName,
    ts.SlotDate,
    ts.StartTime,
    ts.EndTime,
    b.TotalAmount,
    b.BookingStatus,
    owner.Name as VenueOwner,
    owner.PhoneNumber as OwnerPhone
FROM Bookings b
INNER JOIN Users u ON b.UserID = u.UserID
INNER JOIN Venues v ON b.VenueID = v.VenueID
INNER JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
INNER JOIN Sports s ON v.SportID = s.SportID
INNER JOIN Users owner ON v.OwnerID = owner.UserID
ORDER BY b.BookingDate DESC, ts.StartTime;

-- Match details with teams, venue, and sport information
SELECT 
    m.MatchID,
    m.MatchTitle,
    t1.TeamName as Team1,
    c1.Name as Team1Captain,
    t2.TeamName as Team2,
    c2.Name as Team2Captain,
    v.VenueName,
    v.Location,
    s.SportName,
    m.MatchDate,
    m.MatchTime,
    m.Team1Score,
    m.Team2Score,
    m.MatchStatus
FROM Matches m
INNER JOIN Teams t1 ON m.Team1ID = t1.TeamID
INNER JOIN Teams t2 ON m.Team2ID = t2.TeamID
INNER JOIN Users c1 ON t1.CaptainID = c1.UserID
INNER JOIN Users c2 ON t2.CaptainID = c2.UserID
INNER JOIN Venues v ON m.VenueID = v.VenueID
INNER JOIN Sports s ON t1.SportID = s.SportID
ORDER BY m.MatchDate, m.MatchTime;

-- Team roster with complete member information
SELECT 
    t.TeamID,
    t.TeamName,
    s.SportName,
    captain.Name as CaptainName,
    u.Name as MemberName,
    u.Email as MemberEmail,
    u.PhoneNumber as MemberPhone,
    u.City as MemberCity,
    tm.JoinedDate,
    CASE WHEN t.CaptainID = u.UserID THEN 'Captain' ELSE 'Member' END as Role
FROM Teams t
INNER JOIN Sports s ON t.SportID = s.SportID
INNER JOIN Users captain ON t.CaptainID = captain.UserID
INNER JOIN TeamMembers tm ON t.TeamID = tm.TeamID
INNER JOIN Users u ON tm.UserID = u.UserID
ORDER BY t.TeamName, tm.JoinedDate;

-- ================================================
-- SECTION 4: SELF JOINS
-- ================================================

-- Find users from the same city
SELECT 
    u1.Name as User1,
    u2.Name as User2,
    u1.City,
    u1.Email as User1Email,
    u2.Email as User2Email
FROM Users u1
INNER JOIN Users u2 ON u1.City = u2.City AND u1.UserID < u2.UserID
WHERE u1.RoleID = 1 AND u2.RoleID = 1  -- Both are players
ORDER BY u1.City, u1.Name;

-- Find venues with similar pricing in the same city
SELECT 
    v1.VenueName as Venue1,
    v2.VenueName as Venue2,
    v1.City,
    v1.PricePerHour as Price1,
    v2.PricePerHour as Price2,
    ABS(v1.PricePerHour - v2.PricePerHour) as PriceDifference
FROM Venues v1
INNER JOIN Venues v2 ON v1.City = v2.City 
    AND v1.VenueID < v2.VenueID
    AND ABS(v1.PricePerHour - v2.PricePerHour) <= 200
ORDER BY v1.City, PriceDifference;

-- ================================================
-- SECTION 5: AGGREGATION WITH JOINS
-- ================================================

-- Venue statistics with owner information
SELECT 
    u.Name as OwnerName,
    u.Email as OwnerEmail,
    u.City as OwnerCity,
    COUNT(v.VenueID) as TotalVenues,
    AVG(v.PricePerHour) as AvgPrice,
    MIN(v.PricePerHour) as MinPrice,
    MAX(v.PricePerHour) as MaxPrice,
    COUNT(b.BookingID) as TotalBookings,
    SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN b.TotalAmount ELSE 0 END) as Revenue
FROM Users u
LEFT JOIN Venues v ON u.UserID = v.OwnerID
LEFT JOIN Bookings b ON v.VenueID = b.VenueID
WHERE u.RoleID = 2  -- Venue owners
GROUP BY u.UserID, u.Name, u.Email, u.City
ORDER BY TotalVenues DESC, Revenue DESC;

-- Player activity statistics
SELECT 
    u.Name as PlayerName,
    u.Email,
    u.City,
    COUNT(DISTINCT tm.TeamID) as TeamsJoined,
    COUNT(DISTINCT b.BookingID) as TotalBookings,
    SUM(b.TotalAmount) as TotalSpent,
    COUNT(DISTINCT s.SportID) as SportsPlayed,
    GROUP_CONCAT(DISTINCT s.SportName) as Sports
FROM Users u
LEFT JOIN TeamMembers tm ON u.UserID = tm.UserID
LEFT JOIN Teams t ON tm.TeamID = t.TeamID
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN Bookings b ON u.UserID = b.UserID
WHERE u.RoleID = 1  -- Players only
GROUP BY u.UserID, u.Name, u.Email, u.City
HAVING TotalBookings > 0 OR TeamsJoined > 0
ORDER BY TotalBookings DESC, TotalSpent DESC;

-- Sport popularity and revenue analysis
SELECT 
    s.SportName,
    s.Category,
    COUNT(DISTINCT v.VenueID) as VenueCount,
    COUNT(DISTINCT t.TeamID) as TeamCount,
    COUNT(DISTINCT b.BookingID) as BookingCount,
    AVG(v.PricePerHour) as AvgVenuePrice,
    SUM(b.TotalAmount) as TotalRevenue,
    COUNT(DISTINCT tm.UserID) as PlayersCount
FROM Sports s
LEFT JOIN Venues v ON s.SportID = v.SportID
LEFT JOIN Teams t ON s.SportID = t.SportID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID
LEFT JOIN Bookings b ON v.VenueID = b.VenueID
GROUP BY s.SportID, s.SportName, s.Category
ORDER BY BookingCount DESC, TotalRevenue DESC;

-- ================================================
-- SECTION 6: CONDITIONAL JOINS
-- ================================================

-- Find available slots for specific dates and sports
SELECT 
    v.VenueID,
    v.VenueName,
    v.Location,
    s.SportName,
    ts.SlotDate,
    ts.StartTime,
    ts.EndTime,
    ts.PriceINR,
    u.Name as OwnerName
FROM Venues v
INNER JOIN Sports s ON v.SportID = s.SportID
INNER JOIN Timeslots ts ON v.VenueID = ts.VenueID
INNER JOIN Users u ON v.OwnerID = u.UserID
WHERE ts.IsAvailable = TRUE
    AND ts.SlotDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    AND s.SportName IN ('Football', 'Cricket', 'Badminton')
ORDER BY s.SportName, ts.SlotDate, ts.StartTime;

-- Recent bookings with payment details for specific cities
SELECT 
    b.BookingID,
    u.Name as PlayerName,
    v.VenueName,
    v.City,
    s.SportName,
    b.BookingDate,
    b.TotalAmount,
    b.BookingStatus,
    COALESCE(p.PaymentStatus, 'No Payment') as PaymentStatus
FROM Bookings b
INNER JOIN Users u ON b.UserID = u.UserID
INNER JOIN Venues v ON b.VenueID = v.VenueID
INNER JOIN Sports s ON v.SportID = s.SportID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
WHERE v.City IN ('Pune', 'Mumbai')
    AND b.BookingDate >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY b.BookingDate DESC, v.City;

-- ================================================
-- SECTION 7: SUBQUERIES WITH JOINS
-- ================================================

-- Find venues with above-average pricing in their sport category
SELECT 
    v.VenueName,
    v.Location,
    s.SportName,
    v.PricePerHour,
    avg_prices.AvgPrice
FROM Venues v
INNER JOIN Sports s ON v.SportID = s.SportID
INNER JOIN (
    SELECT 
        SportID, 
        AVG(PricePerHour) as AvgPrice
    FROM Venues 
    GROUP BY SportID
) avg_prices ON v.SportID = avg_prices.SportID
WHERE v.PricePerHour > avg_prices.AvgPrice
ORDER BY s.SportName, v.PricePerHour DESC;

-- Most active players by booking frequency
SELECT 
    u.Name as PlayerName,
    u.Email,
    booking_stats.BookingCount,
    booking_stats.TotalSpent,
    booking_stats.LastBookingDate
FROM Users u
INNER JOIN (
    SELECT 
        UserID,
        COUNT(*) as BookingCount,
        SUM(TotalAmount) as TotalSpent,
        MAX(BookingDate) as LastBookingDate
    FROM Bookings
    WHERE BookingStatus = 'Confirmed'
    GROUP BY UserID
    HAVING BookingCount >= 2
) booking_stats ON u.UserID = booking_stats.UserID
WHERE u.RoleID = 1
ORDER BY booking_stats.BookingCount DESC, booking_stats.TotalSpent DESC;

-- ================================================
-- SECTION 8: UNION WITH JOINS
-- ================================================

-- Combined view of all upcoming activities (matches and bookings)
SELECT 
    'Match' as ActivityType,
    m.MatchTitle as Activity,
    v.VenueName,
    v.Location,
    m.MatchDate as ActivityDate,
    m.MatchTime as ActivityTime,
    s.SportName,
    NULL as PlayerName
FROM Matches m
INNER JOIN Venues v ON m.VenueID = v.VenueID
INNER JOIN Teams t ON m.Team1ID = t.TeamID
INNER JOIN Sports s ON t.SportID = s.SportID
WHERE m.MatchDate >= CURDATE() AND m.MatchStatus = 'Scheduled'

UNION ALL

SELECT 
    'Booking' as ActivityType,
    CONCAT(u.Name, ' - ', s.SportName) as Activity,
    v.VenueName,
    v.Location,
    b.BookingDate as ActivityDate,
    ts.StartTime as ActivityTime,
    s.SportName,
    u.Name as PlayerName
FROM Bookings b
INNER JOIN Users u ON b.UserID = u.UserID
INNER JOIN Venues v ON b.VenueID = v.VenueID
INNER JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
INNER JOIN Sports s ON v.SportID = s.SportID
WHERE b.BookingDate >= CURDATE() AND b.BookingStatus = 'Confirmed'

ORDER BY ActivityDate, ActivityTime;

-- ================================================
-- SUCCESS MESSAGE
-- ================================================

SELECT 'Simplified JOIN operations completed successfully!' as Status,
       'All essential JOIN examples for student learning' as Message,
       'Covers INNER, LEFT, SELF, and complex JOINs' as Details;

-- Sample complex query result
SELECT 'Sample: Venue Performance Summary' as Info;
SELECT 
    v.VenueName,
    s.SportName,
    COUNT(b.BookingID) as Bookings,
    SUM(b.TotalAmount) as Revenue,
    AVG(f.Rating) as AvgRating
FROM Venues v
INNER JOIN Sports s ON v.SportID = s.SportID
LEFT JOIN Bookings b ON v.VenueID = b.VenueID
LEFT JOIN Feedback f ON v.VenueID = f.VenueID
GROUP BY v.VenueID, v.VenueName, s.SportName
ORDER BY Revenue DESC
LIMIT 5;