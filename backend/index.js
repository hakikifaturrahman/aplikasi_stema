const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const dbPath = path.join(__dirname, 'database.json');

// --- SISTEM DATABASE LOKAL PERMANEN (JSON FILE) ---
// Alternatif handal & bebas error dari SQLite tanpa instalasi tambahan
function loadDB() {
  try {
    if (fs.existsSync(dbPath)) {
      console.log('📦 Database ditemukan! Memuat data asli...');
      const raw = fs.readFileSync(dbPath, 'utf8');
      return JSON.parse(raw);
    }
  } catch (err) {
    console.error('Error saat Load DB:', err);
  }
  
  console.log('📦 Membuat Database Baru (Initial Data)...');
  return {
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
    riwayatMatches: [],
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
      nama: 'Alvaro Arbeloa',
      email: 'arbeloa@realfootball.com',
      telp: '+62 812 3456 7890',
      role: 'Pelatih'
    }
  };
}

function saveDB() {
  try {
    fs.writeFileSync(dbPath, JSON.stringify({ playersData, riwayatMatches, rulesData, userData }, null, 2));
  } catch (err) {
    console.error('Error gagal menyimpan DB:', err);
  }
}
// ----------------------------------------------------

const app = express();
const server = http.createServer(app);

// Setup middleware
app.use(cors());
app.use(express.json());

// Setup Socket.IO for Real-Time Communication
const io = new Server(server, {
  cors: {
    origin: "*", // Mengizinkan akses dari aplikasi Flutter
    methods: ["GET", "POST"]
  }
});

// Menyimpan state dari pertandingan 
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

// Memuat Data Permanen dari Database
let initialDB = loadDB();
let playersData = initialDB.playersData;
let riwayatMatches = initialDB.riwayatMatches;

// Init base attributes if missing
playersData = playersData.map(p => {
  if (!p.attributes) {
     if (p.pos === 'FW') p.attributes = { speed: 85, shooting: 88, passing: 75, defensive: 30, vision: 80, stamina: 75, dribbling: 90 };
     else if (p.pos === 'MF') p.attributes = { speed: 75, shooting: 78, passing: 90, defensive: 65, vision: 88, stamina: 85, dribbling: 85 };
     else if (p.pos === 'DF') p.attributes = { speed: 70, shooting: 50, passing: 75, defensive: 90, vision: 65, stamina: 80, dribbling: 60 };
     else p.attributes = { speed: 60, shooting: 30, passing: 65, defensive: 60, vision: 60, stamina: 70, dribbling: 50 };
  }
  return p;
});

// Fallback array jika db.json lama tidak memiliki rulesData:
let rulesData = initialDB.rulesData || [
  { id: 'R1', nama: 'Rekomendasi Substitusi', tipe: 'Fatigue', if: 'Stamina < 40 AND Menit > 60', then: 'Ganti', aktif: true, triggered: '-' }
];

let userData = initialDB.userData || {
  nama: 'Alvaro Arbeloa',
  email: 'arbeloa@realfootball.com',
  telp: '+62 812 3456 7890',
  role: 'Pelatih'
};

saveDB(); // save back so DB gets updated with attributes & new keys

io.on('connection', (socket) => {
  console.log(`[+] User connected: ${socket.id}`);

  // 1. KETIKA ADA USER BARU: Berikan Skor & Stamina Yang Paling Baru dari Server
  socket.emit('live_match_sync', liveData);
  socket.emit('stamina_sync', playersData);
  socket.emit('riwayat_sync', riwayatMatches);
  socket.emit('rules_sync', rulesData);
  socket.emit('user_sync', userData);

  // 2. MENDENGAR DARI FLUTTER: Jika ada gol 
  socket.on('update_match', (data) => {
    liveData = { ...liveData, ...data };
    io.emit('live_match_sync', liveData); 
  });

  // 3. MENDENGAR DARI FLUTTER: Jika sebuah layar baru dibuka dan meminta data paling segar saat itu juga
  socket.on('request_sync', () => {
    socket.emit('live_match_sync', liveData);
    socket.emit('stamina_sync', playersData);
    socket.emit('riwayat_sync', riwayatMatches);
    socket.emit('rules_sync', rulesData);
    socket.emit('user_sync', userData);
  });

  // 3b. MENDENGAR DARI FLUTTER: Update Profil
  socket.on('update_user', (data) => {
    userData = { ...userData, ...data };
    saveDB();
    io.emit('user_sync', userData);
  });

  // 4. MENDENGAR DARI FLUTTER: Match Selesai / Peluit Panjang
  socket.on('finish_match', (data = {}) => {
    console.log('📌 MATCH SELESAI! MENYIMPAN RIWAYAT...', data);
    
    // Prediksi Menang/Kalah/Seri
    let finalHasil = liveData.skor1 > liveData.skor2 ? 'W' : (liveData.skor1 === liveData.skor2 ? 'D' : 'L');
    let finalSkorStr = `${liveData.skor1} - ${liveData.skor2}`;
    
    // Jika Extra Time selesai dan adu penalti terlibat
    if (liveData.penalti1 > 0 || liveData.penalti2 > 0 || liveData.fase === 'Penalti') {
       finalSkorStr += ` (${liveData.penalti1} - ${liveData.penalti2} PEN)`;
       finalHasil = liveData.penalti1 > liveData.penalti2 ? 'W' : (liveData.penalti1 === liveData.penalti2 ? 'D' : 'L');
    }

    const totalYellow = playersData.filter(p => p.kartu === 'Kuning').length;
    const totalRed = playersData.filter(p => p.kartu === 'Merah').length;
    
    // Format menjadi Laporan Riwayat (Sesuai struktur RiwayatMatchScreen Flutter)
    // Memasukkan nama tim secara dinamis dari frontend (bisa beda tiap match!)
    
    const possessionStr = data.possession && data.possession.trim() !== '' ? `${data.possession}%` : `${Math.floor(Math.random() * 30 + 35)}%`;
    const passesStr = data.passes && data.passes.trim() !== '' ? data.passes : `${Math.floor(Math.random() * 300 + 200)}`;
    const totalShots = data.shots != null && data.shots > 0 ? data.shots.toString() : Math.floor(Math.random() * 15 + 5).toString();
    const totalShotsTarget = data.shotsOnTarget != null && data.shotsOnTarget > 0 ? data.shotsOnTarget.toString() : Math.floor(Math.random() * 8 + 2).toString();

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
        rating: parseFloat((Math.random() * 3 + 6.0).toFixed(1)), // Acak dari 6.0 ke 9.0
        sprint: Math.floor(Math.random() * 40 + 5),
        assist: p.assist || 0,
        gol: p.gol || 0,
        goalEvents: p.goalEvents || [],
        kartu: p.kartu || '-'
      }))
    };

    // Taruh laporan paling atas
    riwayatMatches.unshift(reportData);
    
    // Sebar luaskan riwayat terbaru ke seluruh aplikasi yang sedang buka Menu Riwayat
    io.emit('riwayat_sync', riwayatMatches);

    // KEMUDIAN LAKUKAN GLOBAL RESET: Atur ulang skor dan bersihkan stamina ke 100% untuk match berikutnya
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
      if (p.status === 'Main' || p.status === 'Pemanasan' || p.status === 'Kartu Kuning') p.stamina = Math.floor(Math.random() * 15 + 85); // Acak 85-100%
      if (p.status === 'Cadangan' || p.status === 'Kartu Merah') p.stamina = 100;
      if (p.status === 'Kartu Merah') p.status = 'Cadangan'; // kembalikan merah jadi cadangan untuk next match
      if (p.status === 'Kartu Kuning') p.status = 'Main'; // kembalikan kuning jadi main untuk next match
      p.kartu = '-'; // Bersihkan riwayat kartu
      p.gol = 0; // Bersihkan gol
      p.goalEvents = []; // Bersihkan riwayat menit gol
      p.assist = 0;
      return p;
    });

    saveDB(); // Simpan riwayat & stamina terbaru murni ke Storage Abadi!
    
    io.emit('live_match_sync', liveData);
    io.emit('stamina_sync', playersData);
    console.log('📌 GLOBAL RESET SELESAI & DB DISIMPAN');
  });

  // 4b. MENDENGAR DARI FLUTTER: Menyimpan Pertandingan Manual (Offline/History Entry)
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
      // Gunakan starting XI yang dilempar, atau kosongi
      performaPemain: (data.startingXI || []).map(namaPemain => {
         // Coba cari data asli pemain untuk POS
         const found = playersData.find(p => p.nama === namaPemain);
         return {
           nama: namaPemain,
           pos: found ? found.pos : 'N/A',
           rating: parseFloat((Math.random() * 2 + 6.5).toFixed(1)), // Mock rating
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

  // 5. MANAJEMEN ROSTER GLOBAL
  socket.on('add_player', (newPlayer) => {
    console.log('📌 MENAMBAHKAN PEMAIN BARU:', newPlayer.nama);
    
    // Auto generate stats based on pos if not provided from Flutter
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

    // Tambahkan ke database lokal server
    playersData.push({
      nama: newPlayer.nama,
      no: newPlayer.no,
      pos: newPlayer.pos,
      stamina: initialStamina,
      status: newPlayer.status || 'Main',
      attributes: attr,
    });
    saveDB(); // Simpan Data Roster langsung ke Storage Permanen!
    
    // Siarkan roster baru
    io.emit('stamina_sync', playersData);
  });

  socket.on('delete_player', (playerName) => {
    console.log('📌 MENGHAPUS PEMAIN:', playerName);
    playersData = playersData.filter(p => p.nama !== playerName);
    saveDB();
    io.emit('stamina_sync', playersData);
  });

  socket.on('edit_player', (updatedPlayer) => {
    console.log('📌 MENGEDIT PEMAIN:', updatedPlayer.originalName);
    const idx = playersData.findIndex(p => p.nama === updatedPlayer.originalName);
    if (idx !== -1) {
      const oldStatus = playersData[idx].status;
      
      // Update data kartu jika status yang dipilih adalah kartu
      if (updatedPlayer.status === 'Kartu Kuning') {
         updatedPlayer.kartu = 'Kuning';
         updatedPlayer.status = 'Main';
      } else if (updatedPlayer.status === 'Kartu Merah') {
         updatedPlayer.kartu = 'Merah';
      } else {
         // Jika status diubah ke yang lain, kartu otomatis dihapus
         updatedPlayer.kartu = '-';
      }
      
      // Cek apakah terjadi perubahan jumlah gol untuk update skor otomatis
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
      
      // Auto Stamina based on status changes (Main/Cadangan -> 100, Cedera/Kartu Merah -> 0)
      if (oldStatus !== playersData[idx].status) {
         if (playersData[idx].status === 'Main' || playersData[idx].status === 'Kartu Kuning') {
            // Jika dari Pemanasan ke Main, JANGAN reset stamina. Biarkan mengikuti stamina terakhir saat pemanasan.
            if (oldStatus !== 'Pemanasan') {
               playersData[idx].stamina = 100;
            }
         } else if (playersData[idx].status === 'Cadangan') {
            playersData[idx].stamina = 100;
         } else if (playersData[idx].status.startsWith('Cedera') || playersData[idx].status === 'Kartu Merah') {
            playersData[idx].stamina = 0;
         }
         // Jika status berubah menjadi Pemanasan, biarkan stamina sesuai yang didapat (biasanya 100 dari Cadangan)
      }

      delete playersData[idx].originalName;
      saveDB();
      io.emit('stamina_sync', playersData);
    }
  });

  socket.on('log_substitution', (data) => {
    console.log('📌 SUBSTITUSI TERJADI:', data);
    // Kita bisa menyisipkan log ini ke dalam liveData atau sebuah log array tersendiri
    // untuk kemudian dimasukkan ke laporan riwayat.
    // Sementara kita hanya console.log agar tercatat di log server.
  });

  // 6. MANAJEMEN RULE ENGINE (CRUD)
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

  socket.on('toggle_rule', (data) => {
    const idx = rulesData.findIndex(r => r.id === data.id);
    if (idx !== -1) {
      rulesData[idx].aktif = data.aktif;
      saveDB();
      io.emit('rules_sync', rulesData);
    }
  });

  socket.on('delete_rule', (id) => {
    rulesData = rulesData.filter(r => r.id !== id);
    saveDB();
    io.emit('rules_sync', rulesData);
  });

  // Simulasi Rule Evaluator (Dipanggil dari frontend untuk tes manual)
  socket.on('simulate_rule', (data) => {
    console.log('🧪 SIMULASI RULE MASUK:', data);
    let firedRules = [];
    const p_stamina = parseInt(data.stamina) || 100;
    const p_menit = parseInt(data.menit) || 0;
    const p_status = data.status || ''; // 'Menang', 'Seri', 'Kalah'

    rulesData.forEach(rule => {
      if (!rule.aktif) return;
      // Parsing sederhana IF condition (Mendukung kondisi dari template)
      let isTriggered = false;
      const cond = rule.if.toUpperCase();
      
      // FATIGUE
      if (cond.includes('STAMINA < 40 AND MENIT > 60')) {
        if (p_stamina < 40 && p_menit > 60) isTriggered = true;
      } else if (cond.includes('STAMINA')) {
        // Fallback untuk rule buatan
        if (p_stamina < 50) isTriggered = true;
      }
      
      // TACTICAL
      if (cond.includes('MENIT < 30 AND STATUS = MENANG')) {
        if (p_menit < 30 && p_status.toUpperCase() === 'MENANG') isTriggered = true;
      } else if (cond.includes('MENIT > 80 AND STATUS = SERI')) {
        if (p_menit > 80 && p_status.toUpperCase() === 'SERI') isTriggered = true;
      }

      if (isTriggered) {
        firedRules.push(`[${rule.nama}] -> ${rule.then}`);
        rule.triggered = 'Baru saja'; // Update UI
      }
    });

    saveDB();
    io.emit('rules_sync', rulesData); // Update triggered status ke semua

    if (firedRules.length > 0) {
      socket.emit('simulation_result', { success: true, message: '🔥 TRIGGER TERPENUHI:\n' + firedRules.join('\n') });
    } else {
      socket.emit('simulation_result', { success: false, message: 'Tidak ada rule yang terpenuhi pada kondisi simulasi ini.' });
    }
  });

  // 7. MENDENGAR DARI ASISTEN PELATIH: Laporan Statistik Pinggir Lapangan
  socket.on('assistant_report', (data) => {
    console.log('Laporan Asisten masuk:', data);
    let ruleFired = false;
    let ruleMessage = "";

    // RULE ENGINE SEDERHANA DI SERVER SECARA LIVE
    // Meniru rule "Performance Alert" dari rule_engine_screen.dart
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
      // Broadcast peringatan keras ini ke semua tablet/aplikasi Pelatih Kepala!
      io.emit('rule_alert', { message: ruleMessage, level: 'CRITICAL', time: new Date().toLocaleTimeString() });
    } else {
      io.emit('rule_alert', { message: `✅ Info Laporan: Data statistik ${data.pemain} baru saja dimasukkan (Rating: ${data.rating}).`, level: 'INFO', time: new Date().toLocaleTimeString() });
    }
  });

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

// 3. LOGIKA SIMULASI DI SERVER (STAMINA LIGA 1 BRI)
// Di aplikasi Anda, 1 menit pertandingan = 5 detik dunia nyata (dari timer dashboard).
// Pemain Liga 1 BRI rata-rata staminanya drop lebih drastis mulai menit 60-70.
// Kita kurangi 1-2% setiap 10 detik dunia nyata (setara setiap 2 menit pertandingan).
setInterval(() => {
  if (liveData.isLive && liveData.fase !== 'Penalti') {
    let changed = false;
    playersData = playersData.map(player => {
      // Hanya kurangi stamina yang Main atau Pemanasan dan belum terkuras habis
      if ((player.status === 'Main' || player.status === 'Pemanasan' || player.status === 'Kartu Kuning') && player.stamina > 0) {
        // Drain: Berkurang secara acak antara 1% sampai 2% untuk Main
        // Drain logic: Di sini interval=10s didunia nyata (2 menit game).
        // Main: turun 1% per 2 menit game -> 1% per interval ini.
        // Pemanasan: turun 1% per 5 menit game. 2 menit/5 menit = 0.4 per interval.
        let drain = 0;
        if (player.status === 'Main' || player.status === 'Kartu Kuning') {
            drain = 1;
        } else if (player.status === 'Pemanasan') {
            // Gunakan properti sementara staminaDecimalTracker untuk akumulasi pengurangan 0.4
            player.staminaDecimalTracker = (player.staminaDecimalTracker || 0) + 0.4;
            if (player.staminaDecimalTracker >= 1) {
               drain = 1;
               player.staminaDecimalTracker -= 1;
               // Ini menghasilkan ~1 poin per 2.5 interval (25 detik dunia nyata / 5 menit game)
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
      saveDB(); // Catat pengurangan stamina ke DB
      // Sebarkan stamina terbaru ke setiap device
      io.emit('stamina_sync', playersData);
    }
  }
}, 10000); // Interval diperlambat menjadi 10 detik sekali

// Basic API route untuk mengecek apakah server jalan
app.get('/api/status', (req, res) => {
  res.json({ message: "Backend is running!", status: "Real-time Ready", liveData, playersData });
});

const os = require('os');
const networkInterfaces = os.networkInterfaces();
let localIp = 'localhost';
for (const interfaceName in networkInterfaces) {
  for (const info of networkInterfaces[interfaceName]) {
    if (info.family === 'IPv4' && !info.internal) {
      localIp = info.address;
      // You can break early if you want, but this gets the last non-internal IPv4
    }
  }
}

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server berjalan di PC lokal: http://localhost:${PORT}`);
  console.log(`📱 Untuk sambungan dari HP Realme (Wi-Fi), server tersedia di: http://${localIp}:${PORT}`);
});
