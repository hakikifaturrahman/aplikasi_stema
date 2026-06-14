# DOKUMENTASI TAMBAHAN: API ENDPOINTS & CONTOH DATA

## A. Socket.IO Event Reference Guide

### 1. Authentication Flow

#### Register Event
```javascript
// CLIENT → SERVER
socket.emit('register', {
  nama: "Alvaro Arbeloa",
  email: "arbeloa@realfootball.com",
  password: "SecurePass123",
  role: "Pelatih Kepala"
});

// SERVER → CLIENT Response
socket.on('register_response', (response) => {
  // {
  //   success: true,
  //   message: "Registrasi berhasil! Silakan Login."
  // }
});
```

#### Login Event
```javascript
// CLIENT → SERVER
socket.emit('login', {
  email: "arbeloa@realfootball.com",
  password: "SecurePass123"
});

// SERVER → CLIENT Response
socket.on('login_response', (response) => {
  // {
  //   success: true,
  //   message: "Login berhasil!",
  //   user: {
  //     nama: "Alvaro Arbeloa",
  //     email: "arbeloa@realfootball.com",
  //     role: "Pelatih Kepala"
  //   }
  // }
});
```

#### Change Password Event
```javascript
// CLIENT → SERVER
socket.emit('change_password', {
  email: "arbeloa@realfootball.com",
  oldPassword: "OldPass123",
  newPassword: "NewSecurePass456"
});

// SERVER → CLIENT Response
socket.on('password_response', (response) => {
  // {
  //   success: true,
  //   message: "Password berhasil diubah!"
  // }
});
```

---

### 2. Data Synchronization Events

#### Request Sync (One-way: Client requests, Server responds)
```javascript
// CLIENT → SERVER (request data terbaru)
socket.emit('request_sync');

// SERVER → CLIENT (sends all latest data)
socket.on('live_match_sync', (liveMatchData) => { ... });
socket.on('stamina_sync', (playersDataArray) => { ... });
socket.on('riwayat_sync', (riwayatMatchesArray) => { ... });
socket.on('rules_sync', (rulesDataArray) => { ... });
socket.on('user_sync', (userDataObject) => { ... });
```

#### Live Match Sync (Broadcast: Server sends to all clients)
```javascript
// Emitted oleh server ke ALL connected clients
io.emit('live_match_sync', {
  skor1: 2,           // Skor tim 1
  skor2: 1,           // Skor tim 2
  menit: 45,          // Menit pertandingan (0-120)
  isLive: true,       // Status pertandingan berlangsung
  fase: "Pertandingan",  // Fase: Persiapan/Pertandingan/Istirahat/ExtraTime/Penalti
  menitLebih: 0,      // Menit extra time
  penalti1: 0,        // Gol penalti tim 1
  penalti2: 0         // Gol penalti tim 2
});
```

#### Stamina Sync (Broadcast)
```javascript
// Emitted ke ALL clients
io.emit('stamina_sync', [
  {
    nama: "Kylian Mbappe",
    no: 9,
    pos: "FW",
    stamina: 72,
    status: "Main",
    attributes: {
      speed: 85,
      shooting: 88,
      passing: 75,
      defensive: 30,
      vision: 80,
      stamina: 75,
      dribbling: 90
    },
    tgllahir: "2002-12-20T00:00:00.000",
    posisiAlternatif: "RW",
    tinggi: 178,
    berat: 73,
    tipe: "Offensive",
    foto: "base64_image_string...",
    kartu: "-",
    gol: 1,
    assist: 0,
    goalEvents: [
      {
        menit: 45,
        jenis: "Regular",
        asisten: "Jude Bellingham"
      }
    ]
  },
  // ... more players
]);
```

---

### 3. Match Management Events

#### Update Match (Client sends update)
```javascript
// CLIENT → SERVER (Setiap ada perubahan skor/menit)
socket.emit('update_match', {
  skor1: 2,
  skor2: 1,
  menit: 47,
  fase: "Pertandingan",
  isLive: true,
  menitLebih: 0
});

// SERVER → ALL CLIENTS
io.emit('live_match_sync', { ... });
```

#### Finish Match (End of match)
```javascript
// CLIENT → SERVER
socket.emit('finish_match', {
  possession: "58",
  passes: "587",
  shots: "12",
  shotsOnTarget: "7",
  timKandang: "Real Madrid",
  timTandang: "Manchester City"
});

// SERVER:
// 1. Generate laporan riwayat match
// 2. Calculate final hasil (W/D/L)
// 3. Generate statistik pemain
// 4. Save laporan ke riwayatMatches
// 5. Broadcast ke ALL clients:
io.emit('riwayat_sync', updatedRiwayatMatches);
```

#### Update User Profile
```javascript
// CLIENT → SERVER
socket.emit('update_user', {
  nama: "Alvaro Arbeloa",
  email: "arbeloa@realfootball.com",
  role: "Pelatih Kepala",
  foto: "base64_image_string...",
  telp: "+62 812 3456 7890"
});

// SERVER → ALL CLIENTS
io.emit('user_sync', updatedUserData);
```

---

## B. Contoh Database.json Lengkap

```json
{
  "playersData": [
    {
      "nama": "Thibaut Courtois",
      "no": 1,
      "pos": "GK",
      "stamina": 89,
      "status": "Main",
      "attributes": {
        "speed": 80,
        "shooting": 97,
        "passing": 97,
        "defensive": 100,
        "vision": 95,
        "stamina": 100,
        "dribbling": 100
      },
      "tgllahir": "1992-05-11T00:00:00.000",
      "posisiAlternatif": "None",
      "tinggi": 200,
      "berat": 96,
      "tipe": "Defensive",
      "foto": "base64_encoded_image_string_goalkeeper...",
      "kartu": "-",
      "gol": 0,
      "assist": 0,
      "goalEvents": []
    },
    {
      "nama": "Dani Carvajal",
      "no": 2,
      "pos": "RB",
      "stamina": 100,
      "status": "Cadangan",
      "attributes": {
        "speed": 80,
        "shooting": 80,
        "passing": 80,
        "defensive": 80,
        "vision": 80,
        "stamina": 100,
        "dribbling": 80
      },
      "tgllahir": "1992-01-10T00:00:00.000",
      "posisiAlternatif": "None",
      "tinggi": 173,
      "berat": 73,
      "tipe": "Balanced",
      "foto": "base64_encoded_image_string_rb...",
      "kartu": "-",
      "gol": 0,
      "assist": 0,
      "goalEvents": []
    },
    {
      "nama": "Kylian Mbappe",
      "no": 9,
      "pos": "FW",
      "stamina": 72,
      "status": "Main",
      "attributes": {
        "speed": 85,
        "shooting": 88,
        "passing": 75,
        "defensive": 30,
        "vision": 80,
        "stamina": 75,
        "dribbling": 90
      },
      "tgllahir": "2002-12-20T00:00:00.000",
      "posisiAlternatif": "RW",
      "tinggi": 178,
      "berat": 73,
      "tipe": "Offensive",
      "foto": "base64_encoded_image_string_fw...",
      "kartu": "-",
      "gol": 1,
      "assist": 0,
      "goalEvents": [
        {
          "menit": 45,
          "jenis": "Regular",
          "asisten": "Jude Bellingham"
        }
      ]
    }
  ],
  
  "accountsData": [
    {
      "nama": "Alvaro Arbeloa",
      "email": "arbeloa@realfootball.com",
      "password": "hashed_password_bcrypt_format",
      "role": "Pelatih Kepala",
      "foto": "base64_profile_image..."
    },
    {
      "nama": "Iker Casillas",
      "email": "casillas@realfootball.com",
      "password": "hashed_password_bcrypt_format",
      "role": "Asisten Pelatih",
      "foto": "base64_profile_image..."
    }
  ],
  
  "riwayatMatches": [
    {
      "tanggal": "15 Dec 2024, 20:30",
      "timKandang": "Real Madrid",
      "lawan": "Manchester City",
      "skor": "2 - 1",
      "hasil": "W",
      "totalSubstitusi": 3,
      "statistikTim": [
        {
          "label": "Ball Possession",
          "nilai": "58%"
        },
        {
          "label": "Total Shots",
          "nilai": "12"
        },
        {
          "label": "Shots on Target",
          "nilai": "7"
        },
        {
          "label": "Passes",
          "nilai": "587"
        },
        {
          "label": "Kartu Kuning",
          "nilai": "2"
        },
        {
          "label": "Kartu Merah",
          "nilai": "0"
        }
      ],
      "rekomendasi": [
        "✅ Pertandingan Selesai: Real Madrid mengalahkan Manchester City 2-1",
        "⚠️ Penggantian taktis: 3 pemain diganti untuk manajemen stamina",
        "📊 Kepemilikan bola: 58% menunjukkan kontrol permainan yang baik",
        "💡 Performa: Tim mempertahankan level tinggi meskipun stamina berkurang di akhir"
      ],
      "performaPemain": [
        {
          "nama": "Kylian Mbappe",
          "pos": "FW",
          "rating": 8.5,
          "sprint": 32,
          "assist": 1,
          "gol": 1,
          "goalEvents": [
            {
              "menit": 45,
              "jenis": "Regular",
              "asisten": "Jude Bellingham"
            }
          ],
          "kartu": "-"
        },
        {
          "nama": "Jude Bellingham",
          "pos": "MF",
          "rating": 7.8,
          "sprint": 28,
          "assist": 1,
          "gol": 0,
          "goalEvents": [],
          "kartu": "-"
        },
        {
          "nama": "Vinicius Junior",
          "pos": "FW",
          "rating": 7.2,
          "sprint": 35,
          "assist": 0,
          "gol": 1,
          "goalEvents": [
            {
              "menit": 72,
              "jenis": "Regular",
              "asisten": "Fede Valverde"
            }
          ],
          "kartu": "Kuning"
        }
      ]
    }
  ],
  
  "rulesData": [
    {
      "id": "R1",
      "nama": "Rekomendasi Substitusi",
      "tipe": "Fatigue Rule",
      "if": "Stamina < 40 AND Menit > 60",
      "then": "Rekomendasi Substitusi",
      "aktif": true,
      "triggered": "Sudah terpicu 5 kali"
    },
    {
      "id": "R2",
      "nama": "Intensive Pressing",
      "tipe": "Tactical Rule",
      "if": "Menit < 30 AND Status = Menang",
      "then": "Pertahankan Tekanan",
      "aktif": false,
      "triggered": "Belum terpicu"
    },
    {
      "id": "R3",
      "nama": "Performance Alert",
      "tipe": "Performance Rule",
      "if": "Rating < 5 AND Kesalahan > 3",
      "then": "Pertimbangkan penggantian posisi",
      "aktif": true,
      "triggered": "Sudah terpicu 2 kali"
    },
    {
      "id": "R4",
      "nama": "Injury Prevention",
      "tipe": "Injury Rule",
      "if": "Stamina < 20 AND Intensitas = High",
      "then": "Hentikan pemain dari pertandingan",
      "aktif": true,
      "triggered": "Belum terpicu"
    }
  ],
  
  "userData": {
    "nama": "Alvaro Arbeloa",
    "email": "arbeloa@realfootball.com",
    "telp": "+62 812 3456 7890",
    "role": "Pelatih Kepala",
    "foto": "base64_profile_image_coach..."
  }
}
```

---

## C. Screen Navigation Map

```
┌──────────────────────────────────────────────────────────┐
│                     NAVIGATION STRUCTURE                 │
└──────────────────────────────────────────────────────────┘

PRE-LOGIN STACK:
├─ SplashScreen (Auto-detect session)
├─ LoginScreen ─┬─→ RegisterScreen
│              └─→ PrivacyPolicyScreen
│              └─→ TermsConditionsScreen
└─ ForgotPasswordScreen

POST-LOGIN STACK (Bottom Navigation):
├─ Dashboard (Tab 1)
│  ├─→ PertandinganScreen
│  ├─→ MonitoringStaminaScreen
│  ├─→ LaporanScreen
│  └─→ PengaturanScreen
│
├─ DataPemain (Tab 2)
│  ├─→ SquadManagementScreen
│  ├─→ TambahPemainScreen
│  ├─→ TambahStatistikScreen
│  └─→ DataPemainDetailScreen
│
├─ Analisis (Tab 3)
│  ├─→ RuleEngineScreen
│  ├─→ StatistikPerformaScreen
│  ├─→ RiwayatMatchScreen
│  └─→ RiwayatDetailScreen
│
└─ Settings (Tab 4)
   ├─→ ProfilUserScreen
   ├─→ ChangePasswordScreen
   ├─→ ExportDataScreen
   └─→ LogoutButton
```

---

## D. HTTP Status Codes & Error Handling

### Error Response Format (via Socket.IO):
```javascript
{
  success: false,
  message: "Error description message",
  code: "ERROR_CODE",
  timestamp: "2024-12-15T20:30:45Z"
}
```

### Common Error Codes:
- `AUTH_FAILED`: Authentication/Login failed
- `AUTH_MISSING`: User not authenticated
- `VALIDATION_ERROR`: Input validation failed
- `PLAYER_NOT_FOUND`: Player data tidak ditemukan
- `DUPLICATE_EMAIL`: Email sudah terdaftar
- `INVALID_PASSWORD`: Password salah atau tidak memenuhi requirement
- `SERVER_ERROR`: Error internal server
- `DATABASE_ERROR`: Error saat akses/simpan database

---

## E. Database Maintenance & Optimization

### Index Optimization (untuk future SQL migration):
```sql
CREATE INDEX idx_player_nama ON playersData(nama);
CREATE INDEX idx_account_email ON accountsData(email);
CREATE INDEX idx_match_tanggal ON riwayatMatches(tanggal DESC);
CREATE INDEX idx_player_pos ON playersData(pos);
```

### Data Archival Strategy:
```
Setiap bulan:
├─ Archive matches yang berusia > 3 bulan ke: riwayatMatches_archive_[YYYY-MM].json
├─ Compress file archive dengan gzip
├─ Delete dari active database
└─ Maintain index untuk quick search di archive

Setiap tahun:
├─ Backup full archive ke external storage
├─ Retention policy: 2 years of active data + 5 years in archive
└─ Old archives (>5 tahun) dapat didelete atau di-migrate ke cold storage
```

---

## F. Testing Scenarios

### Unit Test Cases:

**Authentication Tests:**
```javascript
✓ Test 1: Registrasi dengan email valid
✓ Test 2: Registrasi dengan email duplicate (should fail)
✓ Test 3: Login dengan credential valid
✓ Test 4: Login dengan password salah (should fail)
✓ Test 5: Change password dengan old password benar
✓ Test 6: Change password dengan old password salah (should fail)
```

**Data Synchronization Tests:**
```javascript
✓ Test 7: Request sync saat initial connect
✓ Test 8: Live match update broadcast ke semua clients
✓ Test 9: Player stamina update real-time
✓ Test 10: Database persist setelah server restart
✓ Test 11: Multiple clients menerima sinkronisasi simultaneously
✓ Test 12: Offline client reconnect dan mendapat latest data
```

**Rule Engine Tests:**
```javascript
✓ Test 13: Substitution rule trigger saat stamina < 40 AND menit > 60
✓ Test 14: Performance rule trigger saat rating < 5 AND errors > 3
✓ Test 15: Tactical rule activate/deactivate sesuai kondisi
✓ Test 16: Rule history logging
```

---

## G. Performance Metrics & Benchmarks

### Target Performance:
- Connection time: < 500ms
- Data sync latency: < 100ms (untuk update pemain)
- Database query time: < 50ms
- UI render time: < 60ms (60 FPS target)
- Memory usage: < 100MB (mobile app)
- Server uptime: 99.5% availability

### Monitoring Points:
```
Real-time Monitoring:
├─ Server CPU usage
├─ Memory consumption
├─ Active Socket.IO connections
├─ Request/response times
├─ Error rate & types
├─ Database file size growth
└─ Network bandwidth usage
```

---

**Dokumentasi API & Database - SELESAI**

*File ini melengkapi BAB_3_PERANCANGAN_FISIK.md dengan referensi API detail, contoh data, dan panduan testing.*
