const bcrypt = require('bcrypt');

async function generateHashes() {
    const passwords = {
        'player123': 'player123',
        'venue123': 'venue123',
        'player456': 'player456',
        'player789': 'player789',
        'player101': 'player101',
        'player202': 'player202',
        'player303': 'player303',
        'player404': 'player404',
        'player505': 'player505',
        'venue456': 'venue456',
        'venue789': 'venue789',
        'venue101': 'venue101'
    };

    const saltRounds = 10;
    
    console.log('-- Updated password hashes for sample data:');
    
    for (const [key, password] of Object.entries(passwords)) {
        const hash = await bcrypt.hash(password, saltRounds);
        console.log(`-- ${key}: ${hash}`);
    }
}

generateHashes().catch(console.error);