USE [quan_ly_khach_san];
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'dbo.dat_phong', N'trang_thai_dp') IS NULL
    BEGIN
        ALTER TABLE dbo.dat_phong ADD trang_thai_dp nvarchar(30) NOT NULL
            CONSTRAINT DF_dat_phong_trang_thai_dp DEFAULT (N'Chờ nhận phòng');

        -- Đơn cũ không lưu trạng thái riêng. Suy ra trạng thái từ lịch và phòng.
        EXEC sys.sp_executesql N'
            DECLARE @now datetime2(0) = DATEADD(hour, 7, SYSUTCDATETIME());
            UPDATE dp
            SET trang_thai_dp = CASE
                WHEN dp.ngay_ket_thuc <= @now THEN N''Đã trả phòng''
                ELSE N''Đang ở''
            END
            FROM dbo.dat_phong AS dp
            LEFT JOIN dbo.phong AS p ON p.ma_p = dp.ma_p
            WHERE dp.ngay_ket_thuc <= @now
                OR (dp.ngay_bat_dau <= @now AND p.trang_thai = N''Đang sử dụng'');
        ';
    END;

    IF COL_LENGTH(N'dbo.dat_phong', N'hinh_thuc_tt') IS NULL
        ALTER TABLE dbo.dat_phong ADD hinh_thuc_tt nvarchar(10) NOT NULL
            CONSTRAINT DF_dat_phong_hinh_thuc_tt DEFAULT (N'cash');

    IF COL_LENGTH(N'dbo.dat_phong', N'tong_tien_du_kien') IS NULL
        ALTER TABLE dbo.dat_phong ADD tong_tien_du_kien decimal(15, 0) NULL;
    IF COL_LENGTH(N'dbo.dat_phong', N'gio_vao_thuc_te') IS NULL
        ALTER TABLE dbo.dat_phong ADD gio_vao_thuc_te datetime2(0) NULL;
    IF COL_LENGTH(N'dbo.dat_phong', N'gio_ra_thuc_te') IS NULL
        ALTER TABLE dbo.dat_phong ADD gio_ra_thuc_te datetime2(0) NULL;

    IF OBJECT_ID(N'dbo.nhan_vien', N'U') IS NULL
        CREATE TABLE dbo.nhan_vien (
            ma_nv int IDENTITY(1, 1) CONSTRAINT PK_nhan_vien PRIMARY KEY,
            ho_ten nvarchar(100) NOT NULL,
            chuc_vu nvarchar(100) NOT NULL,
            so_dt nvarchar(15) NULL,
            luong decimal(15, 0) NOT NULL CHECK (luong >= 0)
        );

    IF OBJECT_ID(N'dbo.cau_hinh_khach_san', N'U') IS NULL
        CREATE TABLE dbo.cau_hinh_khach_san (
            id int CONSTRAINT PK_cau_hinh_khach_san PRIMARY KEY CHECK (id = 1),
            anh_qr nvarchar(max) NULL
        );

    IF NOT EXISTS (SELECT 1 FROM dbo.cau_hinh_khach_san WHERE id = 1)
        INSERT INTO dbo.cau_hinh_khach_san (id) VALUES (1);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
