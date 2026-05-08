const fs = require('fs');

const file = 'database.json';
const data = JSON.parse(fs.readFileSync(file, 'utf8'));

data.playersData.forEach(p => {
  if (p.nama === 'Dani Carvajal' || p.nama === 'Dani Carvajal (Captain)') {
    p.nama = 'Dani Carvajal (C)';
  } else if (p.nama === 'Federico Valverde' || p.nama === 'Federico Valverde (Vice-Captain)') {
    p.nama = 'Federico Valverde (VC)';
  }
});

fs.writeFileSync(file, JSON.stringify(data, null, 2));
console.log('Captains set successfully.');
