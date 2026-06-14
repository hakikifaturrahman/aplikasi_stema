// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Overview Dashboard Admin
// File: admin_web/src/app/dashboard/page.tsx
// Deskripsi: Halaman utama panel admin web. Menampilkan ringkasan statistik,
//            status sinkronisasi server backend, live scoreboard pertandingan,
//            dan status stamina kritis dari para pemain secara real-time.
// ==========================================================================

"use client";

import { useEffect, useState } from "react";
import { io, Socket } from "socket.io-client";
import { BACKEND_URL } from "@/config";
import { 
  Users, 
  Activity, 
  Trophy, 
  ShieldAlert,
  Server,
  RefreshCw,
  Power
} from "lucide-react";

// Struktur data pemain dari backend
interface PlayerData {
  nama: string;
  pos: string;
  stamina: number;
  status: string;
}

// Struktur data status pertandingan live
interface LiveData {
  isLive: boolean;
  menit: number;
  fase: string;
  skor1: number;
  skor2: number;
}

// Struktur data aturan rule engine
interface RuleData {
  aktif: boolean;
}

export default function DashboardOverview() {
  // State manajemen data dan socket connection
  const [socket, setSocket] = useState<Socket | null>(null);
  const [connected, setConnected] = useState(false);
  const [players, setPlayers] = useState<PlayerData[]>([]);
  const [liveData, setLiveData] = useState<LiveData | null>(null);
  const [rules, setRules] = useState<RuleData[]>([]);

  // Setup koneksi real-time ke Socket.IO server backend
  useEffect(() => {
    // Menghubungkan ke alamat backend Node.js
    const newSocket = io(BACKEND_URL);

    // Ketika sukses tersambung, minta data sync awal
    newSocket.on("connect", () => {
      setConnected(true);
      newSocket.emit("request_sync");
    });

    newSocket.on("disconnect", () => {
      setConnected(false);
    });

    // Menerima update data pemain real-time
    newSocket.on("stamina_sync", (data) => {
      setPlayers(data);
    });

    // Menerima update status live match
    newSocket.on("live_match_sync", (data) => {
      setLiveData(data);
    });

    // Menerima update rules engine
    newSocket.on("rules_sync", (data) => {
      setRules(data);
    });

    // Simpan instance socket secara asinkron untuk menghindari warning render cascading React
    setTimeout(() => {
      setSocket(newSocket);
    }, 0);

    // Putuskan koneksi saat widget/page ditutup
    return () => {
      newSocket.disconnect();
    };
  }, []);

  // Mengirim sinyal manual refresh request data ke server
  const triggerSync = () => {
    if (socket && connected) {
      socket.emit("request_sync");
    }
  };

  // Kalkulasi statistik dari data pemain & aturan
  const activePlayersCount = players.filter(p => p.status === "Main" || p.status === "Pemanasan").length;
  const avgStamina = players.length > 0 
    ? Math.round(players.reduce((acc, p) => acc + p.stamina, 0) / players.length) 
    : 0;
  const activeRules = rules.filter(r => r.aktif).length;

  return (
    <div className="space-y-8">
      {/* Banner Selamat Datang & Status Koneksi Server */}
      <div className="bg-card border border-border rounded-2xl p-6 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-accent/5 rounded-full -translate-y-1/2 translate-x-1/3 blur-3xl pointer-events-none"></div>
        <h2 className="text-2xl font-bold text-foreground relative z-10">Selamat Datang, Admin</h2>
        <p className="text-text-secondary mt-1 relative z-10">Pantau dan kelola keseluruhan sistem STEMA dari dashboard ini.</p>
        
        <div className="mt-6 flex flex-wrap gap-4 relative z-10">
          {/* Indikator status backend */}
          <div className="flex items-center gap-2 bg-background/50 border border-border px-4 py-2 rounded-xl">
            <Server className={`w-4 h-4 ${connected ? "text-green-500" : "text-red-500"}`} />
            <span className="text-sm font-medium text-foreground">
              Backend: {connected ? "Terhubung" : "Terputus"}
            </span>
          </div>
          {/* Tombol manual sync */}
          <button 
            onClick={triggerSync}
            className="flex items-center gap-2 bg-card-alt hover:bg-border transition-colors border border-border px-4 py-2 rounded-xl text-sm font-medium text-foreground"
          >
            <RefreshCw className={`w-4 h-4 ${!connected ? "opacity-50" : ""}`} />
            Sync Data
          </button>
        </div>
      </div>

      {/* Grid Kartu Statistik Ringkas */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Stat 1: Jumlah Skuad */}
        <div className="bg-card border border-border rounded-2xl p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-text-secondary text-sm font-medium">Total Skuad</p>
              <h3 className="text-3xl font-bold text-foreground mt-2">{players.length}</h3>
            </div>
            <div className="w-12 h-12 bg-accent/10 border border-accent/20 rounded-xl flex items-center justify-center">
              <Users className="w-6 h-6 text-accent" />
            </div>
          </div>
          <div className="mt-4 flex items-center gap-2 text-sm">
            <span className="text-green-400 font-medium">{activePlayersCount} Aktif</span>
            <span className="text-text-secondary">saat ini</span>
          </div>
        </div>

        {/* Stat 2: Rata-rata Stamina */}
        <div className="bg-card border border-border rounded-2xl p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-text-secondary text-sm font-medium">Rata-rata Stamina</p>
              <h3 className="text-3xl font-bold text-foreground mt-2">{avgStamina}%</h3>
            </div>
            <div className="w-12 h-12 bg-green-500/10 border border-green-500/20 rounded-xl flex items-center justify-center">
              <Activity className="w-6 h-6 text-green-500" />
            </div>
          </div>
          {/* Progress bar visual stamina */}
          <div className="mt-4 w-full bg-background rounded-full h-2 overflow-hidden border border-border">
            <div 
              className={`h-full ${avgStamina > 60 ? 'bg-green-500' : avgStamina > 30 ? 'bg-accent' : 'bg-red-500'}`} 
              style={{ width: `${avgStamina}%` }}
            ></div>
          </div>
        </div>

        {/* Stat 3: Status Jalannya Pertandingan */}
        <div className="bg-card border border-border rounded-2xl p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-text-secondary text-sm font-medium">Status Match</p>
              <h3 className="text-xl font-bold text-foreground mt-2">
                {liveData?.isLive ? "Berlangsung" : "Off"}
              </h3>
            </div>
            <div className={`w-12 h-12 rounded-xl flex items-center justify-center border ${liveData?.isLive ? 'bg-red-500/10 border-red-500/20' : 'bg-background border-border'}`}>
              <Power className={`w-6 h-6 ${liveData?.isLive ? 'text-red-500' : 'text-text-secondary'}`} />
            </div>
          </div>
          <div className="mt-4 flex items-center gap-2 text-sm">
            <span className="text-foreground font-medium">Menit {liveData?.menit || 0}</span>
            <span className="text-text-secondary">• Fase {liveData?.fase || '-'}</span>
          </div>
        </div>

        {/* Stat 4: Jumlah Aturan Rule Engine Aktif */}
        <div className="bg-card border border-border rounded-2xl p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-text-secondary text-sm font-medium">Rule Engine Aktif</p>
              <h3 className="text-3xl font-bold text-foreground mt-2">{activeRules}</h3>
            </div>
            <div className="w-12 h-12 bg-blue-500/10 border border-blue-500/20 rounded-xl flex items-center justify-center">
              <ShieldAlert className="w-6 h-6 text-blue-500" />
            </div>
          </div>
          <div className="mt-4 flex items-center gap-2 text-sm">
            <span className="text-text-secondary">Dari total {rules.length} aturan</span>
          </div>
        </div>
      </div>

      {/* Grid Rincian Live Scoreboard & Warning Stamina Kritis */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Kolom 1: Live Scoreboard Mini View */}
        <div className="bg-card border border-border rounded-2xl p-6">
          <h3 className="text-lg font-bold text-foreground mb-6 flex items-center gap-2">
            <Trophy className="w-5 h-5 text-accent" />
            Live Scoreboard
          </h3>
          
          <div className="bg-background border border-border rounded-xl p-8 flex items-center justify-between">
            <div className="text-center">
              <div className="w-16 h-16 bg-card-alt border border-border rounded-full mx-auto mb-3 flex items-center justify-center">
                <span className="font-bold text-text-secondary">HOME</span>
              </div>
              <h4 className="font-bold text-foreground">Real Madrid</h4>
            </div>
            
            {/* Tampilan skor tengah */}
            <div className="text-center">
              <div className="bg-card border border-border px-6 py-3 rounded-xl mb-2">
                <span className="text-4xl font-black text-accent tracking-widest">
                  {liveData?.skor1 || 0} - {liveData?.skor2 || 0}
                </span>
              </div>
              <span className="text-sm font-medium text-red-400 bg-red-400/10 px-3 py-1 rounded-full border border-red-400/20">
                {liveData?.isLive ? `${liveData.menit}' LIVE` : 'FT'}
              </span>
            </div>
            
            <div className="text-center">
               <div className="w-16 h-16 bg-card-alt border border-border rounded-full mx-auto mb-3 flex items-center justify-center">
                <span className="font-bold text-text-secondary">AWAY</span>
              </div>
              <h4 className="font-bold text-foreground">Lawan</h4>
            </div>
          </div>
        </div>

        {/* Kolom 2: Monitoring Stamina Pemain Terendah (Top 5 lowest stamina) */}
        <div className="bg-card border border-border rounded-2xl p-6 flex flex-col">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-bold text-foreground">Stamina Warning</h3>
            <span className="text-xs font-medium text-accent bg-accent/10 px-3 py-1 rounded-full border border-accent/20">
              Live Feed
            </span>
          </div>
          
          <div className="flex-1 overflow-y-auto space-y-3 pr-2">
            {players.length > 0 ? (
              // Mengurutkan pemain berdasarkan stamina dari yang terendah ke tertinggi dan mengambil 5 pemain terendah
              players.sort((a, b) => a.stamina - b.stamina).slice(0, 5).map((player, idx) => (
                <div key={idx} className="flex items-center justify-between p-3 bg-background border border-border rounded-xl">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-card-alt rounded-lg flex items-center justify-center font-bold text-text-secondary text-xs">
                      {player.pos}
                    </div>
                    <div>
                      <h4 className="font-medium text-foreground text-sm">{player.nama}</h4>
                      <p className="text-xs text-text-secondary">{player.status}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-24 bg-card-alt rounded-full h-2 border border-border overflow-hidden">
                      {/* Indikator warna progress bar berdasarkan persentase ketersediaan stamina */}
                      <div 
                        className={`h-full ${player.stamina > 60 ? 'bg-green-500' : player.stamina > 30 ? 'bg-accent' : 'bg-red-500'}`} 
                        style={{ width: `${player.stamina}%` }}
                      ></div>
                    </div>
                    <span className="font-bold text-foreground text-sm w-8 text-right">{player.stamina}%</span>
                  </div>
                </div>
              ))
            ) : (
              <div className="h-full flex flex-col items-center justify-center text-text-secondary">
                <Users className="w-8 h-8 mb-2 opacity-20" />
                <p className="text-sm">Menunggu data pemain...</p>
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
