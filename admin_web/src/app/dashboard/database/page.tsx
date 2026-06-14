// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Manajemen Database Admin
// File: admin_web/src/app/dashboard/database/page.tsx
// Deskripsi: Panel pengelolaan database JSON lokal untuk administrator.
//            Menampilkan daftar aturan aktif, daftar pemain, sinkronisasi paksa,
//            serta ekspor/unduh backup file database.json langsung dari backend.
// ==========================================================================

"use client";

import { useEffect, useState } from "react";
import { io, Socket } from "socket.io-client";
import { Download, Server, RefreshCw, FileJson } from "lucide-react";
import { BACKEND_URL } from "@/config";

// Tipe data aturan rule engine
interface RuleData {
  nama: string;
  if: string;
  aktif: boolean;
}

// Tipe data ringkas pemain
interface PlayerData {
  nama: string;
  pos: string;
}

export default function DatabaseManagement() {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [rules, setRules] = useState<RuleData[]>([]);
  const [players, setPlayers] = useState<PlayerData[]>([]);
  const [syncing, setSyncing] = useState(false); // Melacak animasi putar tombol sync

  // Setup Socket.IO dan sync data saat komponen di-load
  useEffect(() => {
    const newSocket = io(BACKEND_URL);

    // Kirim request data terbaru dari server saat tersambung
    newSocket.on("connect", () => {
      newSocket.emit("request_sync");
    });

    // Sinkronisasi data rules dan data pemain dari event server
    newSocket.on("rules_sync", (data) => setRules(data));
    newSocket.on("stamina_sync", (data) => setPlayers(data));

    // Simpan instance socket secara asinkron untuk menghindari warning render cascading React
    setTimeout(() => {
      setSocket(newSocket);
    }, 0);

    // Putuskan koneksi saat halaman ditutup
    return () => {
      newSocket.disconnect();
    };
  }, []);

  // Menangani penekanan tombol 'Sinkronisasi Paksa'
  const handleForceSync = () => {
    if (socket) {
      setSyncing(true);
      // Kirim event penarikan data ulang ke server
      socket.emit("request_sync");
      // Sembunyikan efek pemuatan setelah 800ms
      setTimeout(() => {
        setSyncing(false);
      }, 800);
    }
  };

  // Menangani penekanan tombol ekspor database JSON (Mengunduh database.json via browser)
  const handleExportJSON = async () => {
    try {
      // Menarik file database.json dari REST API endpoint server backend
      const response = await fetch(`${BACKEND_URL}/api/database/export`);
      if (!response.ok) throw new Error("Gagal mengunduh database");
      
      // Mengubah response menjadi object binary besar (Blob)
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      
      // Bikin elemen link semu 'a' untuk memicu download otomatis di browser
      const a = document.createElement("a");
      a.href = url;
      a.download = "database.json";
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url); // Hapus referensi URL Blob dari memori
    } catch (error) {
      console.error("Export error:", error);
      alert("Gagal mengekspor database. Pastikan backend server aktif.");
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Halaman */}
      <div>
        <h2 className="text-2xl font-bold text-foreground">Sistem Database</h2>
        <p className="text-text-secondary">Pantau status database JSON lokal pada server backend.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Kolom 1: Daftar Aturan Rule Engine */}
        <div className="bg-card border border-border rounded-2xl p-6">
          <div className="flex items-center justify-between mb-4">
             <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
                <FileJson className="w-5 h-5 text-accent" />
                Data Rule Engine
             </h3>
             <span className="text-xs font-bold bg-accent/10 text-accent px-2 py-1 rounded">
               {rules.length} Aturan
             </span>
          </div>
          <div className="space-y-3">
             {rules.map((rule, idx) => (
                <div key={idx} className="bg-background border border-border p-3 rounded-xl flex justify-between items-center">
                   <div className="truncate">
                      <p className="text-sm font-medium text-foreground truncate">{rule.nama}</p>
                      <p className="text-xs text-text-secondary truncate">{rule.if}</p>
                   </div>
                   {/* Indikator status keaktifan rule */}
                   <div className={`w-2 h-2 rounded-full flex-shrink-0 ${rule.aktif ? 'bg-green-500' : 'bg-red-500'}`}></div>
                </div>
             ))}
          </div>
        </div>

        {/* Kolom 2: Daftar Roster Pemain */}
        <div className="bg-card border border-border rounded-2xl p-6">
          <div className="flex items-center justify-between mb-4">
             <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
                <UsersIcon className="w-5 h-5 text-accent" />
                Data Skuad
             </h3>
             <span className="text-xs font-bold bg-accent/10 text-accent px-2 py-1 rounded">
               {players.length} Pemain
             </span>
          </div>
          {/* Scrollable list pemain */}
          <div className="space-y-3 h-64 overflow-y-auto pr-2">
             {players.map((p, idx) => (
                <div key={idx} className="bg-background border border-border p-3 rounded-xl flex justify-between items-center">
                   <span className="text-sm font-medium text-foreground">{p.nama}</span>
                   <span className="text-xs font-medium text-text-secondary">{p.pos}</span>
                </div>
             ))}
          </div>
        </div>

        {/* Kolom 3: Status Server & Aksi Database */}
        <div className="bg-card border border-border rounded-2xl p-6 flex flex-col justify-between">
           <div>
              <h3 className="text-lg font-bold text-foreground mb-4 flex items-center gap-2">
                 <Server className="w-5 h-5 text-accent" />
                 Server Node.js
              </h3>
              <p className="text-sm text-text-secondary mb-6">
                 Backend menyimpan data secara permanen di dalam <code className="text-accent bg-accent/10 px-1 py-0.5 rounded">database.json</code>.
                 Anda dapat membackup data ini langsung.
              </p>
           </div>
           
           {/* Tombol Sinkronisasi Paksa & Ekspor Database */}
           <div className="space-y-3">
              <button 
                onClick={handleForceSync}
                disabled={syncing}
                className="w-full flex justify-center items-center gap-2 bg-background border border-border hover:border-accent hover:text-accent transition-colors py-3 rounded-xl font-medium text-sm text-foreground disabled:opacity-50 cursor-pointer"
              >
                 <RefreshCw className={`w-4 h-4 ${syncing ? 'animate-spin' : ''}`} />
                 {syncing ? 'Menyinkronkan...' : 'Sinkronisasi Paksa'}
              </button>
              <button 
                onClick={handleExportJSON}
                className="w-full flex justify-center items-center gap-2 bg-accent text-background transition-colors py-3 rounded-xl font-bold text-sm cursor-pointer"
              >
                 <Download className="w-4 h-4" />
                 Export Database JSON
              </button>
           </div>
        </div>
      </div>
    </div>
  );
}

// Komponen ikon SVG kustom untuk Users
function UsersIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}
