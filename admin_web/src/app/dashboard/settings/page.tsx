"use client";

import { useState, useEffect, useRef } from "react";
import { io, Socket } from "socket.io-client";
import { User, Lock, Mail, Save, AlertCircle, CheckCircle } from "lucide-react";
import { BACKEND_URL } from "@/config";

/**
 * Komponen Utama: Settings
 * Mengelola profil administrator (nama, foto profil) dan penggantian password secara real-time.
 * Berkomunikasi menggunakan Socket.IO untuk mengambil dan memperbarui data admin.
 */
export default function Settings() {
  // State untuk melacak instance Socket.io client
  const [socket, setSocket] = useState<Socket | null>(null);
  
  // State loading untuk menunjukkan status pemrosesan/penyimpanan data
  const [loading, setLoading] = useState(false);
  
  // State untuk menyimpan data profil pengguna dari server
  const [userData, setUserData] = useState({
    nama: "",
    email: "",
    role: "",
    foto: null as string | null
  });

  // State lokal untuk field input formulir yang dapat diedit oleh user
  const [formNama, setFormNama] = useState("");
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  
  // State untuk menampilkan feedback pesan status (sukses / gagal)
  const [statusMessage, setStatusMessage] = useState<{ type: "success" | "error" | ""; text: string }>({
    type: "",
    text: ""
  });

  // Reference untuk element input file tersembunyi guna unggah foto
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Hook useEffect untuk inisialisasi koneksi Socket.io
  useEffect(() => {
    // Menghubungkan ke backend server yang berjalan di port 3000
    const newSocket = io(BACKEND_URL);

    // Saat berhasil terhubung, minta data sinkronisasi admin terbaru
    newSocket.on("connect", () => {
      newSocket.emit("request_admin_sync");
    });

    // Mendengarkan data profil admin hasil sinkronisasi dari database backend
    newSocket.on("admin_sync", (data) => {
      if (data) {
        setUserData({
          nama: data.nama || "",
          email: data.email || "",
          role: data.role || "",
          foto: data.foto || null
        });
        setFormNama(data.nama || "");
      }
    });

    // Mendengarkan respon perubahan password dari server backend
    newSocket.on("password_response", (res) => {
      setLoading(false);
      if (res.success) {
        setStatusMessage({
          type: "success",
          text: res.message || "Password berhasil diubah!"
        });
        // Kosongkan kembali input password setelah berhasil diubah
        setOldPassword("");
        setNewPassword("");
      } else {
        setStatusMessage({
          type: "error",
          text: res.message || "Gagal mengubah password!"
        });
      }
    });

    // Simpan instance socket secara asinkron untuk menghindari warning render cascading React
    setTimeout(() => {
      setSocket(newSocket);
    }, 0);

    // Membersihkan koneksi socket ketika komponen tidak lagi digunakan (di-unmount)
    return () => {
      newSocket.disconnect();
    };
  }, []);

  // Handler saat file foto profil baru dipilih oleh user
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validasi tipe file harus berupa gambar
    if (!file.type.startsWith("image/")) {
      setStatusMessage({ type: "error", text: "Format file harus berupa gambar!" });
      return;
    }

    // Membatasi ukuran gambar maksimal 2MB agar muatan payload Socket.IO tetap efisien
    if (file.size > 2 * 1024 * 1024) {
      setStatusMessage({ type: "error", text: "Ukuran gambar tidak boleh melebihi 2MB!" });
      return;
    }

    // Membaca file gambar dan mengonversinya menjadi Base64 String
    const reader = new FileReader();
    reader.onloadend = () => {
      const base64String = reader.result as string;
      setUserData((prev) => ({
        ...prev,
        foto: base64String
      }));
      setStatusMessage({ type: "success", text: "Foto profil berhasil dipilih. Klik 'Simpan Perubahan' untuk memperbarui." });
    };
    reader.readAsDataURL(file);
  };

  // Handler untuk menyimpan seluruh perubahan pengaturan profil & keamanan
  const handleSave = () => {
    if (!socket) return;
    setStatusMessage({ type: "", text: "" });

    // Validasi nama lengkap tidak boleh kosong
    if (!formNama.trim()) {
      setStatusMessage({ type: "error", text: "Nama lengkap tidak boleh kosong!" });
      return;
    }

    // Deteksi jika pengguna mencoba mengubah password
    const hasPasswordInput = oldPassword.trim() !== "" || newPassword.trim() !== "";
    if (hasPasswordInput) {
      // Validasi kelengkapan kedua field password
      if (!oldPassword.trim() || !newPassword.trim()) {
        setStatusMessage({ type: "error", text: "Password lama dan password baru keduanya harus diisi!" });
        return;
      }
      // Validasi panjang minimum password baru
      if (newPassword.length < 6) {
        setStatusMessage({ type: "error", text: "Password baru minimal harus 6 karakter!" });
        return;
      }
    }

    setLoading(true);

    // Emit event 'update_user' untuk menyimpan data profil (nama, foto) ke database
    socket.emit("update_user", {
      email: userData.email,
      nama: formNama,
      foto: userData.foto
    });

    // Emit event 'change_password' jika ada input perubahan password
    if (hasPasswordInput) {
      socket.emit("change_password", {
        email: userData.email,
        oldPassword,
        newPassword
      });
    } else {
      // Jika hanya memperbarui data profil dasar, beri konfirmasi cepat secara lokal
      setTimeout(() => {
        setLoading(false);
        setStatusMessage({ type: "success", text: "Profil berhasil diperbarui!" });
      }, 800);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      {/* Header Halaman */}
      <div>
        <h2 className="text-2xl font-bold text-foreground">Pengaturan Admin</h2>
        <p className="text-text-secondary">Kelola profil dan preferensi sistem panel admin.</p>
      </div>

      {/* Notifikasi Alert Status */}
      {statusMessage.text && (
        <div className={`p-4 rounded-xl flex items-center gap-3 border transition-all ${
          statusMessage.type === "success" 
            ? "bg-green-500/10 border-green-500/20 text-green-500" 
            : "bg-red-500/10 border-red-500/20 text-red-400"
        }`}>
          {statusMessage.type === "success" ? (
            <CheckCircle className="w-5 h-5 shrink-0" />
          ) : (
            <AlertCircle className="w-5 h-5 shrink-0" />
          )}
          <p className="text-sm font-medium">{statusMessage.text}</p>
        </div>
      )}

      {/* Card Bagian Profil Administrator */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden">
        <div className="p-6 border-b border-border">
          <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
            <User className="w-5 h-5 text-accent" />
            Profil Administrator
          </h3>
        </div>
        
        <div className="p-6 space-y-6">
           {/* Section Unggah Foto Profil */}
           <div className="flex items-center gap-6">
              <div className="w-24 h-24 bg-card-alt border-2 border-accent rounded-full flex items-center justify-center text-3xl font-bold text-accent overflow-hidden shrink-0">
                  {userData.foto ? (
                    <img src={userData.foto} alt="Profile" className="w-full h-full object-cover" />
                  ) : (
                    userData.nama ? userData.nama.charAt(0).toUpperCase() : "A"
                  )}
              </div>
              <div>
                 <input 
                   type="file"
                   accept="image/*"
                   ref={fileInputRef}
                   onChange={handleFileChange}
                   className="hidden"
                 />
                 <button 
                   type="button"
                   onClick={() => fileInputRef.current?.click()}
                   className="bg-background border border-border hover:border-accent text-foreground px-4 py-2 rounded-xl text-sm font-medium transition-colors"
                 >
                    Ubah Foto Profil
                 </button>
              </div>
           </div>

           {/* Input Field Profil */}
           <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                 <label className="text-sm font-medium text-text-secondary">Nama Lengkap</label>
                 <div className="relative">
                    <User className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-text-secondary" />
                    <input 
                      type="text" 
                      value={formNama} 
                      onChange={(e) => setFormNama(e.target.value)}
                      className="w-full bg-background border border-border rounded-xl py-3 pl-12 pr-4 text-foreground focus:outline-none focus:border-accent" 
                    />
                 </div>
              </div>
              
              <div className="space-y-2">
                 <label className="text-sm font-medium text-text-secondary">Email (Read Only)</label>
                 <div className="relative">
                    <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-text-secondary" />
                    <input 
                      type="email" 
                      value={userData.email || "admin@stema.com"} 
                      disabled 
                      className="w-full bg-card-alt border border-border rounded-xl py-3 pl-12 pr-4 text-text-secondary cursor-not-allowed opacity-70" 
                    />
                 </div>
              </div>

              <div className="space-y-2">
                 <label className="text-sm font-medium text-text-secondary">Role</label>
                 <div className="relative">
                    <input 
                      type="text" 
                      value={userData.role || "Super Administrator"} 
                      disabled 
                      className="w-full bg-card-alt border border-border rounded-xl py-3 px-4 text-text-secondary cursor-not-allowed opacity-70" 
                    />
                 </div>
              </div>
           </div>
        </div>
      </div>

      {/* Card Bagian Keamanan (Password) */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden">
        <div className="p-6 border-b border-border">
          <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
            <Lock className="w-5 h-5 text-accent" />
            Keamanan Akun
          </h3>
        </div>
        
        <div className="p-6 space-y-6">
           <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                 <label className="text-sm font-medium text-text-secondary">Password Lama</label>
                 <input 
                   type="password" 
                   placeholder="••••••••" 
                   value={oldPassword}
                   onChange={(e) => setOldPassword(e.target.value)}
                   className="w-full bg-background border border-border rounded-xl py-3 px-4 text-foreground focus:outline-none focus:border-accent" 
                 />
              </div>
              
              <div className="space-y-2">
                 <label className="text-sm font-medium text-text-secondary">Password Baru</label>
                 <input 
                   type="password" 
                   placeholder="••••••••" 
                   value={newPassword}
                   onChange={(e) => setNewPassword(e.target.value)}
                   className="w-full bg-background border border-border rounded-xl py-3 px-4 text-foreground focus:outline-none focus:border-accent" 
                 />
              </div>
           </div>
        </div>
      </div>

      {/* Tombol Simpan Perubahan */}
      <div className="flex justify-end">
         <button 
           onClick={handleSave}
           disabled={loading}
           className="bg-accent text-background font-bold px-8 py-3 rounded-xl hover:bg-accent/90 transition-colors flex items-center gap-2 disabled:opacity-70"
         >
           {loading ? (
             <div className="w-5 h-5 border-2 border-background border-t-transparent rounded-full animate-spin" />
           ) : (
             <>
                <Save className="w-5 h-5" />
                Simpan Perubahan
             </>
           )}
         </button>
      </div>
    </div>
  );
}
