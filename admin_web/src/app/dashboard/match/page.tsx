// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Kontrol Live Match Admin
// File: admin_web/src/app/dashboard/match/page.tsx
// Deskripsi: Panel kontrol jalannya pertandingan untuk administrator.
//            Menyediakan tombol untuk memulai/mengakhiri sesi pertandingan,
//            menampilkan papan skor secara live, serta memantau status engine simulasi.
// ==========================================================================

"use client";

import { useEffect, useState } from "react";
import { io, Socket } from "socket.io-client";
import { Play, Square, Settings, Timer } from "lucide-react";
import { BACKEND_URL } from "@/config";

// Struktur data status pertandingan live
interface LiveData {
  skor1: number;
  skor2: number;
  menit: number;
  isLive: boolean;
  fase: string;
}

export default function MatchControl() {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [liveData, setLiveData] = useState<LiveData | null>(null);

  // Setup Socket.IO dan sync data saat komponen di-load
  useEffect(() => {
    const newSocket = io(BACKEND_URL);

    // Kirim request data terbaru dari server saat tersambung
    newSocket.on("connect", () => {
      newSocket.emit("request_sync");
    });

    // Sinkronisasi data live match dari event server
    newSocket.on("live_match_sync", (data) => {
      setLiveData(data);
    });

    // Simpan instance socket secara asinkron untuk menghindari warning render cascading React
    setTimeout(() => {
      setSocket(newSocket);
    }, 0);

    // Putuskan koneksi saat halaman ditutup
    return () => {
      newSocket.disconnect();
    };
  }, []);

  // Memicu mulainya pertandingan di server
  const handleStartMatch = () => {
    if (socket) {
      socket.emit("start_match");
    }
  };

  // Mengakhiri pertandingan dan menyusun data laporan
  const handleEndMatch = () => {
    if (socket) {
      // Mengirim trigger finish_match disertai mock data statistik tim
      socket.emit("finish_match", {
        possession: "60",
        passes: "500",
        shots: "10",
        shotsOnTarget: "5",
        timKandang: "Real Madrid",
        timTandang: "Lawan"
      });
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Halaman */}
      <div>
        <h2 className="text-2xl font-bold text-foreground">Kontrol Live Match</h2>
        <p className="text-text-secondary">Kelola pertandingan yang sedang berlangsung, termasuk simulasi skor dan menit.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Papan Skor Visual */}
        <div className="col-span-2 space-y-6">
          <div className="bg-card border border-border rounded-2xl p-8 text-center">
            <h3 className="text-xl font-bold text-foreground mb-6">Papan Skor</h3>
            <div className="flex items-center justify-center gap-8 mb-8">
              
              {/* Tim Home */}
              <div className="text-center">
                <div className="w-24 h-24 bg-card-alt border-2 border-border rounded-full mx-auto mb-4 flex items-center justify-center shadow-lg">
                  <span className="font-bold text-text-secondary">HOME</span>
                </div>
                <h4 className="text-xl font-bold text-foreground">Real Madrid</h4>
              </div>

              {/* Tampilan Skor & Menit */}
              <div className="px-6 text-center">
                <div className="bg-background border border-border px-8 py-4 rounded-2xl mb-4 shadow-inner">
                  <span className="text-6xl font-black text-accent tracking-widest">
                    {liveData?.skor1 || 0} - {liveData?.skor2 || 0}
                  </span>
                </div>
                <div className="flex items-center justify-center gap-2">
                  <Timer className="w-5 h-5 text-text-secondary" />
                  <span className="text-lg font-medium text-text-secondary">
                    {liveData?.isLive ? `${liveData.menit}'` : 'Belum Mulai'}
                  </span>
                </div>
                <div className="mt-2 text-sm text-text-secondary font-medium">
                  Fase: {liveData?.fase || 'Persiapan'}
                </div>
              </div>

              {/* Tim Away */}
              <div className="text-center">
                 <div className="w-24 h-24 bg-card-alt border-2 border-border rounded-full mx-auto mb-4 flex items-center justify-center shadow-lg">
                  <span className="font-bold text-text-secondary">AWAY</span>
                </div>
                <h4 className="text-xl font-bold text-foreground">Lawan</h4>
              </div>
            </div>

            {/* Tombol Kontrol Pertandingan */}
            <div className="flex justify-center gap-4">
              {!liveData?.isLive ? (
                <button 
                  onClick={handleStartMatch}
                  className="flex items-center gap-2 bg-green-500 text-white font-bold px-8 py-3 rounded-xl hover:bg-green-600 transition-colors"
                >
                  <Play className="w-5 h-5" />
                  Mulai Pertandingan
                </button>
              ) : (
                <button 
                  onClick={handleEndMatch}
                  className="flex items-center gap-2 bg-red-500 text-white font-bold px-8 py-3 rounded-xl hover:bg-red-600 transition-colors"
                >
                  <Square className="w-5 h-5" />
                  Akhiri Pertandingan
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Panel Informasi Simulasi Server */}
        <div className="space-y-6">
          <div className="bg-card border border-border rounded-2xl p-6">
             <h3 className="text-lg font-bold text-foreground mb-4 flex items-center gap-2">
                <Settings className="w-5 h-5 text-accent" />
                Simulasi Server
             </h3>
             <p className="text-sm text-text-secondary mb-4">
                Server Node.js secara otomatis mengurangi stamina pemain 1% setiap 10 detik (real-time) saat pertandingan berlangsung. 
                Gol dan update menit akan disinkronisasi langsung dari aplikasi Flutter.
              </p>
             <div className="bg-background border border-border rounded-xl p-4">
               <div className="flex items-center justify-between mb-2">
                 <span className="text-sm text-text-secondary">Status Engine</span>
                 <span className={`text-xs font-bold px-2 py-1 rounded ${liveData?.isLive ? 'bg-green-500/10 text-green-500' : 'bg-red-500/10 text-red-500'}`}>
                    {liveData?.isLive ? 'AKTIF' : 'BERHENTI'}
                 </span>
               </div>
               <div className="flex items-center justify-between">
                 <span className="text-sm text-text-secondary">Interval Sinkronisasi</span>
                 <span className="text-sm font-medium text-foreground">10 detik</span>
               </div>
             </div>
          </div>
        </div>
      </div>
    </div>
  );
}
