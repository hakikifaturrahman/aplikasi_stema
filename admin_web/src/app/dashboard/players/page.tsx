"use client";

import { useEffect, useState } from "react";
import { io, Socket } from "socket.io-client";
import { Search, Filter, ShieldAlert, Plus, Edit2, Trash2, X, AlertTriangle } from "lucide-react";
import { BACKEND_URL } from "@/config";

// Interface untuk mendefinisikan struktur data pemain
interface PlayerData {
  nama: string;      // Nama lengkap pemain
  no: number;        // Nomor punggung pemain (unik)
  pos: string;       // Posisi bermain (FW, MF, DF, GK)
  stamina: number;   // Persentase stamina saat ini (0-100)
  status: string;    // Status pemain (Main, Cadangan, Pemanasan, Cedera, Kartu Kuning, Kartu Merah)
  gol?: number;      // Jumlah gol yang dicetak (opsional)
  kartu?: string;    // Informasi kartu (opsional)
}

/**
 * Komponen Utama: PlayersManagement
 * Mengelola data pemain secara real-time dengan koneksi Socket.io ke backend.
 * Menyediakan fitur CRUD (Create, Read, Update, Delete) serta pencarian dan penyaringan data pemain.
 */
export default function PlayersManagement() {
  // State untuk koneksi Socket.io
  const [socket, setSocket] = useState<Socket | null>(null);
  
  // State untuk menyimpan daftar pemain yang sinkron dengan backend
  const [players, setPlayers] = useState<PlayerData[]>([]);
  
  // State pencarian berdasarkan input user
  const [searchQuery, setSearchQuery] = useState("");

  // State visibilitas untuk masing-masing Modal dialog
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);

  // State untuk melacak pemain mana yang sedang dipilih untuk diedit atau dihapus
  const [selectedPlayer, setSelectedPlayer] = useState<PlayerData | null>(null);

  // State form untuk penambahan & pengeditan data pemain
  const [formNama, setFormNama] = useState("");
  const [formNo, setFormNo] = useState<number>(0);
  const [formPos, setFormPos] = useState("FW");
  const [formStatus, setFormStatus] = useState("Main");
  const [formStamina, setFormStamina] = useState<number>(100);
  const [formGol, setFormGol] = useState<number>(0);
  const [formError, setFormError] = useState(""); // Menyimpan pesan error validasi form

  // State untuk filter posisi dan status pemain
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [selectedPosFilter, setSelectedPosFilter] = useState("ALL");
  const [selectedStatusFilter, setSelectedStatusFilter] = useState("ALL");

  // Hook useEffect untuk inisialisasi koneksi Socket.io
  useEffect(() => {
    // Menghubungkan ke backend server yang berjalan di port 3000
    const newSocket = io(BACKEND_URL);

    // Ketika koneksi berhasil, minta sinkronisasi data pemain terbaru
    newSocket.on("connect", () => {
      newSocket.emit("request_sync");
    });

    // Mendengarkan event 'stamina_sync' untuk menerima data pemain ter-update secara berkala/real-time
    newSocket.on("stamina_sync", (data) => {
      setPlayers(data);
    });

    // Simpan instance socket secara asinkron untuk menghindari warning render cascading React
    setTimeout(() => {
      setSocket(newSocket);
    }, 0);

    // Membersihkan / menutup koneksi socket ketika komponen di-unmount
    return () => {
      newSocket.disconnect();
    };
  }, []);

  // Fungsi untuk membuka modal Tambah Pemain dengan nilai default
  const openAddModal = () => {
    // Secara otomatis mencari nomor punggung tertinggi untuk direkomendasikan pada input form
    const maxNo = players.length > 0 ? Math.max(...players.map(p => p.no)) : 0;
    setFormNama("");
    setFormNo(maxNo + 1);
    setFormPos("FW");
    setFormStatus("Main");
    setFormStamina(100);
    setFormGol(0);
    setFormError("");
    setIsAddModalOpen(true);
  };

  // Fungsi untuk membuka modal Edit Pemain dan mengisi form dengan data pemain terpilih
  const openEditModal = (player: PlayerData) => {
    setSelectedPlayer(player);
    setFormNama(player.nama);
    setFormNo(player.no);
    setFormPos(player.pos);
    setFormStatus(player.status);
    setFormStamina(player.stamina);
    setFormGol(player.gol || 0);
    setFormError("");
    setIsEditModalOpen(true);
  };

  // Fungsi untuk membuka modal konfirmasi Hapus Pemain
  const openDeleteModal = (player: PlayerData) => {
    setSelectedPlayer(player);
    setIsDeleteModalOpen(true);
  };

  // Handler untuk submit form tambah pemain baru
  const handleAddSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!socket) return;

    // Validasi input nama
    if (!formNama.trim()) {
      setFormError("Nama pemain tidak boleh kosong");
      return;
    }

    // Validasi duplikasi nama pemain
    if (players.some(p => p.nama.toLowerCase() === formNama.trim().toLowerCase())) {
      setFormError("Nama pemain sudah ada di tim");
      return;
    }

    // Validasi nomor punggung unik
    if (players.some(p => p.no === Number(formNo))) {
      setFormError(`Nomor punggung ${formNo} sudah digunakan oleh pemain lain`);
      return;
    }

    const newPlayer = {
      nama: formNama.trim(),
      no: Number(formNo),
      pos: formPos,
      stamina: Number(formStamina),
      status: formStatus,
      gol: Number(formGol),
    };

    // Emit event 'add_player' ke backend
    socket.emit("add_player", newPlayer);
    setIsAddModalOpen(false);
  };

  // Handler untuk submit form pengeditan data pemain
  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!socket || !selectedPlayer) return;

    // Validasi input nama
    if (!formNama.trim()) {
      setFormError("Nama pemain tidak boleh kosong");
      return;
    }

    // Validasi nama baru tidak boleh duplikat dengan pemain lain
    if (players.some(p => p.nama.toLowerCase() === formNama.trim().toLowerCase() && p.nama !== selectedPlayer.nama)) {
      setFormError("Nama pemain sudah digunakan oleh pemain lain");
      return;
    }

    // Validasi nomor punggung baru tidak boleh duplikat dengan pemain lain
    if (players.some(p => p.no === Number(formNo) && p.nama !== selectedPlayer.nama)) {
      setFormError(`Nomor punggung ${formNo} sudah digunakan oleh pemain lain`);
      return;
    }

    const updatedPlayer = {
      originalName: selectedPlayer.nama, // Diperlukan backend untuk mencari pemain mana yang akan diedit
      nama: formNama.trim(),
      no: Number(formNo),
      pos: formPos,
      stamina: Number(formStamina),
      status: formStatus,
      gol: Number(formGol),
    };

    // Emit event 'edit_player' ke backend
    socket.emit("edit_player", updatedPlayer);
    setIsEditModalOpen(false);
    setSelectedPlayer(null);
  };

  // Handler konfirmasi hapus pemain
  const handleDeleteConfirm = () => {
    if (!socket || !selectedPlayer) return;
    
    // Emit event 'delete_player' dengan parameter nama pemain ke backend
    socket.emit("delete_player", selectedPlayer.nama);
    setIsDeleteModalOpen(false);
    setSelectedPlayer(null);
  };

  // Filter daftar pemain berdasarkan pencarian teks, filter posisi, dan filter status
  const filteredPlayers = players.filter(p => {
    const matchesSearch = p.nama.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.pos.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.status.toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesPos = selectedPosFilter === "ALL" || p.pos === selectedPosFilter;
    const matchesStatus = selectedStatusFilter === "ALL" || p.status === selectedStatusFilter;
    
    return matchesSearch && matchesPos && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Header Halaman */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Data Pemain</h2>
          <p className="text-text-secondary text-sm">Kelola daftar pemain, status, dan stamina secara real-time</p>
        </div>
        <button 
          onClick={openAddModal}
          className="bg-accent text-background font-bold px-4 py-2 rounded-xl hover:bg-accent/90 transition-colors flex items-center gap-2 cursor-pointer"
        >
          <Plus className="w-5 h-5" />
          Tambah Pemain
        </button>
      </div>

      {/* Bagian Tabel & Toolbar */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden">
        {/* Toolbar: Input Pencarian dan Tombol Filter */}
        <div className="p-4 border-b border-border flex flex-col sm:flex-row gap-4 justify-between bg-card-alt/50">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-text-secondary" />
            <input 
              type="text" 
              placeholder="Cari nama pemain, posisi..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-background border border-border rounded-xl text-foreground focus:border-accent focus:outline-none"
            />
          </div>
          <div className="relative">
            <button 
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className="flex items-center justify-center gap-2 px-4 py-2 bg-background border border-border rounded-xl text-foreground hover:border-accent hover:text-accent transition-colors cursor-pointer"
            >
              <Filter className="w-4 h-4" />
              Filter {(selectedPosFilter !== "ALL" || selectedStatusFilter !== "ALL") && "(Aktif)"}
            </button>
            
            {/* Popover Menu Filter */}
            {isFilterOpen && (
              <>
                <div className="fixed inset-0 z-10" onClick={() => setIsFilterOpen(false)} />
                <div className="absolute right-0 mt-2 w-64 bg-card border border-border rounded-2xl shadow-xl p-4 z-20 space-y-4">
                  {/* Pilihan Filter Posisi */}
                  <div className="space-y-2">
                    <label className="text-xs font-semibold text-text-secondary uppercase">Posisi</label>
                    <select
                      value={selectedPosFilter}
                      onChange={(e) => setSelectedPosFilter(e.target.value)}
                      className="w-full bg-background border border-border rounded-xl px-3 py-2 text-sm text-foreground focus:border-accent focus:outline-none"
                    >
                      <option value="ALL">Semua Posisi</option>
                      <option value="FW">FW (Penyerang)</option>
                      <option value="MF">MF (Gelandang)</option>
                      <option value="DF">DF (Bertahan)</option>
                      <option value="GK">GK (Kiper)</option>
                    </select>
                  </div>
                  
                  {/* Pilihan Filter Status */}
                  <div className="space-y-2">
                    <label className="text-xs font-semibold text-text-secondary uppercase">Status</label>
                    <select
                      value={selectedStatusFilter}
                      onChange={(e) => setSelectedStatusFilter(e.target.value)}
                      className="w-full bg-background border border-border rounded-xl px-3 py-2 text-sm text-foreground focus:border-accent focus:outline-none"
                    >
                      <option value="ALL">Semua Status</option>
                      <option value="Main">Main (Utama)</option>
                      <option value="Cadangan">Cadangan</option>
                      <option value="Pemanasan">Pemanasan</option>
                      <option value="Cedera">Cedera</option>
                      <option value="Kartu Kuning">Kartu Kuning</option>
                      <option value="Kartu Merah">Kartu Merah</option>
                    </select>
                  </div>

                  {/* Tombol Aksi di dalam Popover Filter */}
                  <div className="flex justify-between items-center pt-2 border-t border-border">
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedPosFilter("ALL");
                        setSelectedStatusFilter("ALL");
                        setIsFilterOpen(false);
                      }}
                      className="text-xs text-text-secondary hover:text-red-400 font-medium transition-colors cursor-pointer"
                    >
                      Reset Filter
                    </button>
                    <button
                      type="button"
                      onClick={() => setIsFilterOpen(false)}
                      className="bg-accent text-background text-xs font-bold px-3 py-1.5 rounded-lg hover:bg-accent/90 transition-colors cursor-pointer"
                    >
                      Terapkan
                    </button>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Tabel Daftar Pemain */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-card-alt border-b border-border text-text-secondary text-sm">
                <th className="p-4 font-medium whitespace-nowrap">NO.</th>
                <th className="p-4 font-medium whitespace-nowrap">NAMA PEMAIN</th>
                <th className="p-4 font-medium whitespace-nowrap">POSISI</th>
                <th className="p-4 font-medium whitespace-nowrap">STATUS</th>
                <th className="p-4 font-medium whitespace-nowrap">STAMINA</th>
                <th className="p-4 font-medium whitespace-nowrap text-center">AKSI</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filteredPlayers.length > 0 ? (
                // Mengurutkan pemain berdasarkan nomor punggung secara menaik (ascending)
                [...filteredPlayers].sort((a, b) => a.no - b.no).map((player, idx) => (
                  <tr key={idx} className="hover:bg-card-alt/30 transition-colors">
                    <td className="p-4 text-foreground font-medium">{player.no}</td>
                    <td className="p-4">
                      <div className="font-medium text-foreground">{player.nama}</div>
                    </td>
                    <td className="p-4">
                      <span className="inline-flex items-center justify-center bg-background border border-border rounded-lg px-2.5 py-1 text-xs font-bold text-text-secondary">
                        {player.pos}
                      </span>
                    </td>
                    <td className="p-4">
                      {/* Badge dinamis yang berganti warna sesuai status pemain */}
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border
                        ${player.status === 'Main' ? 'bg-green-500/10 text-green-500 border-green-500/20' : 
                          player.status === 'Cadangan' ? 'bg-blue-500/10 text-blue-500 border-blue-500/20' : 
                          player.status === 'Pemanasan' ? 'bg-accent/10 text-accent border-accent/20' : 
                          player.status.includes('Cedera') || player.status === 'Kartu Merah' ? 'bg-red-500/10 text-red-500 border-red-500/20' : 
                          'bg-background text-text-secondary border-border'}
                      `}>
                        {player.status === 'Kartu Kuning' && <ShieldAlert className="w-3 h-3 text-accent" />}
                        {player.status === 'Kartu Merah' && <ShieldAlert className="w-3 h-3 text-red-500" />}
                        {player.status}
                      </span>
                    </td>
                    <td className="p-4 min-w-[150px]">
                      {/* Bar representasi visual tingkat stamina pemain */}
                      <div className="flex items-center gap-3">
                        <div className="flex-1 bg-background rounded-full h-2 border border-border overflow-hidden">
                          <div 
                            className={`h-full ${player.stamina > 60 ? 'bg-green-500' : player.stamina > 30 ? 'bg-accent' : 'bg-red-500'}`} 
                            style={{ width: `${player.stamina}%` }}
                          ></div>
                        </div>
                        <span className="font-bold text-foreground text-sm w-8">{player.stamina}%</span>
                      </div>
                    </td>
                    <td className="p-4">
                      {/* Tombol aksi Edit dan Hapus */}
                      <div className="flex items-center justify-center gap-2">
                        <button 
                          onClick={() => openEditModal(player)}
                          className="p-2 text-text-secondary hover:text-accent transition-colors bg-background border border-border rounded-lg hover:border-accent cursor-pointer"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button 
                          onClick={() => openDeleteModal(player)}
                          className="p-2 text-text-secondary hover:text-red-500 transition-colors bg-background border border-border rounded-lg hover:border-red-500 cursor-pointer"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-text-secondary">
                    Tidak ada data pemain yang cocok dengan pencarian &quot;{searchQuery}&quot;
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* MODAL DIALOG TAMBAH PEMAIN */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-background/80 backdrop-blur-md" onClick={() => setIsAddModalOpen(false)}></div>
          <div className="relative w-full max-w-lg bg-card border border-border rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200">
            <div className="p-6 border-b border-border flex justify-between items-center bg-card-alt/50">
              <h3 className="text-xl font-bold text-foreground">Tambah Pemain Baru</h3>
              <button onClick={() => setIsAddModalOpen(false)} className="text-text-secondary hover:text-foreground cursor-pointer">
                <X className="w-6 h-6" />
              </button>
            </div>
            <form onSubmit={handleAddSubmit} className="p-6 space-y-4">
              {/* Tampilan pesan kesalahan (jika ada) */}
              {formError && (
                <div className="p-3 bg-red-500/10 border border-red-500/20 text-red-500 rounded-xl text-sm flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 flex-shrink-0" />
                  <span>{formError}</span>
                </div>
              )}
              
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-1 sm:col-span-2">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Nama Pemain</label>
                  <input 
                    type="text" 
                    value={formNama} 
                    onChange={e => setFormNama(e.target.value)} 
                    placeholder="Contoh: Cristiano Ronaldo"
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                    required
                  />
                </div>
                
                <div className="space-y-1">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Nomor Punggung</label>
                  <input 
                    type="number" 
                    value={formNo} 
                    onChange={e => setFormNo(Number(e.target.value))} 
                    min="1"
                    max="99"
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                    required
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Posisi</label>
                  <select 
                    value={formPos} 
                    onChange={e => setFormPos(e.target.value)} 
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                  >
                    <option value="FW">FW (Penyerang)</option>
                    <option value="MF">MF (Gelandang)</option>
                    <option value="DF">DF (Bertahan)</option>
                    <option value="GK">GK (Kiper)</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Status</label>
                  <select 
                    value={formStatus} 
                    onChange={e => setFormStatus(e.target.value)} 
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                  >
                    <option value="Main">Main (Utama)</option>
                    <option value="Cadangan">Cadangan</option>
                    <option value="Pemanasan">Pemanasan</option>
                    <option value="Cedera">Cedera</option>
                    <option value="Kartu Kuning">Kartu Kuning</option>
                    <option value="Kartu Merah">Kartu Merah</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Gol</label>
                  <input 
                    type="number" 
                    value={formGol} 
                    onChange={e => setFormGol(Number(e.target.value))} 
                    min="0"
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                  />
                </div>
              </div>

              {/* Slider Stamina Awal */}
              <div className="space-y-2 pt-2">
                <div className="flex justify-between text-xs font-semibold text-text-secondary uppercase">
                  <span>Stamina Awal</span>
                  <span className="text-accent font-bold">{formStamina}%</span>
                </div>
                <input 
                  type="range" 
                  min="0" 
                  max="100" 
                  value={formStamina} 
                  onChange={e => setFormStamina(Number(e.target.value))}
                  className="w-full h-2 bg-background border border-border rounded-lg appearance-none cursor-pointer accent-accent"
                />
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-border">
                <button 
                  type="button" 
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-5 py-2.5 bg-card-alt border border-border text-text-secondary hover:text-foreground rounded-xl font-bold transition-colors cursor-pointer"
                >
                  Batal
                </button>
                <button 
                  type="submit" 
                  className="px-5 py-2.5 bg-accent text-background font-bold rounded-xl hover:bg-accent/90 transition-colors cursor-pointer"
                >
                  Tambah Pemain
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL DIALOG EDIT PEMAIN */}
      {isEditModalOpen && selectedPlayer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-background/80 backdrop-blur-md" onClick={() => setIsEditModalOpen(false)}></div>
          <div className="relative w-full max-w-lg bg-card border border-border rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200">
            <div className="p-6 border-b border-border flex justify-between items-center bg-card-alt/50">
              <h3 className="text-xl font-bold text-foreground">Edit Pemain: {selectedPlayer.nama}</h3>
              <button onClick={() => setIsEditModalOpen(false)} className="text-text-secondary hover:text-foreground cursor-pointer">
                <X className="w-6 h-6" />
              </button>
            </div>
            <form onSubmit={handleEditSubmit} className="p-6 space-y-4">
              {/* Tampilan pesan kesalahan (jika ada) */}
              {formError && (
                <div className="p-3 bg-red-500/10 border border-red-500/20 text-red-500 rounded-xl text-sm flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 flex-shrink-0" />
                  <span>{formError}</span>
                </div>
              )}
              
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-1 sm:col-span-2">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Nama Pemain</label>
                  <input 
                    type="text" 
                    value={formNama} 
                    onChange={e => setFormNama(e.target.value)} 
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                    required
                  />
                </div>
                
                <div className="space-y-1">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Nomor Punggung</label>
                  <input 
                    type="number" 
                    value={formNo} 
                    onChange={e => setFormNo(Number(e.target.value))} 
                    min="1"
                    max="99"
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                    required
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Posisi</label>
                  <select 
                    value={formPos} 
                    onChange={e => setFormPos(e.target.value)} 
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                  >
                    <option value="FW">FW (Penyerang)</option>
                    <option value="MF">MF (Gelandang)</option>
                    <option value="DF">DF (Bertahan)</option>
                    <option value="GK">GK (Kiper)</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Status</label>
                  <select 
                    value={formStatus} 
                    onChange={e => setFormStatus(e.target.value)} 
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                  >
                    <option value="Main">Main (Utama)</option>
                    <option value="Cadangan">Cadangan</option>
                    <option value="Pemanasan">Pemanasan</option>
                    <option value="Cedera">Cedera</option>
                    <option value="Kartu Kuning">Kartu Kuning</option>
                    <option value="Kartu Merah">Kartu Merah</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-semibold text-text-secondary uppercase">Gol</label>
                  <input 
                    type="number" 
                    value={formGol} 
                    onChange={e => setFormGol(Number(e.target.value))} 
                    min="0"
                    className="w-full bg-background border border-border rounded-xl px-4 py-2 text-foreground focus:border-accent focus:outline-none"
                  />
                </div>
              </div>

              {/* Slider Pengeditan Stamina */}
              <div className="space-y-2 pt-2">
                <div className="flex justify-between text-xs font-semibold text-text-secondary uppercase">
                  <span>Stamina</span>
                  <span className="text-accent font-bold">{formStamina}%</span>
                </div>
                <input 
                  type="range" 
                  min="0" 
                  max="100" 
                  value={formStamina} 
                  onChange={e => setFormStamina(Number(e.target.value))}
                  className="w-full h-2 bg-background border border-border rounded-lg appearance-none cursor-pointer accent-accent"
                />
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-border">
                <button 
                  type="button" 
                  onClick={() => setIsEditModalOpen(false)}
                  className="px-5 py-2.5 bg-card-alt border border-border text-text-secondary hover:text-foreground rounded-xl font-bold transition-colors cursor-pointer"
                >
                  Batal
                </button>
                <button 
                  type="submit" 
                  className="px-5 py-2.5 bg-accent text-background font-bold rounded-xl hover:bg-accent/90 transition-colors cursor-pointer"
                >
                  Simpan Perubahan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL DIALOG KONFIRMASI HAPUS PEMAIN */}
      {isDeleteModalOpen && selectedPlayer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-background/80 backdrop-blur-md" onClick={() => setIsDeleteModalOpen(false)}></div>
          <div className="relative w-full max-w-md bg-card border border-border rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200">
            <div className="p-6 border-b border-border flex justify-between items-center bg-card-alt/50">
              <h3 className="text-xl font-bold text-foreground">Hapus Pemain?</h3>
              <button onClick={() => setIsDeleteModalOpen(false)} className="text-text-secondary hover:text-foreground cursor-pointer">
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6 space-y-6">
              <p className="text-text-secondary text-sm">
                Apakah Anda yakin ingin menghapus pemain <strong className="text-foreground">{selectedPlayer.nama}</strong> (No. {selectedPlayer.no}) dari tim? Tindakan ini tidak dapat dibatalkan.
              </p>
              
              <div className="flex justify-end gap-3">
                <button 
                  type="button" 
                  onClick={() => setIsDeleteModalOpen(false)}
                  className="px-5 py-2.5 bg-card-alt border border-border text-text-secondary hover:text-foreground rounded-xl font-bold transition-colors cursor-pointer"
                >
                  Batal
                </button>
                <button 
                  type="button" 
                  onClick={handleDeleteConfirm}
                  className="px-5 py-2.5 bg-red-500 text-white font-bold rounded-xl hover:bg-red-600 transition-colors cursor-pointer"
                >
                  Hapus Pemain
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

