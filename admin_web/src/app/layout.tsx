// ==========================================================================
// STEMA (Smart Team Estimation and Match Analysis) - Root Layout Web Admin
// File: admin_web/src/app/layout.tsx
// Deskripsi: Layout utama (root layout) aplikasi Next.js untuk Panel Admin.
//            Mengatur font global (Inter), metadata HTML head, dan struktur body utama.
// ==========================================================================

import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

// Menginisialisasi font Inter dari Google Fonts
const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
});

// Menentukan metadata dokumen untuk tab browser (Title dan Deskripsi)
export const metadata: Metadata = {
  title: "STEMA Admin Panel",
  description: "Dashboard Administrasi Sistem Estimasi Stamina",
};

// Layout Pembungkus Utama untuk semua sub-halaman
export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="id" className={`${inter.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col bg-background text-foreground">
        {/* Konten anak (children) di-render di dalam tag body */}
        {children}
      </body>
    </html>
  );
}
