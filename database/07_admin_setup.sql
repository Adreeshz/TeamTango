-- Update Admin Passwords for Testing
-- This script updates the admin passwords to 'admin123' for demo purposes

-- Note: In production, use proper bcrypt hashing
-- For demo purposes, using a pre-computed bcrypt hash for 'admin123'
-- Hash: $2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi

UPDATE Users 
SET Password = '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' 
WHERE Email IN ('admin@example.com', 'admin@teamtango.com');

-- Verify the admin users
SELECT UserID, Name, Email, RoleID 
FROM Users 
WHERE RoleID = 3;

-- Display admin login information
SELECT 
    '=== ADMIN LOGIN CREDENTIALS ===' as Info
UNION ALL
SELECT 'Email: admin@teamtango.com'
UNION ALL  
SELECT 'Password: admin123'
UNION ALL
SELECT 'Role: System Administrator'
UNION ALL
SELECT '===========================' as Info;