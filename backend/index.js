// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Backend Server Entrypoint
// File: backend/index.js
// Deskripsi: Server Node.js/Express dengan komunikasi real-time menggunakan Socket.io.
//            Mengelola data pemain, riwayat pertandingan, aturan rule engine, dan
//            autentikasi pengguna secara real-time menggunakan database JSON lokal.
// ==========================================================================

const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Lokasi penyimpanan file database JSON lokal (dinamis via DATABASE_PATH untuk hosting/persistent volume)
const dbPath = process.env.DATABASE_PATH || path.join(__dirname, 'database.json');

// Memastikan folder penyimpanan file database sudah terbentuk (terutama jika menggunakan volume eksternal)
const dbDir = path.dirname(dbPath);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}


// ==========================================================================
// --- SISTEM DATABASE LOKAL PERMANEN (JSON FILE) ---
// Alternatif handal & bebas error dari SQLite tanpa instalasi tambahan.
// Membaca data dari database.json dan melakukan inisialisasi jika file tidak ada.
// ==========================================================================
function loadDB() {
  try {
    const defaultDbPath = path.join(__dirname, 'database.json');
    
    // Jika file volume eksternal belum terbentuk, tapi ada database bawaan repository, salin terlebih dahulu
    if (!fs.existsSync(dbPath) && dbPath !== defaultDbPath && fs.existsSync(defaultDbPath)) {
      console.log('📦 Menyalin database.json default dari repository ke volume...');
      fs.copyFileSync(defaultDbPath, dbPath);
    }

    if (fs.existsSync(dbPath)) {
      console.log('📦 Database ditemukan! Memuat data asli...');
      const raw = fs.readFileSync(dbPath, 'utf8');
      const data = JSON.parse(raw);

      // Memastikan struktur data accountsData ada
      if (!data.accountsData) data.accountsData = [];
      
      // Menambahkan akun Super Admin default jika belum terdaftar
      const adminExists = data.accountsData.some(u => u.email === "admin@stema.com");
      if (!adminExists) {
        data.accountsData.push({
          nama: "Super Admin",
          email: "admin@stema.com",
          password: "admin123",
          role: "Super Administrator",
          foto: null
        });
      }

      // Memaksa override details profil admin jika masih menggunakan placeholder lama
      if (!data.userData || data.userData.email === "ancok@12.com" || data.userData.email === "arbeloa@realfootball.com") {
        data.userData = {
          nama: "Super Admin",
          email: "admin@stema.com",
          role: "Super Administrator",
          foto: null
        };
      }

      return data;
    }
  } catch (err) {
    console.error('Error saat Load DB:', err);
  }
  
  // Jika database tidak ditemukan, buat data awal (initial data)
  console.log('📦 Membuat Database Baru (Initial Data)...');
  return {
    // Roster Pemain Awal (Real Madrid)
    playersData: [
      { nama: 'Kylian Mbappe', no: 9, pos: 'FW', stamina: 78, status: 'Main' },
      { nama: 'Jude Bellingham', no: 8, pos: 'MF', stamina: 35, status: 'Main' },
      { nama: 'Vinicius Junior', no: 7, pos: 'FW', stamina: 62, status: 'Main' },
      { nama: 'Fede Valverde', no: 15, pos: 'MF', stamina: 55, status: 'Main' },
      { nama: 'Antonio Rudiger', no: 22, pos: 'DF', stamina: 88, status: 'Main' },
      { nama: 'Eduardo Camavinga', no: 12, pos: 'MF', stamina: 100, status: 'Cadangan'},
      { nama: 'Thibaut Courtois', no: 1, pos: 'GK', stamina: 0, status: 'Cedera' },
      { nama: 'Eder Militao', no: 3, pos: 'DF', stamina: 0, status: 'Cedera' },
    ],
    // Akun Pengguna Awal
    accountsData: [
      {
        nama: "Super Admin",
        email: "admin@stema.com",
        password: "admin123",
        role: "Super Administrator",
        foto: null
      }
    ],
    riwayatMatches: [],
    // Template Aturan Rule Engine Default
    rulesData: [
      {
        id: 'R1',
        nama: 'Rekomendasi Substitusi',
        tipe: 'Fatigue Rule',
        if: 'Stamina < 40 AND Menit > 60',
        then: 'Rekomendasi Substitusi',
        aktif: true,
        triggered: 'Belum terpicu'
      },
      {
        id: 'R2',
        nama: 'Intensive Pressing',
        tipe: 'Tactical Rule',
        if: 'Menit < 30 AND Status = Menang',
        then: 'Pertahankan Tekanan',
        aktif: false,
        triggered: 'Belum terpicu'
      },
      {
        id: 'R3',
        nama: 'Performance Alert',
        tipe: 'Performance Rule',
        if: 'Rating < 5 AND Kesalahan > 3',
        then: 'Pertimbangkan penggantian posisi',
        aktif: true,
        triggered: 'Belum terpicu'
      }
    ],
    userData: {
      nama: 'Super Admin',
      email: 'admin@stema.com',
      role: 'Super Administrator',
      foto: null
    }
  };
}

// Menyimpan data memori ke file database.json
function saveDB() {
  try {
    fs.writeFileSync(dbPath, JSON.stringify({ playersData, riwayatMatches, rulesData, userData, accountsData }, null, 2));
  } catch (err) {
    console.error('Error gagal menyimpan DB:', err);
  }
}
// --------------------------------------------------------------------------

// Inisialisasi aplikasi Express dan Server HTTP
const app = express();
const server = http.createServer(app);

// Pengaturan Middleware Express
app.use(cors());
app.use(express.json());

// Setup Socket.IO Server untuk Komunikasi Dua Arah Real-Time
const io = new Server(server, {
  cors: {
    origin: "*", // Mengizinkan akses dari aplikasi mobile Flutter dan Next.js Web Admin
    methods: ["GET", "POST"]
  }
});

// State real-time dari pertandingan berjalan (Match Status)
let liveData = {
  skor1: 0,
  skor2: 0,
  menit: 0,
  isLive: false,
  fase: 'Persiapan',
  menitLebih: 0,
  penalti1: 0,
  penalti2: 0
};

// Memuat Data Permanen dari Database ke Variabel Memori Server
let initialDB = loadDB();
let playersData = initialDB.playersData;
let riwayatMatches = initialDB.riwayatMatches;
let accountsData = initialDB.accountsData || [];

// Inisialisasi atribut kemampuan default (speed, shooting, dll.) jika tidak terdefinisi
playersData = playersData.map(p => {
  if (!p.attributes) {
     if (p.pos === 'FW') p.attributes = { speed: 85, shooting: 88, passing: 75, defensive: 30, vision: 80, stamina: 75, dribbling: 90 };
     else if (p.pos === 'MF') p.attributes = { speed: 75, shooting: 78, passing: 90, defensive: 65, vision: 88, stamina: 85, dribbling: 85 };
     else if (p.pos === 'DF') p.attributes = { speed: 70, shooting: 50, passing: 75, defensive: 90, vision: 65, stamina: 80, dribbling: 60 };
     else p.attributes = { speed: 60, shooting: 30, passing: 65, defensive: 60, vision: 60, stamina: 70, dribbling: 50 };
  }
  return p;
});

// Fallback array jika rulesData belum ada di file database lama
let rulesData = initialDB.rulesData || [
  { id: 'R1', nama: 'Rekomendasi Substitusi', tipe: 'Fatigue', if: 'Stamina < 40 AND Menit > 60', then: 'Ganti', aktif: true, triggered: '-' }
];

// Fallback profil pengguna aktif jika tidak ada
let userData = initialDB.userData || {
  nama: 'Alvaro Arbeloa',
  email: 'arbeloa@realfootball.com',
  telp: '+62 812 3456 7890',
  role: 'Pelatih'
};

// Simpan data kembali untuk sinkronisasi format database
saveDB();

// ==========================================================================
// --- PENANGANAN SOCKET.IO CONNECTION ---
// Mengelola seluruh event real-time dari aplikasi Mobile dan Web Admin
// ==========================================================================
io.on('connection', (socket) => {
  console.log(`[+] User connected: ${socket.id}`);

  // Kirim data teraktual saat klien baru berhasil terhubung (initial sync)
  socket.emit('live_match_sync', liveData);
  socket.emit('stamina_sync', playersData);
  socket.emit('riwayat_sync', riwayatMatches);
  socket.emit('rules_sync', rulesData);
  socket.emit('user_sync', userData);

  // --- LOGIKA EVENT AUTENTIKASI ---
  
  // Menerima data pendaftaran akun baru
  socket.on('register', (data) => {
    const { nama, email, password, role } = data;
    if (!nama || !email || !password || !role) {
      socket.emit('register_response', { success: false, message: 'Semua kolom wajib diisi!' });
      return;
    }
    const isExist = accountsData.find(u => u.email === email);
    if (isExist) {
      socket.emit('register_response', { success: false, message: 'Email sudah terdaftar!' });
      return;
    }
    accountsData.push({ nama, email, password, role });
    saveDB();
    socket.emit('register_response', { success: true, message: 'Registrasi berhasil! Silakan Login.' });
  });

  // Memvalidasi data login pengguna
  socket.on('login', (data) => {
    const { email, password } = data;
    if (!email || !password) {
      socket.emit('login_response', { success: false, message: 'Email dan password wajib diisi!' });
      return;
    }
    const user = accountsData.find(u => u.email === email && u.password === password);
    if (!user) {
      socket.emit('login_response', { success: false, message: 'Email atau password salah!' });
      return;
    }
    // Perbarui profil pengguna aktif di server
    userData.nama = user.nama;
    userData.email = user.email;
    userData.role = user.role || 'Pelatih Utama';
    userData.foto = user.foto || null;
    saveDB();
    // Beritahu semua klien bahwa user aktif berubah
    io.emit('user_sync', userData);
    socket.emit('login_response', { success: true, message: 'Login berhasil!', user: { nama: user.nama, email: user.email, role: user.role } });
  });

  // Mengubah password pengguna
  socket.on('change_password', (data) => {
    const { email, oldPassword, newPassword } = data;
    const userIndex = accountsData.findIndex(u => u.email === email && u.password === oldPassword);
    
    if (userIndex === -1) {
      socket.emit('password_response', { success: false, message: 'Password lama salah atau akun tidak ditemukan!' });
      return;
    }

    accountsData[userIndex].password = newPassword;
    saveDB();
    socket.emit('password_response', { success: true, message: 'Password berhasil diubah!' });
  });

  // --- LOGIKA EVENT PERTANDINGAN REAL-TIME ---

  // Menerima update skor, menit, dan fase pertandingan dari tim kontrol (klien)
  socket.on('update_match', (data) => {
    liveData = { ...liveData, ...data };
    io.emit('live_match_sync', liveData); 
  });

  // Mengirim ulang data teraktual ke klien secara langsung (manual refresh)
  socket.on('request_sync', () => {
    socket.emit('live_match_sync', liveData);
    socket.emit('stamina_sync', playersData);
    socket.emit('riwayat_sync', riwayatMatches);
    socket.emit('rules_sync', rulesData);
    socket.emit('user_sync', userData);
  });

  // Menerima permintaan sinkronisasi profil admin dari panel web
  socket.on('request_admin_sync', () => {
    const adminAccount = accountsData.find(u => u.email === "admin@stema.com") || {
      nama: "Super Admin",
      email: "admin@stema.com",
      role: "Super Administrator",
      foto: null
    };
    socket.emit('admin_sync', adminAccount);
  });

  // Memperbarui data informasi profil pengguna (termasuk foto Base64)
  socket.on('update_user', (data) => {
    // Pembaruan khusus akun super admin
    if (data.email === "admin@stema.com") {
      const adminIndex = accountsData.findIndex(u => u.email === data.email);
      if (adminIndex !== -1) {
        accountsData[adminIndex].nama = data.nama || accountsData[adminIndex].nama;
        if (data.foto !== undefined) {
           accountsData[adminIndex].foto = data.foto;
        }
        saveDB();
        io.emit('admin_sync', accountsData[adminIndex]);
      }
      return;
    }

    userData = { ...userData, ...data };
    
    // Perbarui atau daftarkan akun baru di database lokal
    if (data.email) {
      const userIndex = accountsData.findIndex(u => u.email === data.email);
      if (userIndex !== -1) {
        accountsData[userIndex].nama = data.nama || accountsData[userIndex].nama;
        accountsData[userIndex].role = data.role || accountsData[userIndex].role;
        if (data.foto !== undefined) {
           accountsData[userIndex].foto = data.foto;
        }
      } else {
        accountsData.push({
          nama: userData.nama,
          email: userData.email,
          password: "admin123", // Password bawaan
          role: userData.role || 'Pelatih Utama',
          foto: userData.foto || null
        });
      }
    }
    
    saveDB();
    io.emit('user_sync', userData);
  });

  // Mengakhiri pertandingan, menghitung performa rata-rata, dan menyusun laporan riwayat
  socket.on('finish_match', (data = {}) => {
    console.log('📌 MATCH SELESAI! MENYIMPAN RIWAYAT...', data);
    
    // Tentukan hasil akhir (W = Menang, D = Seri, L = Kalah)
    let finalHasil = liveData.skor1 > liveData.skor2 ? 'W' : (liveData.skor1 === liveData.skor2 ? 'D' : 'L');
    let finalSkorStr = `${liveData.skor1} - ${liveData.skor2}`;
    
    // Jika fase saat ini adalah adu penalti
    if (liveData.penalti1 > 0 || liveData.penalti2 > 0 || liveData.fase === 'Penalti') {
       finalSkorStr += ` (${liveData.penalti1} - ${liveData.penalti2} PEN)`;
       finalHasil = liveData.penalti1 > liveData.penalti2 ? 'W' : (liveData.penalti1 === liveData.penalti2 ? 'D' : 'L');
     }

    const totalYellow = playersData.filter(p => p.kartu === 'Kuning').length;
    const totalRed = playersData.filter(p => p.kartu === 'Merah').length;
    
    // Atur data statistik default/acak jika input kosong
    const possessionStr = data.possession && data.possession.trim() !== '' ? `${data.possession}%` : `${Math.floor(Math.random() * 30 + 35)}%`;
    const passesStr = data.passes && data.passes.trim() !== '' ? data.passes : `${Math.floor(Math.random() * 300 + 200)}`;
    const totalShots = data.shots != null && data.shots > 0 ? data.shots.toString() : Math.floor(Math.random() * 15 + 5).toString();
    const totalShotsTarget = data.shotsOnTarget != null && data.shotsOnTarget > 0 ? data.shotsOnTarget.toString() : Math.floor(Math.random() * 8 + 2).toString();

    // Menyusun objek laporan riwayat pertandingan
    const reportData = {
      tanggal: new Date().toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
      timKandang: data.timKandang || 'Real Madrid',
      lawan: data.timTandang || 'Manchester City',
      skor: finalSkorStr,
      hasil: finalHasil,
      totalSubstitusi: Math.floor(Math.random() * 5),
      statistikTim: [
        {label: 'Ball Possession', nilai: possessionStr},
        {label: 'Total Shots', nilai: totalShots},
        {label: 'Shots on Target', nilai: totalShotsTarget},
        {label: 'Passes', nilai: passesStr},
        {label: 'Kartu Kuning', nilai: totalYellow.toString()},
        {label: 'Kartu Merah', nilai: totalRed.toString()}
      ],
      rekomendasi: [
        `✅ Match Selesai: ${data.timKandang || 'Real Madrid'} melawan ${data.timTandang || 'Manchester City'}.`,
      ],
      performaPemain: playersData.filter(p => p.status === 'Main' || p.status === 'Pemanasan' || p.status === 'Cadangan' || p.status === 'Kartu Kuning' || p.status === 'Kartu Merah').map(p => ({
        nama: p.nama,
        pos: p.pos,
        rating: parseFloat((Math.random() * 3 + 6.0).toFixed(1)), // Acak rating pemain 6.0 - 9.0
        sprint: Math.floor(Math.random() * 40 + 5),
        assist: p.assist || 0,
        gol: p.gol || 0,
        goalEvents: p.goalEvents || [],
        kartu: p.kartu || '-'
      }))
    };

    // Sisipkan laporan ke tumpukan riwayat paling atas
    riwayatMatches.unshift(reportData);
    io.emit('riwayat_sync', riwayatMatches);

    // KEMUDIAN LAKUKAN GLOBAL RESET STAMINA & STATISTIK PEMAIN
    liveData = {
      skor1: 0,
      skor2: 0,
      menit: 0,
      isLive: false,
      fase: 'Persiapan',
      menitLebih: 0,
      penalti1: 0,
      penalti2: 0
    };
    playersData = playersData.map(p => {
      if (p.status === 'Main' || p.status === 'Pemanasan' || p.status === 'Kartu Kuning') p.stamina = Math.floor(Math.random() * 15 + 85); // Stamina reset acak 85-100%
      if (p.status === 'Cadangan' || p.status === 'Kartu Merah') p.stamina = 100;
      if (p.status === 'Kartu Merah') p.status = 'Cadangan'; 
      if (p.status === 'Kartu Kuning') p.status = 'Main'; 
      p.kartu = '-'; 
      p.gol = 0; 
      p.goalEvents = []; 
      p.assist = 0;
      return p;
    });

    saveDB();
    
    // Sinkronisasi data reset ke semua klien
    io.emit('live_match_sync', liveData);
    io.emit('stamina_sync', playersData);
    console.log('📌 GLOBAL RESET SELESAI & DB DISIMPAN');
  });

  // Menyimpan data pertandingan yang dimasukkan secara manual (offline history)
  socket.on('save_manual_match', (data) => {
    console.log('📌 MENYIMPAN MATCH MANUAL:', data.namaPertandingan);
    
    const reportData = {
      tanggal: data.tanggal || new Date().toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }),
      timKandang: data.kompetisi || 'Manual Entry',
      lawan: data.lawan || 'Unknown',
      skor: data.skorAkhir || '0 - 0',
      hasil: data.hasilAkhir.includes('W') ? 'W' : (data.hasilAkhir.includes('D') ? 'D' : 'L'),
      totalSubstitusi: 0,
      statistikTim: [
        {label: 'Formasi', nilai: data.formasi || '4-3-3'},
        {label: 'Catatan', nilai: data.catatan || '-'},
        {label: 'Pemain Inti', nilai: '11'}
      ],
      rekomendasi: [
         `✅ Pertandingan didaftarkan secara manual: ${data.namaPertandingan}`
      ],
      performaPemain: (data.startingXI || []).map(namaPemain => {
         const found = playersData.find(p => p.nama === namaPemain);
         return {
           nama: namaPemain,
           pos: found ? found.pos : 'N/A',
           rating: parseFloat((Math.random() * 2 + 6.5).toFixed(1)),
           sprint: Math.floor(Math.random() * 30 + 10),
           assist: 0,
           gol: 0
         };
      })
    };

    riwayatMatches.unshift(reportData);
    saveDB();
    io.emit('riwayat_sync', riwayatMatches);
  });

  // --- LOGIKA EVENT PENGELOLAAN PEMAIN ---

  // Menambahkan pemain baru ke database roster
  socket.on('add_player', (newPlayer) => {
    console.log('📌 MENAMBAHKAN PEMAIN BARU:', newPlayer.nama);
    
    const pos = newPlayer.pos || 'CM';
    let attr = newPlayer.attributes;
    if (!attr) {
      if (pos.includes('FW') || pos.includes('ST') || pos.includes('RW') || pos.includes('LW')) attr = { speed: 85, shooting: 88, passing: 75, defensive: 30, vision: 80, stamina: 75, dribbling: 90 };
      else if (pos.includes('MF') || pos.includes('CM') || pos.includes('LM') || pos.includes('RM') || pos.includes('AM')) attr = { speed: 75, shooting: 78, passing: 90, defensive: 65, vision: 88, stamina: 85, dribbling: 85 };
      else if (pos.includes('DF') || pos.includes('CB') || pos.includes('LB') || pos.includes('RB')) attr = { speed: 70, shooting: 50, passing: 75, defensive: 90, vision: 65, stamina: 80, dribbling: 60 };
      else attr = { speed: 60, shooting: 30, passing: 65, defensive: 60, vision: 60, stamina: 70, dribbling: 50 }; // GK
    }

    let initialStamina = newPlayer.stamina || 100;
    if (newPlayer.status === 'Cedera') initialStamina = 0;
    else if (newPlayer.status === 'Main' || newPlayer.status === 'Cadangan') initialStamina = 100;

    playersData.push({
      nama: newPlayer.nama,
      no: newPlayer.no,
      pos: newPlayer.pos,
      stamina: initialStamina,
      status: newPlayer.status || 'Main',
      attributes: attr,
    });
    saveDB();
    io.emit('stamina_sync', playersData);
  });

  // Menghapus pemain berdasarkan nama
  socket.on('delete_player', (playerName) => {
    console.log('📌 MENGHAPUS PEMAIN:', playerName);
    playersData = playersData.filter(p => p.nama !== playerName);
    saveDB();
    io.emit('stamina_sync', playersData);
  });

  // Mengedit data pemain, mengotomatisasi status kartu, dan menyesuaikan stamina berdasarkan perubahan status
  socket.on('edit_player', (updatedPlayer) => {
    console.log('📌 MENGEDIT PEMAIN:', updatedPlayer.originalName);
    const idx = playersData.findIndex(p => p.nama === updatedPlayer.originalName);
    if (idx !== -1) {
      const oldStatus = playersData[idx].status;
      
      // Deteksi status kartu
      if (updatedPlayer.status === 'Kartu Kuning') {
         updatedPlayer.kartu = 'Kuning';
         updatedPlayer.status = 'Main';
      } else if (updatedPlayer.status === 'Kartu Merah') {
         updatedPlayer.kartu = 'Merah';
      } else {
         updatedPlayer.kartu = '-';
      }
      
      // Deteksi penambahan/pengurangan gol pemain untuk mengupdate skor global real-time
      const oldGol = playersData[idx].gol || 0;
      const newGol = updatedPlayer.gol || 0;
      
      if (newGol !== oldGol) {
        liveData.skor1 += (newGol - oldGol);
        if (liveData.skor1 < 0) liveData.skor1 = 0;

        if (newGol > oldGol) {
           if (!playersData[idx].goalEvents) playersData[idx].goalEvents = [];
           let goalTime = liveData.menit.toString();
           if (liveData.fase.includes('Injury') || liveData.menitLebih > 0) {
               goalTime = `${liveData.menit}+${liveData.menitLebih}`;
           }
           playersData[idx].goalEvents.push(goalTime);
        } else if (newGol < oldGol) {
           if (playersData[idx].goalEvents && playersData[idx].goalEvents.length > 0) {
              playersData[idx].goalEvents.pop();
           }
        }

        io.emit('live_match_sync', liveData);
      }

      playersData[idx] = { ...playersData[idx], ...updatedPlayer };
      
      // Sesuaikan stamina otomatis berdasarkan transisi status baru
      if (oldStatus !== playersData[idx].status) {
         if (playersData[idx].status === 'Main' || playersData[idx].status === 'Kartu Kuning') {
            if (oldStatus !== 'Pemanasan') {
               playersData[idx].stamina = 100;
            }
         } else if (playersData[idx].status === 'Cadangan') {
            playersData[idx].stamina = 100;
         } else if (playersData[idx].status.startsWith('Cedera') || playersData[idx].status === 'Kartu Merah') {
            playersData[idx].stamina = 0;
         }
      }

      delete playersData[idx].originalName;
      saveDB();
      io.emit('stamina_sync', playersData);
    }
  });

  // Mencatat log pergantian pemain ke terminal server
  socket.on('log_substitution', (data) => {
    console.log('📌 SUBSTITUSI TERJADI:', data);
  });

  // --- LOGIKA EVENT KONFIGURASI RULE ENGINE (CRUD) ---

  // Menambahkan aturan (rule) baru
  socket.on('add_rule', (newRule) => {
    console.log('📌 MENAMBAHKAN RULE BARU:', newRule.nama);
    const ruleObj = {
      id: 'R' + Date.now().toString(),
      nama: newRule.nama || 'Custom Rule',
      tipe: newRule.tipe || 'Custom Rule',
      if: newRule.if || '',
      then: newRule.then || '',
      aktif: true,
      triggered: 'Belum terpicu'
    };
    rulesData.push(ruleObj);
    saveDB();
    io.emit('rules_sync', rulesData);
  });

  // Mengubah status aktif/nonaktif aturan
  socket.on('toggle_rule', (data) => {
    const idx = rulesData.findIndex(r => r.id === data.id);
    if (idx !== -1) {
      rulesData[idx].aktif = data.aktif;
      saveDB();
      io.emit('rules_sync', rulesData);
    }
  });

  // Menghapus aturan berdasarkan ID
  socket.on('delete_rule', (id) => {
    rulesData = rulesData.filter(r => r.id !== id);
    saveDB();
    io.emit('rules_sync', rulesData);
  });

  // Simulasi mengevaluasi kondisi aturan dan mengirimkan respon balik (simulation engine)
  socket.on('simulate_rule', (data) => {
    console.log('🧪 SIMULASI RULE MASUK:', data);
    let firedRules = [];
    const p_stamina = parseInt(data.stamina) || 100;
    const p_menit = parseInt(data.menit) || 0;
    const p_status = data.status || '';

    rulesData.forEach(rule => {
      if (!rule.aktif) return;
      let isTriggered = false;
      const cond = rule.if.toUpperCase();
      
      // Aturan Kelompok: Fatigue (Kelelahan)
      if (cond.includes('STAMINA < 40 AND MENIT > 60')) {
        if (p_stamina < 40 && p_menit > 60) isTriggered = true;
      } else if (cond.includes('STAMINA')) {
        if (p_stamina < 50) isTriggered = true;
      }
      
      // Aturan Kelompok: Tactical (Taktis)
      if (cond.includes('MENIT < 30 AND STATUS = MENANG')) {
        if (p_menit < 30 && p_status.toUpperCase() === 'MENANG') isTriggered = true;
      } else if (cond.includes('MENIT > 80 AND STATUS = SERI')) {
        if (p_menit > 80 && p_status.toUpperCase() === 'SERI') isTriggered = true;
      }

      if (isTriggered) {
        firedRules.push(`[${rule.nama}] -> ${rule.then}`);
        rule.triggered = 'Baru saja'; 
      }
    });

    saveDB();
    io.emit('rules_sync', rulesData); 

    if (firedRules.length > 0) {
      socket.emit('simulation_result', { success: true, message: '🔥 TRIGGER TERPENUHI:\n' + firedRules.join('\n') });
    } else {
      socket.emit('simulation_result', { success: false, message: 'Tidak ada rule yang terpenuhi pada kondisi simulasi ini.' });
    }
  });

  // Menerima data statistik latihan/pinggir lapangan dari asisten pelatih dan mengevaluasi rule secara live
  socket.on('assistant_report', (data) => {
    console.log('Laporan Asisten masuk:', data);
    let ruleFired = false;
    let ruleMessage = "";

    // Cek kecocokan kondisi aturan taktis & performa
    if (data.rating < 5 && data.kesalahan > 3) {
      ruleFired = true;
      ruleMessage = `⚠️ KEPUTUSAN RULE ENGINE (PERFORMA BURUK):\n${data.pemain} bermain terburuk (Rating ${data.rating}, ${data.kesalahan}x Blunder). REKOMENDASI: PERTIMBANGKAN PENGGANTIAN POSISI SEGERA!`;
    } else if (data.kartu === 'Merah') {
      ruleFired = true;
      ruleMessage = `🚨 KEPUTUSAN RULE ENGINE (TAKTIS DARURAT):\n${data.pemain} mendapat KARTU MERAH! Segera kurangi intensitas pressing dan ganti formasi bertahan!`;
    } else if (data.kartu === 'Kuning') {
      ruleFired = true;
      ruleMessage = `⚠️ KEPUTUSAN RULE ENGINE (RISIKO PELANGGARAN):\n${data.pemain} mendapat Kartu Kuning. Peringatkan untuk mengurangi pelanggaran keras!`;
    }

    if (ruleFired) {
      // Broadcast peringatan keras ini ke semua tablet/aplikasi Pelatih Kepala
      io.emit('rule_alert', { message: ruleMessage, level: 'CRITICAL', time: new Date().toLocaleTimeString() });
    } else {
      io.emit('rule_alert', { message: `✅ Info Laporan: Data statistik ${data.pemain} baru saja dimasukkan (Rating: ${data.rating}).`, level: 'INFO', time: new Date().toLocaleTimeString() });
    }
  });

  // Memicu mulainya jalannya timer & status pertandingan live
  socket.on('start_match', () => {
    liveData.isLive = true;
    if (liveData.fase === 'Persiapan') {
       liveData.fase = 'Babak 1';
       liveData.menit = 0;
    }
    io.emit('live_match_sync', liveData);
  });

  socket.on('disconnect', () => {
    console.log(`[-] User disconnected: ${socket.id}`);
  });
});

// ==========================================================================
// --- SIMULASI PENGURANGAN STAMINA BERKALA (LIGA 1 INDONESIA TYPE) ---
// Pengurangan stamina otomatis berjalan setiap 10 detik dunia nyata jika status isLive = true.
// ==========================================================================
setInterval(() => {
  if (liveData.isLive && liveData.fase !== 'Penalti') {
    let changed = false;
    playersData = playersData.map(player => {
      // Kurangi stamina pemain yang sedang aktif bermain (Main, Pemanasan, Kartu Kuning)
      if ((player.status === 'Main' || player.status === 'Pemanasan' || player.status === 'Kartu Kuning') && player.stamina > 0) {
        let drain = 0;
        if (player.status === 'Main' || player.status === 'Kartu Kuning') {
            drain = 1; // Kurangi 1% stamina per interval
        } else if (player.status === 'Pemanasan') {
            // Pengurangan lebih lambat untuk pemain pemanasan (~1% per 2.5 interval)
            player.staminaDecimalTracker = (player.staminaDecimalTracker || 0) + 0.4;
            if (player.staminaDecimalTracker >= 1) {
               drain = 1;
               player.staminaDecimalTracker -= 1;
            }
        }
        
        if (drain > 0) {
           player.stamina = Math.max(0, player.stamina - drain);
           changed = true;
        }
      }
      return player;
    });

    if (changed) {
      saveDB(); // Catat pengurangan stamina ke file DB
      io.emit('stamina_sync', playersData); // Sebarkan stamina terupdate ke klien
    }
  }
}, 10000); // Berjalan setiap 10 detik sekali

// ==========================================================================
// --- REST API ENDPOINTS ---
// Untuk keperluan pengecekan status server, login admin, dan ekspor database
// ==========================================================================

// Pengecekan status backend
app.get('/api/status', (req, res) => {
  res.json({ message: "Backend is running!", status: "Real-time Ready", liveData, playersData });
});

// Autentikasi administrator web
app.post('/api/admin/login', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email dan password wajib diisi!' });
  }
  const adminUser = accountsData.find(u => u.email === email && u.password === password && u.email === "admin@stema.com");
  if (!adminUser) {
    return res.status(401).json({ success: false, message: 'Email atau password admin salah!' });
  }
  return res.json({ success: true, message: 'Login berhasil!', user: { nama: adminUser.nama, email: adminUser.email, role: adminUser.role } });
});

// Mengunduh salinan database.json secara penuh
app.get('/api/database/export', (req, res) => {
  try {
    if (fs.existsSync(dbPath)) {
      const raw = fs.readFileSync(dbPath, 'utf8');
      res.setHeader('Content-Disposition', 'attachment; filename=database.json');
      res.setHeader('Content-Type', 'application/json');
      return res.send(raw);
    } else {
      return res.status(404).json({ success: false, message: 'Database file not found' });
    }
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Deteksi alamat IP Lokal PC untuk koneksi Wi-Fi eksternal dari HP
const os = require('os');
const networkInterfaces = os.networkInterfaces();
let localIp = 'localhost';
for (const interfaceName in networkInterfaces) {
  for (const info of networkInterfaces[interfaceName]) {
    if (info.family === 'IPv4' && !info.internal) {
      localIp = info.address;
    }
  }
}

// Menjalankan server pada port yang ditentukan
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server berjalan di PC lokal: http://localhost:${PORT}`);
  console.log(`📱 Untuk sambungan dari HP Realme (Wi-Fi), server tersedia di: http://${localIp}:${PORT}`);
});
