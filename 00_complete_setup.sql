-- ================================================
-- TeamTango Complete Setup Script (Run All)
-- Purpose: Execute all database setup scripts in correct order
-- Date: October 5, 2025
-- Usage: mysql -u root -p < 00_complete_setup.sql
-- ================================================

-- This script runs all the setup files in the correct order
-- Make sure all SQL files are in the same directory

SELECT '================================================' as Info;
SELECT 'TeamTango Database Complete Setup Starting...' as Status;
SELECT '================================================' as Info;

-- Step 1: Database Creation
SELECT 'Step 1: Creating Database Structure...' as CurrentStep;
SOURCE 01_database_creation.sql;

-- Step 2: Sample Data Insertion  
SELECT 'Step 2: Inserting Sample Data...' as CurrentStep;
SOURCE 02_sample_data_insertion.sql;

-- Step 3: User Classification System
SELECT 'Step 3: Implementing User Classification System...' as CurrentStep;
SOURCE 03_user_classification_system.sql;

-- Final Status Report
SELECT '================================================' as Info;
SELECT 'TeamTango Database Setup Complete!' as Status;
SELECT '================================================' as Info;

-- Show final statistics
SELECT 
    'Database Statistics:' as Section,
    (SELECT COUNT(*) FROM Users) as TotalUsers,
    (SELECT COUNT(*) FROM Venues) as TotalVenues,
    (SELECT COUNT(*) FROM Teams) as TotalTeams,
    (SELECT COUNT(*) FROM Sports) as TotalSports,
    (SELECT COUNT(*) FROM Bookings) as TotalBookings,
    (SELECT COUNT(*) FROM UserActivityLog) as ActivityLogs;

-- Show user distribution by role
SELECT 'User Role Distribution:' as Section;
SELECT 
    r.RoleName,
    COUNT(u.UserID) as Count,
    GROUP_CONCAT(u.Name SEPARATOR ', ') as Users
FROM Roles r
LEFT JOIN Users u ON r.RoleID = u.RoleID
WHERE r.RoleID IN (1, 2)
GROUP BY r.RoleID, r.RoleName;

-- Show venue distribution by location
SELECT 'Venue Distribution:' as Section;
SELECT 
    Location,
    COUNT(*) as VenueCount,
    GROUP_CONCAT(VenueName SEPARATOR ', ') as Venues
FROM Venues
GROUP BY Location;

-- Show next steps
SELECT 'Next Steps:' as Section,
       '1. Start the Node.js server: node server.js' as Step1,
       '2. Visit: http://localhost:5000' as Step2,
       '3. Register new users or use demo accounts' as Step3,
       '4. Test the booking and team management features' as Step4;