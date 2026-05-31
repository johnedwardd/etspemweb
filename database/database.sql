-- ============================================================
--  STEPX - Sistem Penjualan Sepatu
--  Database: MySQL 8.0+
--  Dibuat: 2025
-- ============================================================

CREATE DATABASE IF NOT EXISTS stepx_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE stepx_db;

-- ============================================================
-- 1. TABEL USERS (Pembeli & Penjual)
-- ============================================================
CREATE TABLE users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama          VARCHAR(100)  NOT NULL,
  email         VARCHAR(150)  NOT NULL UNIQUE,
  password_hash VARCHAR(255)  NOT NULL,
  no_hp         VARCHAR(20),
  role          ENUM('pembeli', 'penjual', 'admin') NOT NULL DEFAULT 'pembeli',
  status        ENUM('aktif', 'nonaktif', 'banned')  NOT NULL DEFAULT 'aktif',
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. TABEL ALAMAT PEMBELI
-- ============================================================
CREATE TABLE alamat_pembeli (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id      INT UNSIGNED NOT NULL,
  label        VARCHAR(50)  NOT NULL DEFAULT 'Rumah',   -- 'Rumah', 'Kantor', dll
  nama_penerima VARCHAR(100) NOT NULL,
  no_hp        VARCHAR(20)  NOT NULL,
  provinsi     VARCHAR(100) NOT NULL,
  kota         VARCHAR(100) NOT NULL,
  kecamatan    VARCHAR(100),
  kode_pos     VARCHAR(10),
  alamat_lengkap TEXT        NOT NULL,
  is_utama     TINYINT(1)   NOT NULL DEFAULT 0  ,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_alamat_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- 3. TABEL PROFIL PENJUAL
-- ============================================================
CREATE TABLE profil_penjual (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id       INT UNSIGNED NOT NULL UNIQUE,
  nama_toko     VARCHAR(150) NOT NULL,
  deskripsi     TEXT,
  logo_url      VARCHAR(255),
  provinsi      VARCHAR(100),
  kota          VARCHAR(100),
  alamat_toko   TEXT,
  no_rekening   VARCHAR(50),
  nama_bank     VARCHAR(50),
  atas_nama     VARCHAR(100),
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_profil_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- 4. TABEL KATEGORI PRODUK
-- ============================================================
CREATE TABLE kategori (
  id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama  VARCHAR(100) NOT NULL UNIQUE,
  slug  VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================================
-- 5. TABEL PRODUK (Sepatu)
-- ============================================================
CREATE TABLE produk (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  penjual_id   INT UNSIGNED NOT NULL,
  kategori_id  INT UNSIGNED NOT NULL,
  nama         VARCHAR(200) NOT NULL,
  brand        VARCHAR(100) NOT NULL,
  deskripsi    TEXT,
  harga_jual   DECIMAL(12,2) NOT NULL,
  hpp          DECIMAL(12,2) NOT NULL COMMENT 'Harga Pokok Penjualan / Modal',
  stok         INT          NOT NULL DEFAULT 0,
  berat_gram   INT          NOT NULL DEFAULT 500,
  emoji        VARCHAR(10)  DEFAULT '👟',
  is_new       TINYINT(1)   NOT NULL DEFAULT 0,
  status       ENUM('aktif', 'nonaktif', 'habis') NOT NULL DEFAULT 'aktif',
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_produk_penjual  FOREIGN KEY (penjual_id)  REFERENCES users(id),
  CONSTRAINT fk_produk_kategori FOREIGN KEY (kategori_id) REFERENCES kategori(id),
  CONSTRAINT chk_harga          CHECK (harga_jual > 0),
  CONSTRAINT chk_hpp             CHECK (hpp > 0),
  CONSTRAINT chk_stok            CHECK (stok >= 0)
);

-- ============================================================
-- 6. TABEL UKURAN PRODUK
-- ============================================================
CREATE TABLE produk_ukuran (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  produk_id  INT UNSIGNED NOT NULL,
  ukuran     VARCHAR(10)  NOT NULL,   -- '38', '39', '40', '41', '42', dst
  stok       INT          NOT NULL DEFAULT 0,
  CONSTRAINT fk_ukuran_produk FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE CASCADE,
  CONSTRAINT uq_produk_ukuran UNIQUE (produk_id, ukuran)
);

-- ============================================================
-- 7. TABEL GAMBAR PRODUK
-- ============================================================
CREATE TABLE produk_gambar (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  produk_id  INT UNSIGNED NOT NULL,
  url        VARCHAR(255) NOT NULL,
  urutan     INT          NOT NULL DEFAULT 1,
  CONSTRAINT fk_gambar_produk FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE CASCADE
);

-- ============================================================
-- 8. TABEL KERANJANG
-- ============================================================
CREATE TABLE keranjang (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  produk_id  INT UNSIGNED NOT NULL,
  ukuran     VARCHAR(10),
  qty        INT          NOT NULL DEFAULT 1,
  added_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_keranjang_user   FOREIGN KEY (user_id)   REFERENCES users(id)  ON DELETE CASCADE,
  CONSTRAINT fk_keranjang_produk FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE CASCADE,
  CONSTRAINT uq_keranjang        UNIQUE (user_id, produk_id, ukuran)
);

-- ============================================================
-- 9. TABEL PESANAN (Header)
-- ============================================================
CREATE TABLE pesanan (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  kode_pesanan    VARCHAR(20)   NOT NULL UNIQUE,
  pembeli_id      INT UNSIGNED  NOT NULL,
  alamat_id       INT UNSIGNED  NOT NULL,
  subtotal        DECIMAL(12,2) NOT NULL,
  ongkos_kirim    DECIMAL(10,2) NOT NULL DEFAULT 0,
  diskon          DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_bayar     DECIMAL(12,2) NOT NULL,
  metode_bayar    ENUM('transfer_bank','cod','ewallet','kartu_kredit') NOT NULL,
  status_bayar    ENUM('menunggu','lunas','gagal','refund')             NOT NULL DEFAULT 'menunggu',
  status_pesanan  ENUM('proses','dikemas','dikirim','selesai','dibatalkan') NOT NULL DEFAULT 'proses',
  catatan         TEXT,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pesanan_pembeli FOREIGN KEY (pembeli_id) REFERENCES users(id),
  CONSTRAINT fk_pesanan_alamat  FOREIGN KEY (alamat_id)  REFERENCES alamat_pembeli(id)
);

-- ============================================================
-- 10. TABEL DETAIL PESANAN (Item per Pesanan)
-- ============================================================
CREATE TABLE detail_pesanan (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pesanan_id      INT UNSIGNED  NOT NULL,
  produk_id       INT UNSIGNED  NOT NULL,
  penjual_id      INT UNSIGNED  NOT NULL,
  nama_produk     VARCHAR(200)  NOT NULL COMMENT 'Snapshot nama saat order',
  harga_satuan    DECIMAL(12,2) NOT NULL COMMENT 'Snapshot harga saat order',
  hpp_satuan      DECIMAL(12,2) NOT NULL COMMENT 'Snapshot HPP saat order',
  ukuran          VARCHAR(10),
  qty             INT           NOT NULL DEFAULT 1,
  subtotal        DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_detail_pesanan  FOREIGN KEY (pesanan_id) REFERENCES pesanan(id) ON DELETE CASCADE,
  CONSTRAINT fk_detail_produk   FOREIGN KEY (produk_id)  REFERENCES produk(id),
  CONSTRAINT fk_detail_penjual  FOREIGN KEY (penjual_id) REFERENCES users(id)
);

-- ============================================================
-- 11. TABEL BIAYA OPERASIONAL (untuk hitung Laba Neto)
-- ============================================================
CREATE TABLE biaya_operasional (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  penjual_id  INT UNSIGNED  NOT NULL,
  nama_biaya  VARCHAR(100)  NOT NULL,   -- 'Sewa Toko', 'Gaji', 'Listrik', dst
  nominal     DECIMAL(12,2) NOT NULL,
  bulan       TINYINT       NOT NULL CHECK (bulan BETWEEN 1 AND 12),
  tahun       YEAR          NOT NULL,
  keterangan  TEXT,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_biaya_penjual FOREIGN KEY (penjual_id) REFERENCES users(id)
);

-- ============================================================
-- 12. TABEL ULASAN PRODUK
-- ============================================================
CREATE TABLE ulasan (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  produk_id  INT UNSIGNED NOT NULL,
  user_id    INT UNSIGNED NOT NULL,
  pesanan_id INT UNSIGNED NOT NULL,
  rating     TINYINT      NOT NULL CHECK (rating BETWEEN 1 AND 5),
  komentar   TEXT,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ulasan_produk  FOREIGN KEY (produk_id)  REFERENCES produk(id),
  CONSTRAINT fk_ulasan_user    FOREIGN KEY (user_id)    REFERENCES users(id),
  CONSTRAINT fk_ulasan_pesanan FOREIGN KEY (pesanan_id) REFERENCES pesanan(id),
  CONSTRAINT uq_ulasan         UNIQUE (user_id, produk_id, pesanan_id)
);

-- ============================================================
-- 13. TABEL RIWAYAT STATUS PESANAN (Tracking)
-- ============================================================
CREATE TABLE riwayat_status_pesanan (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pesanan_id INT UNSIGNED NOT NULL,
  status     VARCHAR(50)  NOT NULL,
  keterangan TEXT,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_riwayat_pesanan FOREIGN KEY (pesanan_id) REFERENCES pesanan(id) ON DELETE CASCADE
);

-- ============================================================
-- INDEXES untuk performa query
-- ============================================================
CREATE INDEX idx_produk_kategori  ON produk(kategori_id);
CREATE INDEX idx_produk_penjual   ON produk(penjual_id);
CREATE INDEX idx_produk_status    ON produk(status);
CREATE INDEX idx_pesanan_pembeli  ON pesanan(pembeli_id);
CREATE INDEX idx_pesanan_status   ON pesanan(status_pesanan);
CREATE INDEX idx_pesanan_tanggal  ON pesanan(created_at);
CREATE INDEX idx_detail_penjual   ON detail_pesanan(penjual_id);
CREATE INDEX idx_detail_pesanan   ON detail_pesanan(pesanan_id);
CREATE INDEX idx_biaya_bulan_thn  ON biaya_operasional(penjual_id, tahun, bulan);

-- ============================================================
-- VIEW: LAPORAN LABA BULANAN PER PENJUAL
-- ============================================================
CREATE OR REPLACE VIEW v_laporan_laba_bulanan AS
SELECT
  dp.penjual_id,
  u.nama                                              AS nama_penjual,
  YEAR(p.created_at)                                  AS tahun,
  MONTH(p.created_at)                                 AS bulan,
  MONTHNAME(p.created_at)                             AS nama_bulan,
  COUNT(DISTINCT p.id)                                AS jumlah_transaksi,
  SUM(dp.qty)                                         AS unit_terjual,
  SUM(dp.subtotal)                                    AS pendapatan,
  SUM(dp.hpp_satuan * dp.qty)                         AS total_hpp,
  SUM(dp.subtotal) - SUM(dp.hpp_satuan * dp.qty)      AS laba_bruto,
  COALESCE((
    SELECT SUM(bo.nominal)
    FROM biaya_operasional bo
    WHERE bo.penjual_id  = dp.penjual_id
      AND bo.tahun       = YEAR(p.created_at)
      AND bo.bulan       = MONTH(p.created_at)
  ), 0)                                               AS biaya_operasional,
  (SUM(dp.subtotal) - SUM(dp.hpp_satuan * dp.qty)) -
  COALESCE((
    SELECT SUM(bo.nominal)
    FROM biaya_operasional bo
    WHERE bo.penjual_id  = dp.penjual_id
      AND bo.tahun       = YEAR(p.created_at)
      AND bo.bulan       = MONTH(p.created_at)
  ), 0)                                               AS laba_neto,
  ROUND(
    ((SUM(dp.subtotal) - SUM(dp.hpp_satuan * dp.qty)) / NULLIF(SUM(dp.subtotal), 0)) * 100, 2
  )                                                   AS margin_bruto_pct
FROM detail_pesanan dp
JOIN pesanan p ON p.id = dp.pesanan_id
JOIN users   u ON u.id = dp.penjual_id
WHERE p.status_pesanan IN ('selesai', 'dikirim')
GROUP BY dp.penjual_id, u.nama, YEAR(p.created_at), MONTH(p.created_at), MONTHNAME(p.created_at)
ORDER BY tahun DESC, bulan DESC;

-- ============================================================
-- VIEW: PRODUK TERLARIS
-- ============================================================
CREATE OR REPLACE VIEW v_produk_terlaris AS
SELECT
  dp.produk_id,
  dp.nama_produk,
  dp.penjual_id,
  pr.brand,
  k.nama                        AS kategori,
  SUM(dp.qty)                   AS total_terjual,
  SUM(dp.subtotal)              AS total_pendapatan,
  SUM(dp.hpp_satuan * dp.qty)   AS total_hpp,
  SUM(dp.subtotal) - SUM(dp.hpp_satuan * dp.qty) AS total_laba_bruto,
  ROUND(
    ((SUM(dp.subtotal) - SUM(dp.hpp_satuan * dp.qty)) / NULLIF(SUM(dp.subtotal), 0)) * 100, 2
  )                             AS margin_pct
FROM detail_pesanan dp
JOIN pesanan p ON p.id = dp.pesanan_id AND p.status_pesanan IN ('selesai','dikirim')
JOIN produk  pr ON pr.id = dp.produk_id
JOIN kategori k ON k.id  = pr.kategori_id
GROUP BY dp.produk_id, dp.nama_produk, dp.penjual_id, pr.brand, k.nama
ORDER BY total_terjual DESC;

-- ============================================================
-- VIEW: DATABASE PELANGGAN + SEGMENTASI
-- ============================================================
CREATE OR REPLACE VIEW v_database_pelanggan AS
SELECT
  u.id,
  u.nama,
  u.email,
  u.no_hp,
  COUNT(p.id)           AS total_transaksi,
  SUM(p.total_bayar)    AS total_belanja,
  MAX(p.created_at)     AS terakhir_belanja,
  CASE
    WHEN SUM(p.total_bayar) >= 5000000  THEN 'VIP'
    WHEN COUNT(p.id) >= 3               THEN 'Regular'
    ELSE 'Baru'
  END                   AS segmen_pelanggan
FROM users u
LEFT JOIN pesanan p ON p.pembeli_id = u.id AND p.status_pesanan != 'dibatalkan'
WHERE u.role = 'pembeli'
GROUP BY u.id, u.nama, u.email, u.no_hp;

-- ============================================================
-- VIEW: STOK PRODUK & MARGIN
-- ============================================================
CREATE OR REPLACE VIEW v_stok_margin AS
SELECT
  pr.id,
  pr.nama,
  pr.brand,
  k.nama               AS kategori,
  pr.harga_jual,
  pr.hpp,
  pr.stok,
  pr.harga_jual - pr.hpp AS laba_per_unit,
  ROUND(((pr.harga_jual - pr.hpp) / pr.harga_jual) * 100, 2) AS margin_pct,
  CASE
    WHEN pr.stok = 0        THEN 'Habis'
    WHEN pr.stok <= 5       THEN 'Kritis'
    WHEN pr.stok <= 15      THEN 'Rendah'
    ELSE 'Aman'
  END                  AS status_stok
FROM produk pr
JOIN kategori k ON k.id = pr.kategori_id
WHERE pr.status != 'nonaktif'
ORDER BY pr.stok ASC;

-- ============================================================
-- SEED DATA
-- ============================================================

-- Kategori
INSERT INTO kategori (nama, slug) VALUES
  ('Running',  'running'),
  ('Casual',   'casual'),
  ('Formal',   'formal'),
  ('Sport',    'sport');

-- Users (password_hash = bcrypt dari "password123")
INSERT INTO users (nama, email, password_hash, no_hp, role) VALUES
  ('Admin StepX',    'admin@stepx.id',       '$2b$12$examplehash001', '081200000001', 'admin'),
  ('Toko StepX',     'penjual@stepx.id',     '$2b$12$examplehash002', '081200000002', 'penjual'),
  ('Rizky Pratama',  'rizky@gmail.com',       '$2b$12$examplehash003', '081211111111', 'pembeli'),
  ('Sari Dewi',      'sari@gmail.com',        '$2b$12$examplehash004', '081222222222', 'pembeli'),
  ('Budi Santoso',   'budi@gmail.com',        '$2b$12$examplehash005', '081233333333', 'pembeli'),
  ('Eka Putri',      'eka@gmail.com',         '$2b$12$examplehash006', '081244444444', 'pembeli'),
  ('Ahmad Fauzi',    'ahmad@gmail.com',       '$2b$12$examplehash007', '081255555555', 'pembeli'),
  ('Nining Wahyu',   'nining@gmail.com',      '$2b$12$examplehash008', '081266666666', 'pembeli'),
  ('Dani Kurnia',    'dani@gmail.com',        '$2b$12$examplehash009', '081277777777', 'pembeli');

-- Profil Penjual
INSERT INTO profil_penjual (user_id, nama_toko, deskripsi, provinsi, kota, no_rekening, nama_bank, atas_nama) VALUES
  (2, 'StepX Official', 'Toko sepatu premium terpercaya sejak 2020', 'Jawa Timur', 'Surabaya', '1234567890', 'BCA', 'Toko StepX');

-- Alamat Pembeli
INSERT INTO alamat_pembeli (user_id, label, nama_penerima, no_hp, provinsi, kota, kode_pos, alamat_lengkap, is_utama) VALUES
  (3, 'Rumah',  'Rizky Pratama', '081211111111', 'Jawa Timur',   'Surabaya',   '60111', 'Jl. Pahlawan No. 12, RT 03/04',  1),
  (4, 'Rumah',  'Sari Dewi',     '081222222222', 'Jawa Timur',   'Malang',     '65112', 'Jl. Semeru No. 45, RT 01/02',    1),
  (5, 'Rumah',  'Budi Santoso',  '081233333333', 'Jawa Tengah',  'Semarang',   '50131', 'Jl. Pandanaran No. 8, Blok B',   1),
  (6, 'Kantor', 'Eka Putri',     '081244444444', 'DKI Jakarta',  'Jakarta Selatan', '12950', 'Jl. Sudirman Kav 22, Lt 5', 1),
  (7, 'Rumah',  'Ahmad Fauzi',   '081255555555', 'Jawa Barat',   'Bandung',    '40111', 'Jl. Dago No. 99, RT 07/08',      1),
  (8, 'Rumah',  'Nining Wahyu',  '081266666666', 'D.I. Yogyakarta','Yogyakarta','55111', 'Jl. Malioboro No. 14',           1),
  (9, 'Rumah',  'Dani Kurnia',   '081277777777', 'Jawa Timur',   'Sidoarjo',   '61212', 'Perum Graha Natura Blok C-5',    1);

-- Produk
INSERT INTO produk (penjual_id, kategori_id, nama, brand, harga_jual, hpp, stok, emoji, is_new) VALUES
  (2, 1, 'Air Max 270',         'Nike',     1350000,  750000, 24, '👟', 1),
  (2, 1, 'Ultra Boost 22',      'Adidas',   1750000,  950000, 15, '🏃', 0),
  (2, 2, 'Old Skool Classic',   'Vans',      650000,  320000, 38, '🥿', 0),
  (2, 2, 'Chuck Taylor All Star','Converse',  550000,  270000, 45, '👞', 0),
  (2, 3, 'Oxford Brogue',       'Clarks',    980000,  520000, 12, '🥾', 0),
  (2, 1, 'Gel-Kayano 29',       'Asics',    1580000,  880000,  8, '👟', 1),
  (2, 1, 'Pegasus 39',          'Nike',     1250000,  680000, 30, '👟', 0),
  (2, 2, 'Handball Spezial',    'Adidas',   1100000,  580000,  5, '👟', 1),
  (2, 2, 'Suede Classic',       'Puma',      720000,  380000, 20, '🥿', 0),
  (2, 4, 'Pro Court',           'Puma',      420000,  200000, 50, '🏓', 0),
  (2, 2, 'Slip-On Pro',         'Vans',      580000,  290000,  3, '🥿', 0),
  (2, 3, 'Loafer Derby',        'Ecco',     1450000,  800000,  9, '👞', 1);

-- Ukuran Produk (contoh untuk produk 1)
INSERT INTO produk_ukuran (produk_id, ukuran, stok) VALUES
  (1,'38',3),(1,'39',5),(1,'40',6),(1,'41',5),(1,'42',4),(1,'43',1),
  (2,'39',3),(2,'40',4),(2,'41',5),(2,'42',2),(2,'43',1),
  (3,'37',5),(3,'38',8),(3,'39',9),(3,'40',8),(3,'41',5),(3,'42',3);

-- Biaya Operasional (Jan–Jun 2025)
INSERT INTO biaya_operasional (penjual_id, nama_biaya, nominal, bulan, tahun) VALUES
  (2, 'Sewa Toko',       1500000, 1, 2025), (2, 'Gaji Karyawan', 800000, 1, 2025), (2, 'Listrik & Air', 300000, 1, 2025), (2, 'Marketing',     200000, 1, 2025),
  (2, 'Sewa Toko',       1500000, 2, 2025), (2, 'Gaji Karyawan', 800000, 2, 2025), (2, 'Listrik & Air', 300000, 2, 2025), (2, 'Marketing',     300000, 2, 2025),
  (2, 'Sewa Toko',       1500000, 3, 2025), (2, 'Gaji Karyawan', 800000, 3, 2025), (2, 'Listrik & Air', 250000, 3, 2025), (2, 'Marketing',     200000, 3, 2025),
  (2, 'Sewa Toko',       1500000, 4, 2025), (2, 'Gaji Karyawan', 900000, 4, 2025), (2, 'Listrik & Air', 350000, 4, 2025), (2, 'Marketing',     350000, 4, 2025),
  (2, 'Sewa Toko',       1500000, 5, 2025), (2, 'Gaji Karyawan', 900000, 5, 2025), (2, 'Listrik & Air', 400000, 5, 2025), (2, 'Marketing',     600000, 5, 2025),
  (2, 'Sewa Toko',       1500000, 6, 2025), (2, 'Gaji Karyawan', 900000, 6, 2025), (2, 'Listrik & Air', 350000, 6, 2025), (2, 'Marketing',     450000, 6, 2025);

-- Pesanan & Detail Pesanan
INSERT INTO pesanan (kode_pesanan, pembeli_id, alamat_id, subtotal, ongkos_kirim, diskon, total_bayar, metode_bayar, status_bayar, status_pesanan) VALUES
  ('#ORD-001', 3, 1, 1350000, 15000, 0,     1365000, 'transfer_bank', 'lunas',     'selesai'),
  ('#ORD-002', 4, 2, 3500000, 20000, 175000,3345000, 'ewallet',       'lunas',     'dikirim'),
  ('#ORD-003', 5, 3,  650000, 15000, 0,      665000, 'cod',           'lunas',     'selesai'),
  ('#ORD-004', 6, 4,  980000, 15000, 0,      995000, 'transfer_bank', 'menunggu',  'proses'),
  ('#ORD-005', 7, 5, 1580000, 20000, 0,     1600000, 'transfer_bank', 'lunas',     'selesai'),
  ('#ORD-006', 8, 6, 1100000, 15000, 0,     1115000, 'ewallet',       'lunas',     'dikirim'),
  ('#ORD-007', 9, 7, 1250000, 15000, 0,     1265000, 'transfer_bank', 'menunggu',  'proses');

INSERT INTO detail_pesanan (pesanan_id, produk_id, penjual_id, nama_produk, harga_satuan, hpp_satuan, ukuran, qty, subtotal) VALUES
  (1, 1,  2, 'Air Max 270',          1350000, 750000, '41', 1, 1350000),
  (2, 2,  2, 'Ultra Boost 22',       1750000, 950000, '42', 2, 3500000),
  (3, 3,  2, 'Old Skool Classic',     650000, 320000, '40', 1,  650000),
  (4, 5,  2, 'Oxford Brogue',         980000, 520000, '43', 1,  980000),
  (5, 6,  2, 'Gel-Kayano 29',        1580000, 880000, '40', 1, 1580000),
  (6, 4,  2, 'Chuck Taylor All Star',  550000, 270000, '39', 2, 1100000),
  (7, 7,  2, 'Pegasus 39',           1250000, 680000, '41', 1, 1250000);

-- Riwayat Status Pesanan
INSERT INTO riwayat_status_pesanan (pesanan_id, status, keterangan) VALUES
  (1, 'proses',    'Pesanan diterima, sedang dikemas'),
  (1, 'dikirim',   'Paket dikirim via JNE, no resi: JNE123456'),
  (1, 'selesai',   'Pesanan diterima pembeli'),
  (2, 'proses',    'Pesanan diterima, sedang dikemas'),
  (2, 'dikirim',   'Paket dikirim via SiCepat, no resi: SCP789012'),
  (3, 'proses',    'Pesanan diterima, COD dijadwalkan'),
  (3, 'selesai',   'Pembayaran COD diterima'),
  (5, 'proses',    'Pesanan diterima, sedang dikemas'),
  (5, 'dikirim',   'Paket dikirim via AnterAja, no resi: AA345678'),
  (5, 'selesai',   'Pesanan diterima pembeli');

-- Ulasan
INSERT INTO ulasan (produk_id, user_id, pesanan_id, rating, komentar) VALUES
  (1, 3, 1, 5, 'Sepatu sangat nyaman dipakai, ukuran pas. Pengiriman cepat!'),
  (3, 5, 3, 4, 'Kualitas bagus, sesuai gambar. Tapi pengiriman agak lama.'),
  (6, 7, 5, 5, 'Mantap banget, cocok buat lari pagi. Recommended!');

-- ============================================================
-- CONTOH QUERY BERGUNA
-- ============================================================

-- Laporan laba bulan Juni 2025:
-- SELECT * FROM v_laporan_laba_bulanan WHERE tahun = 2025 AND bulan = 6;

-- Top 5 produk terlaris:
-- SELECT * FROM v_produk_terlaris LIMIT 5;

-- Database pelanggan + segmen:
-- SELECT * FROM v_database_pelanggan ORDER BY total_belanja DESC;

-- Stok produk kritis:
-- SELECT * FROM v_stok_margin WHERE status_stok IN ('Habis','Kritis');

-- Semua pesanan beserta detail:
-- SELECT p.kode_pesanan, u.nama AS pembeli, p.total_bayar, p.status_pesanan, p.created_at
-- FROM pesanan p JOIN users u ON u.id = p.pembeli_id
-- ORDER BY p.created_at DESC;
