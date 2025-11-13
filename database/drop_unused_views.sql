-- ============================================
-- DROP UNUSED VIEWS - SAFE TO EXECUTE
-- ============================================
-- These 12 views are NOT used anywhere in:
--   ✓ Backend route files (verified)
--   ✓ Stored procedures
--   ✓ Triggers
--   ✓ Frontend code
-- 
-- Database: dbms_cp
-- Created: November 13, 2025
-- ============================================

USE dbms_cp;

-- Drop all 12 unused views
DROP VIEW IF EXISTS admindashboard;
DROP VIEW IF EXISTS availableslots;
DROP VIEW IF EXISTS availablevenues;
DROP VIEW IF EXISTS paymentsummary;
DROP VIEW IF EXISTS playeractivity;
DROP VIEW IF EXISTS players;
DROP VIEW IF EXISTS recentfeedback;
DROP VIEW IF EXISTS sportsoverview;
DROP VIEW IF EXISTS todaybookings;
DROP VIEW IF EXISTS userdetails;
DROP VIEW IF EXISTS venuefeedback;
DROP VIEW IF EXISTS venueowners;

-- ============================================
-- VERIFICATION QUERY (Run AFTER executing drops above)
-- ============================================
-- Check remaining views:
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'dbms_cp';

-- EXPECTED RESULT AFTER RUNNING THIS SCRIPT: 
-- Empty set (0 rows) - all 12 unused views dropped
-- 
-- Your backend queries base tables directly (Users, Venues, 
-- Bookings, Teams, etc.) so these views aren't needed
-- ============================================
