-- Chạy toàn bộ script trong SQL Server Management Studio (SSMS).
USE [master];
GO

IF DB_ID(N'quan_ly_khach_san') IS NULL
    EXEC (N'CREATE DATABASE [quan_ly_khach_san];');
GO

USE [quan_ly_khach_san];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;

-- Giữ nguyên dữ liệu nếu một trong các bảng đích đã tồn tại.
IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE schema_id = SCHEMA_ID(N'dbo')
      AND name IN (
          N'tai_khoan', N'loai_phong', N'dich_vu', N'khach_hang',
          N'phong', N'dat_phong', N'hoa_don', N'su_dung_dich_vu'
      )
)
BEGIN
    PRINT N'Bỏ qua nhập dữ liệu vì cơ sở dữ liệu đã có đối tượng trùng tên.';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Biên dịch phần nhập sau khi đã kiểm tra các bảng đích.
    EXEC sys.sp_executesql N'
CREATE TABLE dbo.tai_khoan (
    id int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_tai_khoan PRIMARY KEY,
    ten_dang_nhap nvarchar(50) NOT NULL CONSTRAINT UQ_tai_khoan_ten_dang_nhap UNIQUE,
    mat_khau nvarchar(255) NOT NULL,
    vai_tro nvarchar(20) NOT NULL
);

CREATE TABLE dbo.loai_phong (
    ma_lp int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_loai_phong PRIMARY KEY,
    ten_lp nvarchar(50) NOT NULL,
    don_gia decimal(15, 0) NOT NULL
);

CREATE TABLE dbo.dich_vu (
    ma_dv int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_dich_vu PRIMARY KEY,
    ten_dv nvarchar(100) NOT NULL,
    don_gia decimal(15, 0) NOT NULL
);

CREATE TABLE dbo.khach_hang (
    ma_kh int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_khach_hang PRIMARY KEY,
    ho_ten nvarchar(100) NOT NULL,
    cccd nvarchar(12) NULL,
    so_dt nvarchar(15) NULL,
    dia_chi nvarchar(255) NULL,
    tai_khoan_id int NULL,
    CONSTRAINT khach_hang_ibfk_1 FOREIGN KEY (tai_khoan_id) REFERENCES dbo.tai_khoan (id)
);

CREATE TABLE dbo.phong (
    ma_p int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_phong PRIMARY KEY,
    so_phong nvarchar(10) NOT NULL CONSTRAINT UQ_phong_so_phong UNIQUE,
    mo_ta nvarchar(255) NULL,
    hinh_anh nvarchar(max) NULL,
    trang_thai nvarchar(30) NULL CONSTRAINT DF_phong_trang_thai DEFAULT (N''Trống''),
    ma_lp int NULL,
    CONSTRAINT phong_ibfk_1 FOREIGN KEY (ma_lp) REFERENCES dbo.loai_phong (ma_lp)
);

CREATE TABLE dbo.dat_phong (
    ma_dp int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_dat_phong PRIMARY KEY,
    so_nguoi int NOT NULL,
    ngay_bat_dau datetime2(0) NOT NULL,
    ngay_ket_thuc datetime2(0) NOT NULL,
    tien_dat_coc decimal(15, 0) NULL CONSTRAINT DF_dat_phong_tien_dat_coc DEFAULT (0),
    trang_thai_tt nvarchar(30) NULL CONSTRAINT DF_dat_phong_trang_thai_tt DEFAULT (N''Chưa trả''),
    ma_kh int NULL,
    ma_p int NULL,
    CONSTRAINT dat_phong_ibfk_1 FOREIGN KEY (ma_kh) REFERENCES dbo.khach_hang (ma_kh),
    CONSTRAINT dat_phong_ibfk_2 FOREIGN KEY (ma_p) REFERENCES dbo.phong (ma_p)
);

CREATE TABLE dbo.hoa_don (
    ma_hd int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_hoa_don PRIMARY KEY,
    ngay_lap datetime2(0) NULL CONSTRAINT DF_hoa_don_ngay_lap DEFAULT (CURRENT_TIMESTAMP),
    tong_tien decimal(15, 0) NOT NULL,
    ma_dp int NULL,
    CONSTRAINT hoa_don_ibfk_1 FOREIGN KEY (ma_dp) REFERENCES dbo.dat_phong (ma_dp)
);

CREATE TABLE dbo.su_dung_dich_vu (
    ma_sddv int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_su_dung_dich_vu PRIMARY KEY,
    so_luong int NOT NULL,
    ngay_dat datetime2(0) NULL CONSTRAINT DF_su_dung_dich_vu_ngay_dat DEFAULT (CURRENT_TIMESTAMP),
    ma_dp int NULL,
    ma_dv int NULL,
    CONSTRAINT su_dung_dich_vu_ibfk_1 FOREIGN KEY (ma_dp) REFERENCES dbo.dat_phong (ma_dp),
    CONSTRAINT su_dung_dich_vu_ibfk_2 FOREIGN KEY (ma_dv) REFERENCES dbo.dich_vu (ma_dv)
);

-- CCCD phải duy nhất khi có giá trị. Nhiều khách hàng có thể để NULL.
CREATE UNIQUE INDEX UX_khach_hang_cccd ON dbo.khach_hang (cccd) WHERE cccd IS NOT NULL;
CREATE INDEX IX_khach_hang_tai_khoan_id ON dbo.khach_hang (tai_khoan_id);
CREATE INDEX IX_phong_ma_lp ON dbo.phong (ma_lp);
CREATE INDEX IX_dat_phong_ma_kh ON dbo.dat_phong (ma_kh);
CREATE INDEX IX_dat_phong_ma_p ON dbo.dat_phong (ma_p);
CREATE INDEX IX_hoa_don_ma_dp ON dbo.hoa_don (ma_dp);
CREATE INDEX IX_su_dung_dich_vu_ma_dp ON dbo.su_dung_dich_vu (ma_dp);
CREATE INDEX IX_su_dung_dich_vu_ma_dv ON dbo.su_dung_dich_vu (ma_dv);

-- Giữ các mã gốc để dữ liệu mẫu khớp với khóa ngoại.
SET IDENTITY_INSERT dbo.tai_khoan ON;
INSERT INTO dbo.tai_khoan (id, ten_dang_nhap, mat_khau, vai_tro) VALUES
    (1, N''abc'', N''1234'', N''Admin''),
    (2, N''khach1'', N''1234'', N''KhachHang'');
SET IDENTITY_INSERT dbo.tai_khoan OFF;

SET IDENTITY_INSERT dbo.loai_phong ON;
INSERT INTO dbo.loai_phong (ma_lp, ten_lp, don_gia) VALUES
    (1, N''Phòng đơn'', 150000),
    (2, N''Phòng đôi'', 300000),
    (3, N''Phòng gia đình'', 400000),
    (4, N''Phòng VIP'', 500000);
SET IDENTITY_INSERT dbo.loai_phong OFF;

SET IDENTITY_INSERT dbo.dich_vu ON;
INSERT INTO dbo.dich_vu (ma_dv, ten_dv, don_gia) VALUES
    (1, N''Bữa sáng Buffet'', 100000),
    (2, N''Giặt ủi quần áo'', 50000),
    (3, N''Spa thư giãn'', 300000);
SET IDENTITY_INSERT dbo.dich_vu OFF;

SET IDENTITY_INSERT dbo.khach_hang ON;
INSERT INTO dbo.khach_hang (ma_kh, ho_ten, cccd, so_dt, dia_chi, tai_khoan_id) VALUES
    (1, N''Nguyễn Văn A'', N''001203004567'', N''0912345678'', N''Hà Nội'', 2);
SET IDENTITY_INSERT dbo.khach_hang OFF;

SET IDENTITY_INSERT dbo.phong ON;
INSERT INTO dbo.phong (ma_p, so_phong, mo_ta, hinh_anh, trang_thai, ma_lp) VALUES
    (1, N''101'', N''1 giường đơn, wifi miễn phí'', NULL, N''Trống'', 1),
    (2, N''102'', N''1 giường đôi, ban công thoáng mát'', NULL, N''Đang sử dụng'', 2),
    (3, N''201'', N''2 giường đôi, view toàn cảnh'', NULL, N''Trống'', 3),
    (4, N''301'', N''Phòng hạng sang, đầy đủ tiện nghi'', NULL, N''Trống'', 4);
SET IDENTITY_INSERT dbo.phong OFF;

SET IDENTITY_INSERT dbo.dat_phong ON;
INSERT INTO dbo.dat_phong (ma_dp, so_nguoi, ngay_bat_dau, ngay_ket_thuc, tien_dat_coc, trang_thai_tt, ma_kh, ma_p) VALUES
    (1, 2, ''2026-11-18T14:00:00'', ''2026-11-20T12:00:00'', 150000, N''Chưa trả'', 1, 2);
SET IDENTITY_INSERT dbo.dat_phong OFF;
';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
