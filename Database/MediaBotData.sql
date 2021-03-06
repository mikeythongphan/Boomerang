USE [master]
GO
/****** Object:  Database [MediaBotData]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE DATABASE [MediaBotData]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'MediaBotData', FILENAME = N'D:\DATABASE_ALL\MediaBotData.mdf' , SIZE = 1741120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_1] 
( NAME = N'MediaBotDataSite1', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite1.ndf' , SIZE = 451840KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_10] 
( NAME = N'MediaBotDataSite10', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite10.ndf' , SIZE = 585664KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_11] 
( NAME = N'MediaBotDataSite11', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite11.ndf' , SIZE = 5168256KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_12] 
( NAME = N'MediaBotDataSite12', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite12.ndf' , SIZE = 14238720KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_13] 
( NAME = N'MediaBotDataSite13', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite13.ndf' , SIZE = 54272KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_2] 
( NAME = N'MediaBotDataSite2', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite2.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_3] 
( NAME = N'MediaBotDataSite3', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite3.ndf' , SIZE = 6226176KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_4] 
( NAME = N'MediaBotDataSite4', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite4.ndf' , SIZE = 1202624KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_5] 
( NAME = N'MediaBotDataSite5', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite5.ndf' , SIZE = 97792KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_6] 
( NAME = N'MediaBotDataSite6', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite6.ndf' , SIZE = 119168KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_7] 
( NAME = N'MediaBotDataSite7', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite7.ndf' , SIZE = 379904KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_8] 
( NAME = N'MediaBotDataSite8', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite8.ndf' , SIZE = 386752KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_9] 
( NAME = N'MediaBotDataSite9', FILENAME = N'D:\DATABASE_ALL\MediaBotDataSite9.ndf' , SIZE = 30067904KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'MediaBotData_log', FILENAME = N'D:\DATABASE_ALL\MediaBotData_log.ldf' , SIZE = 340992KB , MAXSIZE = 2048GB , FILEGROWTH = 10240KB )
GO
ALTER DATABASE [MediaBotData] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [MediaBotData].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [MediaBotData] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [MediaBotData] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [MediaBotData] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [MediaBotData] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [MediaBotData] SET ARITHABORT OFF 
GO
ALTER DATABASE [MediaBotData] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [MediaBotData] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [MediaBotData] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [MediaBotData] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [MediaBotData] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [MediaBotData] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [MediaBotData] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [MediaBotData] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [MediaBotData] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [MediaBotData] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [MediaBotData] SET  DISABLE_BROKER 
GO
ALTER DATABASE [MediaBotData] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [MediaBotData] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [MediaBotData] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [MediaBotData] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [MediaBotData] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [MediaBotData] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [MediaBotData] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [MediaBotData] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [MediaBotData] SET  MULTI_USER 
GO
ALTER DATABASE [MediaBotData] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [MediaBotData] SET DB_CHAINING OFF 
GO
ALTER DATABASE [MediaBotData] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [MediaBotData] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'MediaBotData', N'ON'
GO
USE [MediaBotData]
GO
/****** Object:  PartitionFunction [RecordShreddingInSiteGUID]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE PARTITION FUNCTION [RecordShreddingInSiteGUID](uniqueidentifier) AS RANGE RIGHT FOR VALUES (N'2d374d89-396b-4652-b00b-05a78689fa49', N'93a82c00-d33a-436b-9808-3230e60dab5c', N'2191726f-3797-4226-9930-32b3f9b964d3', N'2ff3f9b3-088e-48a8-ae5b-4b08ccc74370', N'bf491e4e-386b-49e8-949e-506cdac01b1d', N'9abb0d40-c24e-4066-8c09-608949932cdf', N'2a972d3b-8e4a-4d4e-9c41-64fc1ebbb18d', N'1abfe49b-1ffe-479c-8739-6e767a62b828', N'c6cbdd12-fe26-45d9-8771-9323fb3210af', N'a3ac5035-f55f-4a35-a267-93e05d48367e', N'104b878a-89ab-4b69-9f8b-98a9149af6ef', N'17eb38d4-2971-48a6-bd44-bd1bf1a927c9', N'7f1b0501-4c55-41a4-a036-e661b247db83', N'9bc07398-be9c-4b57-b9a1-ea7f528921c9')
GO
/****** Object:  PartitionFunction [SubRecordShreddingInSiteGUID]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE PARTITION FUNCTION [SubRecordShreddingInSiteGUID](uniqueidentifier) AS RANGE RIGHT FOR VALUES (N'2d374d89-396b-4652-b00b-05a78689fa49', N'93a82c00-d33a-436b-9808-3230e60dab5c', N'2191726f-3797-4226-9930-32b3f9b964d3', N'2ff3f9b3-088e-48a8-ae5b-4b08ccc74370', N'bf491e4e-386b-49e8-949e-506cdac01b1d', N'9abb0d40-c24e-4066-8c09-608949932cdf', N'2a972d3b-8e4a-4d4e-9c41-64fc1ebbb18d', N'1abfe49b-1ffe-479c-8739-6e767a62b828', N'c6cbdd12-fe26-45d9-8771-9323fb3210af', N'a3ac5035-f55f-4a35-a267-93e05d48367e', N'104b878a-89ab-4b69-9f8b-98a9149af6ef', N'17eb38d4-2971-48a6-bd44-bd1bf1a927c9', N'7f1b0501-4c55-41a4-a036-e661b247db83', N'9bc07398-be9c-4b57-b9a1-ea7f528921c9')
GO
/****** Object:  PartitionScheme [RecordShreddingInSiteGUIDSchema]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE PARTITION SCHEME [RecordShreddingInSiteGUIDSchema] AS PARTITION [RecordShreddingInSiteGUID] TO ([PRIMARY], [Site_1], [Site_3], [Site_4], [Site_13], [Site_8], [Site_1], [Site_9], [Site_6], [Site_11], [Site_2], [Site_10], [Site_5], [Site_7], [Site_12])
GO
/****** Object:  PartitionScheme [SubRecordShreddingInSiteGUIDSchema]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE PARTITION SCHEME [SubRecordShreddingInSiteGUIDSchema] AS PARTITION [SubRecordShreddingInSiteGUID] TO ([PRIMARY], [Site_9], [Site_3], [Site_4], [Site_13], [Site_8], [Site_1], [Site_9], [Site_6], [Site_11], [Site_2], [Site_10], [Site_5], [Site_7], [Site_12])
GO
/****** Object:  StoredProcedure [dbo].[GetDBMediaBotDataReportCrawler]    Script Date: 6/14/2013 4:26:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetDBMediaBotDataReportCrawler]
    @StartDate datetime,
    @EndDate datetime
WITH recompile
AS
BEGIN
	SET NOCOUNT ON

	select '221.132.37.45.MediaBotData' AS 'Ip', 4 AS 'ServerID',rd.SiteGUID as 'siteGUID',
				COUNT(distinct rd.RecordID) as 'NumRecordID', COUNT(sr.SubRecordID) as 'NumSubRecordID', 3 as 'IsCompleted'
	from [MediaBotData].[dbo].[Record] rd with(NOLOCK) 
			join [MediaBotData].[dbo].subrecord sr with(NOLOCK)
				on rd.RecordID=sr.RecordID
	where rd.PublishedDate>=@StartDate and rd.PublishedDate<=@EndDate
	group by rd.SiteGUID

END



GO
/****** Object:  UserDefinedFunction [dbo].[GetLatestSubRecordDate]    Script Date: 6/14/2013 4:26:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Mar 22, 2013
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[GetLatestSubRecordDate] 
(	
	-- Add the parameters for the function here
	@RecordID int
)
RETURNS DateTime
AS
BEGIN
	-- Add the SELECT statement with parameter references here
	DECLARE @Result datetime 
	SET @Result = (SELECT max(PublishedDate)
	FROM SubRecord WITH(NOLOCK)
	WHERE RecordID = @RecordID)

	RETURN case when @Result is not null then @Result else '1753-01-01' end;
END

GO
/****** Object:  UserDefinedFunction [dbo].[GetNumberOfSubRecord]    Script Date: 6/14/2013 4:26:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Mar 22, 2013
-- Description:	<Description,,>
-- =============================================
create FUNCTION [dbo].[GetNumberOfSubRecord] 
(	
	-- Add the parameters for the function here
	@RecordID int
)
RETURNS int 
AS
BEGIN
	-- Add the SELECT statement with parameter references here
	DECLARE @Result int
	SET @Result = (SELECT COUNT(*)
	FROM SubRecord WITH(NOLOCK)
	WHERE RecordID = @RecordID)

	RETURN @Result
END

GO
/****** Object:  Table [dbo].[CheckCopy_SubRecord]    Script Date: 6/14/2013 4:26:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CheckCopy_SubRecord](
	[SubRecordID] [int] NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[RecordID] [int] NOT NULL,
 CONSTRAINT [PK_CheckCopy_SubRecord] PRIMARY KEY CLUSTERED 
(
	[SubRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Site_6]
) ON [Site_6] TEXTIMAGE_ON [Site_6]

GO
/****** Object:  Table [dbo].[Data]    Script Date: 6/14/2013 4:26:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Data](
	[F1] [nvarchar](255) NULL,
	[SiteGUID] [uniqueidentifier] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FanPage]    Script Date: 6/14/2013 4:26:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FanPage](
	[FanpageID] [int] IDENTITY(1,1) NOT NULL,
	[FagepageGUID] [uniqueidentifier] NOT NULL,
	[URL] [nvarchar](1024) NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[FanpagName] [nvarchar](200) NULL,
 CONSTRAINT [PK_FanPage] PRIMARY KEY CLUSTERED 
(
	[FanpageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Record]    Script Date: 6/14/2013 4:26:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Record](
	[RecordID] [int] IDENTITY(1,1) NOT NULL,
	[RecordGUID] [uniqueidentifier] NOT NULL,
	[URL] [nvarchar](1024) NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[Author] [nvarchar](256) NOT NULL,
	[PublishedDate] [datetime] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Title] [nvarchar](512) NOT NULL,
	[IsDeleted] [bit] NULL,
	[SubSiteGUID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Record] PRIMARY KEY NONCLUSTERED 
(
	[RecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])

GO
/****** Object:  Table [dbo].[SubRecord]    Script Date: 6/14/2013 4:26:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SubRecord](
	[SubRecordID] [int] IDENTITY(1,1) NOT NULL,
	[SubRecordGUID] [uniqueidentifier] NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[URL] [nvarchar](1024) NOT NULL,
	[Author] [nvarchar](256) NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[PublishedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NULL,
	[RecordID] [int] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_SubRecord] PRIMARY KEY NONCLUSTERED 
(
	[SubRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [SubRecordShreddingInSiteGUIDSchema]([SiteGUID])

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [NonClusteredIndex-20121202-154628]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20121202-154628] ON [dbo].[Record]
(
	[URL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
/****** Object:  Index [RecordGUID]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE NONCLUSTERED INDEX [RecordGUID] ON [dbo].[Record]
(
	[RecordGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [URL]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE NONCLUSTERED INDEX [URL] ON [dbo].[Record]
(
	[URL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
/****** Object:  Index [PublishedDateIndex]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE NONCLUSTERED INDEX [PublishedDateIndex] ON [dbo].[SubRecord]
(
	[PublishedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [SubRecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
/****** Object:  Index [RecordIDIndex]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE NONCLUSTERED INDEX [RecordIDIndex] ON [dbo].[SubRecord]
(
	[RecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [SubRecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
/****** Object:  Index [SiteGUIDIndex]    Script Date: 6/14/2013 4:26:20 PM ******/
CREATE NONCLUSTERED INDEX [SiteGUIDIndex] ON [dbo].[SubRecord]
(
	[SiteGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [SubRecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
ALTER TABLE [dbo].[SubRecord]  WITH NOCHECK ADD  CONSTRAINT [FK_Record_SubRecord] FOREIGN KEY([RecordID])
REFERENCES [dbo].[Record] ([RecordID])
GO
ALTER TABLE [dbo].[SubRecord] CHECK CONSTRAINT [FK_Record_SubRecord]
GO
USE [master]
GO
ALTER DATABASE [MediaBotData] SET  READ_WRITE 
GO
