// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Script Populas Pemain
// File: backend/populate_players.js
// Deskripsi: Script utilitas untuk memperbarui rincian profil pemain sepak bola
//            (nomor punggung, tanggal lahir, tinggi/berat badan, dll.) di database
//            JSON berdasarkan data rujukan statis (Real Madrid Roster).
// ==========================================================================

const fs = require('fs');

// Path database JSON lokal
const file = 'database.json';
const db = JSON.parse(fs.readFileSync(file, 'utf8'));

// Data rujukan profil pemain Real Madrid
const rawData = [
  { nama: "Thibaut Courtois", no: 1, tgllahir: "1992-05-11", pos: "GK", posisiAlternatif: "None", tinggi: 200, berat: 96, status: "Aktif", tipe: "Defensive" },
  { nama: "Andriy Lunin", no: 13, tgllahir: "1999-02-11", pos: "GK", posisiAlternatif: "None", tinggi: 191, berat: 80, status: "Aktif", tipe: "Defensive" },
  { nama: "Dani Carvajal", no: 2, tgllahir: "1992-01-10", pos: "RB", posisiAlternatif: "None", tinggi: 173, berat: 73, status: "Aktif", tipe: "Balanced" },
  { nama: "Éder Militão", no: 3, tgllahir: "1998-01-17", pos: "CB", posisiAlternatif: "RB", tinggi: 186, berat: 79, status: "Aktif", tipe: "Defensive" },
  { nama: "David Alaba", no: 4, tgllahir: "1992-06-24", pos: "CB", posisiAlternatif: "LB", tinggi: 180, berat: 78, status: "Cedera", tipe: "Balanced" },
  { nama: "T. Alexander-Arnold", no: 12, tgllahir: "1998-10-06", pos: "RB", posisiAlternatif: "CMF", tinggi: 175, berat: 69, status: "Aktif", tipe: "Attacking" },
  { nama: "Antonio Rüdiger", no: 22, tgllahir: "1993-03-03", pos: "CB", posisiAlternatif: "LB", tinggi: 191, berat: 83, status: "Aktif", tipe: "Defensive" },
  { nama: "Ferland Mendy", no: 23, tgllahir: "1995-06-08", pos: "LB", posisiAlternatif: "None", tinggi: 180, berat: 73, status: "Aktif", tipe: "Defensive" },
  { nama: "Fran García", no: 20, tgllahir: "1999-08-14", pos: "LB", posisiAlternatif: "None", tinggi: 169, berat: 69, status: "Aktif", tipe: "Attacking" },
  { nama: "Aurélien Tchouaméni", no: 18, tgllahir: "2000-01-27", pos: "DMF", posisiAlternatif: "CB", tinggi: 187, berat: 81, status: "Aktif", tipe: "Defensive" },
  { nama: "Eduardo Camavinga", no: 6, tgllahir: "2002-11-10", pos: "CMF", posisiAlternatif: "LB", tinggi: 182, berat: 68, status: "Aktif", tipe: "Balanced" },
  { nama: "Federico Valverde", no: 15, tgllahir: "1998-07-22", pos: "CMF", posisiAlternatif: "RW", tinggi: 182, berat: 78, status: "Aktif", tipe: "Balanced" },
  { nama: "Jude Bellingham", no: 5, tgllahir: "2003-06-29", pos: "AMF", posisiAlternatif: "CMF", tinggi: 186, berat: 75, status: "Aktif", tipe: "Attacking" },
  { nama: "Brahim Díaz", no: 21, tgllahir: "1999-08-03", pos: "AMF", posisiAlternatif: "RW", tinggi: 171, berat: 68, status: "Aktif", tipe: "Attacking" },
  { nama: "Arda Güler", no: 24, tgllahir: "2005-02-25", pos: "AMF", posisiAlternatif: "RW", tinggi: 176, berat: 70, status: "Aktif", tipe: "Attacking" },
  { nama: "Dani Ceballos", no: 19, tgllahir: "1996-08-07", pos: "CMF", posisiAlternatif: "AMF", tinggi: 179, berat: 70, status: "Aktif", tipe: "Balanced" },
  { nama: "Vinícius Júnior", no: 7, tgllahir: "2000-07-12", pos: "LW", posisiAlternatif: "ST", tinggi: 176, berat: 73, status: "Aktif", tipe: "Attacking" },
  { nama: "Rodrygo", no: 11, tgllahir: "2001-01-09", pos: "RW", posisiAlternatif: "LW", tinggi: 174, berat: 64, status: "Aktif", tipe: "Attacking" },
  { nama: "Kylian Mbappé", no: 9, tgllahir: "1998-12-20", pos: "ST", posisiAlternatif: "LW", tinggi: 178, berat: 75, status: "Aktif", tipe: "Attacking" },
  { nama: "Raúl Asencio", no: 35, tgllahir: "2003-02-13", pos: "CB", posisiAlternatif: "RB", tinggi: 184, berat: 78, status: "Aktif", tipe: "Defensive" },
  { nama: "Gonzalo García", no: 16, tgllahir: "2004-03-24", pos: "ST", posisiAlternatif: "RW", tinggi: 182, berat: 74, status: "Aktif", tipe: "Attacking" },
  { nama: "Álvaro Carreras", no: 18, tgllahir: "2003-03-23", pos: "LB", posisiAlternatif: "None", tinggi: 186, berat: 75, status: "Aktif", tipe: "Balanced" },
  { nama: "Dean Huijsen", no: 24, tgllahir: "2005-04-14", pos: "CB", posisiAlternatif: "DMF", tinggi: 197, berat: 87, status: "Aktif", tipe: "Defensive" },
  { nama: "Franco Mastantuono", no: 30, tgllahir: "2007-08-14", pos: "RW", posisiAlternatif: "AMF", tinggi: 177, berat: 71, status: "Aktif", tipe: "Attacking" }
];

// Cari dan hubungkan data rujukan ke data database.json berdasarkan kesamaan nama
db.playersData.forEach(p => {
  // Bersihkan penanda (C) Kapten atau (VC) Wakil Kapten sebelum mencocokkan nama
  let basename = p.nama.replace(' (C)', '').replace(' (VC)', '').trim();
  let match = rawData.find(r => r.nama.includes(basename) || basename.includes(r.nama));
  if (!match) {
    if (basename.includes('Alexander')) match = rawData.find(r => r.nama.includes('Alexander-Arnold'));
  }
  
  // Jika ditemukan kecocokan, isi data profil teknis pemain
  if (match) {
    p.no = match.no;
    p.tgllahir = match.tgllahir;
    p.pos = match.pos;
    p.posisiAlternatif = match.posisiAlternatif;
    p.tinggi = match.tinggi;
    p.berat = match.berat;
    p.status = match.status; // Aktif, Cedera, Suspend
    p.tipe = match.tipe;
  }
});

// Tulis kembali database yang sudah diperbarui ke database.json
fs.writeFileSync(file, JSON.stringify(db, null, 2));
console.log('Semua detail pemain telah dimodifikasi.');
