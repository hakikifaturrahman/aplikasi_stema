// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Script Tambah Kapten
// File: backend/add_captain.js
// Deskripsi: Script utilitas sekali pakai untuk memperbarui nama kapten tim (Dani Carvajal)
//            dan wakil kapten (Federico Valverde) pada playersData di database JSON.
// ==========================================================================

const fs = require('fs');

// Path menuju file database JSON lokal
const file = 'database.json';

// Membaca dan mem-parsing isi database.json
const data = JSON.parse(fs.readFileSync(file, 'utf8'));

// Lakukan perulangan untuk mencari pemain yang dimaksud dan tambahkan label (C) dan (VC)
data.playersData.forEach(p => {
  if (p.nama === 'Dani Carvajal' || p.nama === 'Dani Carvajal (Captain)') {
    p.nama = 'Dani Carvajal (C)';
  } else if (p.nama === 'Federico Valverde' || p.nama === 'Federico Valverde (Vice-Captain)') {
    p.nama = 'Federico Valverde (VC)';
  }
});

// Tulis kembali data terbaru ke database.json dengan format rapi (indentasi 2 spasi)
fs.writeFileSync(file, JSON.stringify(data, null, 2));
console.log('Captains set successfully.');
