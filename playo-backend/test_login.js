const bcrypt = require('bcrypt');

async function testLogin() {
    try {
        // Test if the password hash matches
        const testPassword = 'player123';
        const storedHash = '$2b$10$Pupwre/dJCoSd0tXCxWp3.sKbod/LwkMQlYkFU3P7QcoJXhSc/w9C';
        
        const isValid = await bcrypt.compare(testPassword, storedHash);
        console.log(`Password validation test: ${isValid}`);
        
        // Test API call
        const response = await fetch('http://localhost:5000/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                email: 'rahul.player@gmail.com',
                password: 'player123'
            })
        });
        
        const result = await response.text();
        console.log('API Response Status:', response.status);
        console.log('API Response:', result);
        
    } catch (error) {
        console.error('Test failed:', error);
    }
}

testLogin();