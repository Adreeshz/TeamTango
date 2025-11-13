
CREATE OR REPLACE VIEW user_profiles AS
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.PhoneNumber,
    u.Gender,
    u.Address,
    u.CreatedAt,
    r.RoleID,
    r.RoleName,
    COUNT(DISTINCT b.BookingID) as TotalBookings,
    COUNT(DISTINCT tm.TeamID) as TotalTeams,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as TotalSpent
FROM Users u
LEFT JOIN Roles r ON u.RoleID = r.RoleID
LEFT JOIN Bookings b ON u.UserID = b.UserID
LEFT JOIN TeamMembers tm ON u.UserID = tm.UserID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
GROUP BY u.UserID, u.Name, u.Email, u.PhoneNumber, u.Gender, u.Address, u.CreatedAt, r.RoleID, r.RoleName;

-- ============================================
-- 2. VENUE MANAGEMENT VIEWS
-- ============================================

-- View: Complete venue information with ratings
-- Use in: /api/venues endpoint (replace complex JOIN query)
CREATE OR REPLACE VIEW venue_summary AS
SELECT 
    v.VenueID,
    v.VenueName,
    v.Location,
    v.City,
    v.PricePerHour,
    v.OwnerID,
    u.Name as OwnerName,
    u.PhoneNumber as OwnerPhone,
    s.SportID,
    s.SportName,
    COUNT(DISTINCT f.FeedbackID) as TotalReviews,
    ROUND(AVG(f.Rating), 1) as AverageRating,
    COUNT(DISTINCT b.BookingID) as TotalBookings,
    COUNT(DISTINCT ts.TimeslotID) as TotalTimeslots,
    SUM(CASE WHEN ts.IsAvailable = TRUE AND ts.SlotDate >= CURDATE() THEN 1 ELSE 0 END) as AvailableSlots
FROM Venues v
LEFT JOIN Users u ON v.OwnerID = u.UserID
LEFT JOIN Sports s ON v.SportID = s.SportID
LEFT JOIN Feedback f ON v.VenueID = f.VenueID
LEFT JOIN Bookings b ON v.VenueID = b.VenueID
LEFT JOIN Timeslots ts ON v.VenueID = ts.VenueID
GROUP BY v.VenueID, v.VenueName, v.Location, v.City, v.PricePerHour, v.OwnerID, 
         u.Name, u.PhoneNumber, s.SportID, s.SportName;

-- ============================================
-- 3. TEAM MANAGEMENT VIEWS
-- ============================================

-- View: Team details with member counts and captain info
-- Use in: /api/teams endpoint (simplify your current query)
CREATE OR REPLACE VIEW team_summary AS
SELECT 
    t.TeamID,
    t.TeamName,
    t.CaptainID,
    u.Name as CaptainName,
    u.Email as CaptainEmail,
    u.PhoneNumber as CaptainPhone,
    s.SportID,
    s.SportName,
    COUNT(DISTINCT tm.UserID) as TotalMembers,
    SUM(CASE WHEN u2.Gender = 'Male' THEN 1 ELSE 0 END) as MaleMembers,
    SUM(CASE WHEN u2.Gender = 'Female' THEN 1 ELSE 0 END) as FemaleMembers,
    COUNT(DISTINCT m1.MatchID) + COUNT(DISTINCT m2.MatchID) as TotalMatches,
    SUM(CASE WHEN m1.Team1Score > m1.Team2Score OR m2.Team2Score > m2.Team1Score THEN 1 ELSE 0 END) as Wins
FROM Teams t
LEFT JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID
LEFT JOIN Users u2 ON tm.UserID = u2.UserID
LEFT JOIN Matches m1 ON t.TeamID = m1.Team1ID
LEFT JOIN Matches m2 ON t.TeamID = m2.Team2ID
GROUP BY t.TeamID, t.TeamName, t.CaptainID, u.Name, u.Email, u.PhoneNumber, 
         s.SportID, s.SportName;

-- ============================================
-- 4. BOOKING MANAGEMENT VIEWS
-- ============================================

-- View: Complete booking details with all related info
-- Use in: /api/bookings, /api/venues/:id/bookings endpoints
CREATE OR REPLACE VIEW booking_details AS
SELECT 
    b.BookingID,
    b.BookingDate,
    b.TotalAmount,
    b.BookingStatus,
    b.UserID,
    u.Name as PlayerName,
    u.Email as PlayerEmail,
    u.PhoneNumber as PlayerPhone,
    b.VenueID,
    v.VenueName,
    v.Location as VenueLocation,
    v.City as VenueCity,
    s.SportName,
    b.TimeslotID,
    ts.SlotDate,
    ts.StartTime,
    ts.EndTime,
    ts.PriceINR as SlotPrice,
    p.PaymentID,
    p.PaymentMethod,
    p.PaymentStatus,
    p.PaymentDate
FROM Bookings b
LEFT JOIN Users u ON b.UserID = u.UserID
LEFT JOIN Venues v ON b.VenueID = v.VenueID
LEFT JOIN Sports s ON v.SportID = s.SportID
LEFT JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
LEFT JOIN Payments p ON b.BookingID = p.BookingID;

-- ============================================
-- 5. PAYMENT & REVENUE VIEWS
-- ============================================

-- View: Venue owner revenue summary
-- Use in: Venue owner dashboard, analytics
CREATE OR REPLACE VIEW venue_revenue AS
SELECT 
    v.OwnerID,
    u.Name as OwnerName,
    v.VenueID,
    v.VenueName,
    COUNT(b.BookingID) as TotalBookings,
    COUNT(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1 END) as ConfirmedBookings,
    COUNT(CASE WHEN b.BookingStatus = 'Pending' THEN 1 END) as PendingBookings,
    SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END) as TotalRevenue,
    SUM(CASE WHEN p.PaymentStatus = 'Success' AND p.PaymentDate >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) 
        THEN p.Amount ELSE 0 END) as MonthlyRevenue
FROM Venues v
LEFT JOIN Users u ON v.OwnerID = u.UserID
LEFT JOIN Bookings b ON v.VenueID = b.VenueID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
GROUP BY v.OwnerID, u.Name, v.VenueID, v.VenueName;

-- ============================================
-- 6. MATCH & COMPETITION VIEWS
-- ============================================

-- View: Match details with team names and venue info
-- Use in: /api/matches endpoint
CREATE OR REPLACE VIEW match_details AS
SELECT 
    m.MatchID,
    m.MatchTitle,
    m.MatchDate,
    m.MatchTime,
    m.MatchStatus,
    m.Team1ID,
    t1.TeamName as Team1Name,
    m.Team1Score,
    m.Team2ID,
    t2.TeamName as Team2Name,
    m.Team2Score,
    m.VenueID,
    v.VenueName,
    v.Location as VenueLocation,
    v.City as VenueCity,
    s.SportName,
    CASE 
        WHEN m.Team1Score > m.Team2Score THEN t1.TeamName
        WHEN m.Team2Score > m.Team1Score THEN t2.TeamName
        WHEN m.Team1Score = m.Team2Score AND m.MatchStatus = 'Completed' THEN 'Draw'
        ELSE NULL
    END as Winner
FROM Matches m
LEFT JOIN Teams t1 ON m.Team1ID = t1.TeamID
LEFT JOIN Teams t2 ON m.Team2ID = t2.TeamID
LEFT JOIN Venues v ON m.VenueID = v.VenueID
LEFT JOIN Sports s ON t1.SportID = s.SportID;

-- ============================================
-- 7. DASHBOARD/ANALYTICS VIEWS
-- ============================================

-- View: Today's activity summary
-- Use in: Admin dashboard, venue owner dashboard
CREATE OR REPLACE VIEW today_summary AS
SELECT 
    (SELECT COUNT(*) FROM Bookings WHERE BookingDate = CURDATE()) as TodayBookings,
    (SELECT COUNT(*) FROM Bookings WHERE BookingDate = CURDATE() AND BookingStatus = 'Confirmed') as ConfirmedToday,
    (SELECT COUNT(*) FROM Matches WHERE MatchDate = CURDATE()) as TodayMatches,
    (SELECT SUM(Amount) FROM Payments WHERE PaymentDate = CURDATE() AND PaymentStatus = 'Success') as TodayRevenue,
    (SELECT COUNT(*) FROM Users WHERE DATE(CreatedAt) = CURDATE()) as NewUsers;


