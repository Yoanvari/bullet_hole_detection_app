-- =====================================================================
--  Bullet Hole Detection System - MySQL Database Schema
-- =====================================================================
--  Konteks:
--    * desktop_app : mendeteksi lubang peluru (YOLO) & menghitung skor,
--                    menyimpan foto tembakan, lalu mengirim ke API server.
--    * mobile_app  : dipakai oleh penembak (sipenembak) untuk login,
--                    melihat tembakan secara live, dan melihat riwayat
--                    sesi latihan beserta skornya.
--
--  Engine  : InnoDB (transaksi + foreign key)
--  Charset : utf8mb4
--  MySQL   : 5.7+ / 8.0+
-- =====================================================================

CREATE DATABASE IF NOT EXISTS bullet_detection
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bullet_detection;

SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================================
-- 1. USERS
--    Penembak (sipenembak), instruktur, dan admin.
--    Login mobile_app & operator desktop_app.
-- =====================================================================
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    username        VARCHAR(50)  NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,            -- simpan hash bcrypt
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(120) DEFAULT NULL,
    role            ENUM('shooter','instructor') NOT NULL DEFAULT 'shooter',
    avatar_path     VARCHAR(255) DEFAULT NULL,
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    last_login_at   DATETIME     DEFAULT NULL,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_username (username),
    UNIQUE KEY uq_users_email (email),
    KEY idx_users_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 2. DEVICES
--    Stasiun desktop_app yang menjalankan deteksi (opsional namun
--    berguna untuk multi-lane / multi-komputer).
-- =====================================================================
DROP TABLE IF EXISTS devices;
CREATE TABLE devices (
    id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    device_code   VARCHAR(50)  NOT NULL,              -- mis. "LANE-01"
    device_name   VARCHAR(100) DEFAULT NULL,
    ip_address    VARCHAR(45)  DEFAULT NULL,          -- IPv4/IPv6 server desktop
    location      VARCHAR(120) DEFAULT NULL,
    is_active     TINYINT(1)   NOT NULL DEFAULT 1,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_devices_code (device_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 3. SESSIONS
--    Satu sesi latihan menembak (dikelompokkan per tanggal/penembak).
--    Menyimpan juga data kalibrasi target dari desktop_app.
-- =====================================================================
DROP TABLE IF EXISTS sessions;
CREATE TABLE sessions (
    id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    shooter_id       BIGINT UNSIGNED NOT NULL,        -- penembak (users.role='shooter')
    instructor_id    BIGINT UNSIGNED DEFAULT NULL,    -- pengawas (opsional)
    device_id        BIGINT UNSIGNED DEFAULT NULL,    -- stasiun desktop yang dipakai
    title            VARCHAR(120) DEFAULT NULL,        -- mis. "Latihan Pagi"
    target_distance  SMALLINT UNSIGNED DEFAULT NULL,   -- jarak target (meter)
    status           ENUM('ongoing','completed','cancelled') NOT NULL DEFAULT 'ongoing',

    -- Data kalibrasi target (dari proses warping/elips di desktop_app)
    is_calibrated    TINYINT(1)   NOT NULL DEFAULT 0,
    target_center_x  FLOAT        DEFAULT NULL,
    target_center_y  FLOAT        DEFAULT NULL,
    target_radius    FLOAT        DEFAULT NULL,

    started_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at         DATETIME     DEFAULT NULL,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_sessions_shooter (shooter_id),
    KEY idx_sessions_instructor (instructor_id),
    KEY idx_sessions_device (device_id),
    KEY idx_sessions_status (status),
    KEY idx_sessions_started (started_at),
    CONSTRAINT fk_sessions_shooter
        FOREIGN KEY (shooter_id)    REFERENCES users (id)   ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_sessions_instructor
        FOREIGN KEY (instructor_id) REFERENCES users (id)   ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_sessions_device
        FOREIGN KEY (device_id)     REFERENCES devices (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 4. SHOTS
--    Setiap tembakan / lubang peluru yang terdeteksi.
--    score 0-10 dihitung desktop_app (calculate_score_circle).
--    image_path = lokasi file di server desktop,
--    image_url  = URL yang diakses mobile_app.
-- =====================================================================
DROP TABLE IF EXISTS shots;
CREATE TABLE shots (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    session_id          BIGINT UNSIGNED NOT NULL,
    shot_number         INT UNSIGNED DEFAULT NULL,    -- urutan tembakan dalam sesi
    score               TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- 0..10

    -- Koordinat lubang relatif ke pusat target (hasil deteksi)
    hole_x              FLOAT  DEFAULT NULL,
    hole_y              FLOAT  DEFAULT NULL,
    distance_from_center FLOAT DEFAULT NULL,          -- jarak (px) dari pusat
    confidence          FLOAT  DEFAULT NULL,          -- confidence YOLO (0..1)

    -- Penyimpanan gambar
    image_filename      VARCHAR(255) DEFAULT NULL,    -- mis. shot_1777102404.jpg
    image_path          VARCHAR(512) DEFAULT NULL,    -- path lokal di desktop
    image_url           VARCHAR(512) DEFAULT NULL,    -- URL untuk mobile_app

    captured_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_shots_session (session_id),
    KEY idx_shots_captured (captured_at),
    CONSTRAINT fk_shots_session
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_shots_score CHECK (score BETWEEN 0 AND 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 5. VIEW: ringkasan sesi (total tembakan & total skor)
--    Memudahkan mobile_app menampilkan riwayat tanpa hitung manual.
-- =====================================================================
DROP VIEW IF EXISTS v_session_summary;
CREATE VIEW v_session_summary AS
SELECT
    s.id                AS session_id,
    s.shooter_id,
    u.full_name         AS shooter_name,
    s.title,
    s.status,
    s.started_at,
    s.ended_at,
    COUNT(sh.id)        AS total_shots,
    COALESCE(SUM(sh.score), 0)  AS total_score,
    ROUND(COALESCE(AVG(sh.score), 0), 2) AS avg_score
FROM sessions s
JOIN users u        ON u.id = s.shooter_id
LEFT JOIN shots sh  ON sh.session_id = s.id
GROUP BY s.id, s.shooter_id, u.full_name, s.title, s.status, s.started_at, s.ended_at;

-- =====================================================================
-- 6. DATA CONTOH (opsional - hapus jika tidak diperlukan)
-- =====================================================================
-- Password di bawah hanyalah placeholder; ganti dengan hash asli.
-- INSERT INTO users (username, password_hash, full_name, role) VALUES
--     ('admin',   '$2y$10$placeholderhashadminxxxxxxxxxxxxxxxxxxxxxxx', 'Administrator', 'admin'),
--     ('budi',    '$2y$10$placeholderhashbudixxxxxxxxxxxxxxxxxxxxxxxx', 'Budi Santoso',  'shooter'),
--     ('andi',    '$2y$10$placeholderhashandixxxxxxxxxxxxxxxxxxxxxxxx', 'Andi Pratama',  'instructor');

-- INSERT INTO devices (device_code, device_name, ip_address, location) VALUES
--     ('LANE-01', 'Stasiun Deteksi 1', '192.168.100.23', 'Lapangan A');

-- INSERT INTO sessions (shooter_id, instructor_id, device_id, title, target_distance, status, is_calibrated, started_at, ended_at)
-- VALUES (2, 3, 1, 'Latihan Pagi', 25, 'completed', 1, '2026-05-09 08:00:00', '2026-05-09 08:30:00');

-- INSERT INTO shots (session_id, shot_number, score, image_filename, image_url, captured_at) VALUES
--     (1, 1, 9,  'shot_1777102404.jpg', 'http://192.168.100.23:8000/static/shots/shot_1777102404.jpg', '2026-05-09 08:05:00'),
--     (1, 2, 8,  'shot_1777102480.jpg', 'http://192.168.100.23:8000/static/shots/shot_1777102480.jpg', '2026-05-09 08:06:20'),
--     (1, 3, 10, 'shot_1777102513.jpg', 'http://192.168.100.23:8000/static/shots/shot_1777102513.jpg', '2026-05-09 08:06:53'),
--     (1, 4, 7,  'shot_1777102536.jpg', 'http://192.168.100.23:8000/static/shots/shot_1777102536.jpg', '2026-05-09 08:07:16');
