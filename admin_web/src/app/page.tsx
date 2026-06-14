// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Halaman Login Web Admin
// File: admin_web/src/app/page.tsx
// Deskripsi: Halaman login utama untuk administrator. Mengirim kredensial email/password
//            ke backend API untuk validasi sesi admin dan mengarahkan ke dashboard.
// ==========================================================================

"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Lock, Mail, Eye, EyeOff } from "lucide-react";
import { BACKEND_URL } from "@/config";

export default function LoginPage() {
  // State untuk melacak input formulir dan status pemuatan
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false); // Mengatur visibilitas password
  const [error, setError] = useState("");                   // Pesan error jika login gagal
  const [loading, setLoading] = useState(false);             // Status pemuatan saat memproses API
  const router = useRouter();                                // Router Next.js untuk pengalihan navigasi

  // Menangani submit formulir login
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      // Mengirim POST request untuk autentikasi admin ke REST API backend
      const res = await fetch(`${BACKEND_URL}/api/admin/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      
      // Jika berhasil, arahkan pengguna ke halaman dashboard panel admin
      if (res.ok && data.success) {
        router.push("/dashboard");
      } else {
        setError(data.message || "Email atau password admin salah");
        setLoading(false);
      }
    } catch (err) {
      setError("Gagal menghubungkan ke server. Pastikan backend aktif.");
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="w-full max-w-md bg-card border border-border rounded-2xl p-8 shadow-2xl">
        
        {/* Header Visual Halaman Login */}
        <div className="text-center mb-8">
          <div className="w-20 h-20 bg-card-alt border border-accent rounded-full mx-auto mb-4 flex items-center justify-center overflow-hidden">
            <img src="/stema_logo.png" alt="STEMA Logo" className="w-full h-full object-cover" />
          </div>
          <h1 className="text-2xl font-bold text-foreground">STEMA Admin</h1>
          <p className="text-text-secondary mt-2">Login ke Panel Administrator</p>
        </div>

        {/* Notifikasi Teks Pesan Error */}
        {error && (
          <div className="bg-red-500/10 border border-red-500/50 text-red-500 px-4 py-3 rounded-xl mb-6 text-sm text-center">
            {error}
          </div>
        )}

        {/* Form Input Data Kredensial */}
        <form onSubmit={handleLogin} className="space-y-6">
          {/* Kolom Email */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">Email Administrator</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-text-secondary" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-background border border-border rounded-xl py-3 pl-12 pr-4 text-foreground placeholder:text-border focus:outline-none focus:border-accent transition-colors"
                placeholder="admin@stema.com"
              />
            </div>
          </div>

          {/* Kolom Password */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-text-secondary" />
              <input
                type={showPassword ? "text" : "password"}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-background border border-border rounded-xl py-3 pl-12 pr-12 text-foreground placeholder:text-border focus:outline-none focus:border-accent transition-colors"
                placeholder="••••••••"
              />
              {/* Tombol Toggle Visibilitas Karakter Password */}
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary hover:text-foreground transition-colors"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          {/* Tombol Login */}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-accent text-background font-bold py-3.5 rounded-xl hover:bg-accent/90 transition-all flex items-center justify-center disabled:opacity-70"
          >
            {loading ? (
              <div className="w-5 h-5 border-2 border-background border-t-transparent rounded-full animate-spin" />
            ) : (
              "LOGIN ADMIN"
            )}
          </button>
        </form>

        {/* Petunjuk Info Kredensial Default */}
        <div className="mt-8 text-center">
          <p className="text-sm text-text-secondary">
            Gunakan email: <span className="text-accent font-medium">admin@stema.com</span>
            <br />Password: <span className="text-accent font-medium">admin123</span>
          </p>
        </div>
      </div>
    </div>
  );
}
