// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Layout Dashboard Web Admin
// File: admin_web/src/app/dashboard/layout.tsx
// Deskripsi: Layout utama untuk halaman dashboard admin. Menyediakan bilah sisi
//            navigasi (sidebar), topbar sistem online, sinkronisasi profil admin via
//            Socket.IO, dan pembungkus konten dinamis (children).
// ==========================================================================

"use client";

import { ReactNode, useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { io } from "socket.io-client";
import { BACKEND_URL } from "@/config";
import { 
  LayoutDashboard, 
  Users, 
  Settings, 
  Activity, 
  LogOut,
  Menu,
  X,
  Database
} from "lucide-react";

export default function DashboardLayout({ children }: { children: ReactNode }) {
  const pathname = usePathname(); // Melacak URL aktif untuk menandai item menu navigasi
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false); // Melacak status slide-in menu di HP
  
  // State data profil administrator
  const [user, setUser] = useState({
    nama: "Super Admin",
    email: "admin@stema.com",
    role: "Super Administrator",
    foto: null as string | null
  });

  // Hubungkan ke Socket.IO untuk pembaruan profil secara real-time
  useEffect(() => {
    const socket = io(BACKEND_URL);

    // Kirim permintaan profil admin teraktual sesaat setelah tersambung
    socket.on("connect", () => {
      socket.emit("request_admin_sync");
    });

    // Dengarkan event sinkronisasi profil dari backend server
    socket.on("admin_sync", (data) => {
      if (data) {
        setUser({
          nama: data.nama || "Super Admin",
          email: data.email || "admin@stema.com",
          role: data.role || "Super Administrator",
          foto: data.foto || null
        });
      }
    });

    // Bersihkan koneksi socket saat layout tidak di-render lagi
    return () => {
      socket.disconnect();
    };
  }, []);

  // Menu navigasi panel administrator
  const navItems = [
    { name: "Overview", href: "/dashboard", icon: LayoutDashboard },
    { name: "Data Pemain", href: "/dashboard/players", icon: Users },
    { name: "Live Match", href: "/dashboard/match", icon: Activity },
    { name: "Sistem DB", href: "/dashboard/database", icon: Database },
    { name: "Pengaturan", href: "/dashboard/settings", icon: Settings },
  ];

  // Keluar dari sesi admin (redirect ke halaman login utama)
  const handleLogout = () => {
    router.push("/");
  };

  return (
    <div className="min-h-screen bg-background flex flex-col md:flex-row">
      
      {/* Mobile Header (Hanya tampil di ukuran layar kecil/smartphone) */}
      <div className="md:hidden flex items-center justify-between p-4 bg-card border-b border-border">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-card-alt border border-accent rounded-lg flex items-center justify-center overflow-hidden">
            <img src="/stema_logo.png" alt="STEMA Logo" className="w-full h-full object-cover" />
          </div>
          <span className="font-bold text-foreground">STEMA Admin</span>
        </div>
        {/* Tombol hamburger menu */}
        <button 
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="text-text-secondary hover:text-foreground"
        >
          {sidebarOpen ? <X /> : <Menu />}
        </button>
      </div>

      {/* Sidebar Navigasi Utama (Responsif: tersembunyi di HP, melayang saat aktif) */}
      <div className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-card border-r border-border transform transition-transform duration-300 ease-in-out md:relative md:translate-x-0
        ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}
      `}>
        <div className="h-full flex flex-col">
          {/* Area Logo & Identitas Brand (Hanya tampil di ukuran desktop) */}
          <div className="hidden md:flex items-center gap-3 p-6 border-b border-border">
            <div className="w-10 h-10 bg-card-alt border border-accent rounded-xl flex items-center justify-center overflow-hidden">
              <img src="/stema_logo.png" alt="STEMA Logo" className="w-full h-full object-cover" />
            </div>
            <div>
              <h2 className="font-bold text-foreground tracking-wide">STEMA</h2>
              <p className="text-xs text-text-secondary">Admin Panel</p>
            </div>
          </div>

          {/* Navigasi Links */}
          <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                    isActive 
                      ? "bg-accent/10 text-accent border border-accent/20" 
                      : "text-text-secondary hover:bg-card-alt hover:text-foreground"
                  }`}
                  onClick={() => setSidebarOpen(false)}
                >
                  <Icon className="w-5 h-5" />
                  <span className="font-medium">{item.name}</span>
                </Link>
              );
            })}
          </nav>

          {/* User Profile Info & Tombol Logout */}
          <div className="p-4 border-t border-border">
            {/* Kartu Detail Admin ter-sinkronisasi */}
            <div className="flex items-center gap-3 px-4 py-3 mb-2 rounded-xl bg-card-alt border border-border">
              <div className="w-10 h-10 bg-background rounded-full flex items-center justify-center text-accent font-bold overflow-hidden shrink-0">
                {user.foto ? (
                  <img src={user.foto} alt="Profile" className="w-full h-full object-cover" />
                ) : (
                  user.nama ? user.nama.charAt(0).toUpperCase() : "A"
                )}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">{user.nama}</p>
                <p className="text-xs text-text-secondary truncate">{user.email}</p>
              </div>
            </div>
            {/* Tombol Logout */}
            <button 
              onClick={handleLogout}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-red-400 hover:bg-red-400/10 hover:text-red-300 transition-colors"
            >
              <LogOut className="w-5 h-5" />
              <span className="font-medium">Logout</span>
            </button>
          </div>
        </div>
      </div>

      {/* Main Content Pane */}
      <div className="flex-1 flex flex-col min-h-0 overflow-hidden">
        {/* Topbar Desktop */}
        <header className="hidden md:flex items-center justify-between px-8 py-4 bg-background border-b border-border">
          <h1 className="text-xl font-bold text-foreground">
            {navItems.find(i => i.href === pathname)?.name || "Dashboard"}
          </h1>
          <div className="flex items-center gap-4">
            {/* Indikator Status Server Live */}
            <div className="flex items-center gap-2 px-3 py-1.5 bg-green-500/10 border border-green-500/20 rounded-full">
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
              <span className="text-xs font-medium text-green-500">System Online</span>
            </div>
            <p className="text-sm text-text-secondary">
              {new Date().toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
            </p>
          </div>
        </header>

        {/* Page Content Viewport (Scrollable) */}
        <main className="flex-1 overflow-y-auto p-4 md:p-8">
          {children}
        </main>
      </div>

      {/* Mobile Sidebar Overlay (Menutup sidebar saat klik area kosong di HP) */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 md:hidden backdrop-blur-sm"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}
