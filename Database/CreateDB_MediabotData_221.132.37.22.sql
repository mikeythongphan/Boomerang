USE [master]
GO
/****** Object:  Database [MediaBotData]    Script Date: 2/19/2013 10:07:51 AM ******/
CREATE DATABASE [MediaBotData]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'MediaBotData', FILENAME = N'D:\Database\MediaBotData.mdf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_1] 
( NAME = N'MediaBotDataSite1', FILENAME = N'D:\Database\MediaBotDataSite1.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_10] 
( NAME = N'MediaBotDataSite10', FILENAME = N'D:\Database\MediaBotDataSite10.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_2] 
( NAME = N'MediaBotDataSite2', FILENAME = N'D:\Database\MediaBotDataSite2.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_3] 
( NAME = N'MediaBotDataSite3', FILENAME = N'D:\Database\MediaBotDataSite3.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_4] 
( NAME = N'MediaBotDataSite4', FILENAME = N'D:\Database\MediaBotDataSite4.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_5] 
( NAME = N'MediaBotDataSite5', FILENAME = N'D:\Database\MediaBotDataSite5.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_6] 
( NAME = N'MediaBotDataSite6', FILENAME = N'D:\Database\MediaBotDataSite6.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_7] 
( NAME = N'MediaBotDataSite7', FILENAME = N'D:\Database\MediaBotDataSite7.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_8] 
( NAME = N'MediaBotDataSite8', FILENAME = N'D:\Database\MediaBotDataSite8.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [Site_9] 
( NAME = N'MediaBotDataSite9', FILENAME = N'D:\Database\MediaBotDataSite9.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'MediaBotData_log', FILENAME = N'D:\Database\MediaBotData_log.ldf' , SIZE = 3072KB , MAXSIZE = 2048GB , FILEGROWTH = 10240KB )
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
ALTER DATABASE [MediaBotData] SET AUTO_SHRINK ON 
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
/****** Object:  PartitionFunction [RecordShreddingInSiteGUID]    Script Date: 2/19/2013 10:07:53 AM ******/
CREATE PARTITION FUNCTION [RecordShreddingInSiteGUID](uniqueidentifier) AS RANGE RIGHT FOR VALUES (N'2d374d89-396b-4652-b00b-05a78689fa49', N'ca68039e-b20d-4358-8e97-3b57925fca39', N'2b2e713f-e888-4bba-849b-4c6baaf72be5', N'1709ccdb-c59c-476a-862d-60a73b8a30e7', N'c167fe47-fda5-45a2-8ae6-8f0943d7ed5c', N'5a2721f7-1337-4992-bc7f-9d85653c7fcd', N'a7bb2a18-f0ae-43ca-aa3b-b0a8ed14296b', N'21672bd9-77ad-4ae0-ac5c-f3aae2e9df09', N'dffc358b-93e7-48e1-ad27-f607c0bf69fb')
GO
/****** Object:  PartitionFunction [SubRecordShreddingInSiteGUID]    Script Date: 2/19/2013 10:07:53 AM ******/
CREATE PARTITION FUNCTION [SubRecordShreddingInSiteGUID](uniqueidentifier) AS RANGE RIGHT FOR VALUES (N'2d374d89-396b-4652-b00b-05a78689fa49', N'ca68039e-b20d-4358-8e97-3b57925fca39', N'2b2e713f-e888-4bba-849b-4c6baaf72be5', N'1709ccdb-c59c-476a-862d-60a73b8a30e7', N'c167fe47-fda5-45a2-8ae6-8f0943d7ed5c', N'5a2721f7-1337-4992-bc7f-9d85653c7fcd', N'a7bb2a18-f0ae-43ca-aa3b-b0a8ed14296b', N'21672bd9-77ad-4ae0-ac5c-f3aae2e9df09', N'dffc358b-93e7-48e1-ad27-f607c0bf69fb')
GO
/****** Object:  PartitionScheme [RecordShreddingInSiteGUIDSchema]    Script Date: 2/19/2013 10:07:53 AM ******/
CREATE PARTITION SCHEME [RecordShreddingInSiteGUIDSchema] AS PARTITION [RecordShreddingInSiteGUID] TO ([PRIMARY], [Site_1], [Site_2], [Site_3], [Site_4], [Site_5], [Site_6], [Site_7], [Site_8], [Site_9])
GO
/****** Object:  PartitionScheme [SubRecordShreddingInSiteGUIDSchema]    Script Date: 2/19/2013 10:07:53 AM ******/
CREATE PARTITION SCHEME [SubRecordShreddingInSiteGUIDSchema] AS PARTITION [SubRecordShreddingInSiteGUID] TO ([PRIMARY], [Site_9], [Site_8], [Site_7], [Site_6], [Site_5], [Site_4], [Site_3], [Site_2], [Site_1])
GO
/****** Object:  Table [dbo].[FanPage]    Script Date: 2/19/2013 10:07:53 AM ******/
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
/****** Object:  Table [dbo].[Record]    Script Date: 2/19/2013 10:07:53 AM ******/
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
	[FanpageGUID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Record] PRIMARY KEY NONCLUSTERED 
(
	[RecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])

GO
/****** Object:  Table [dbo].[SubRecord]    Script Date: 2/19/2013 10:07:53 AM ******/
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
/****** Object:  Index [NonClusteredIndex-20121202-154628]    Script Date: 2/19/2013 10:07:54 AM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20121202-154628] ON [dbo].[Record]
(
	[URL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
/****** Object:  Index [RecordGUID]    Script Date: 2/19/2013 10:07:54 AM ******/
CREATE NONCLUSTERED INDEX [RecordGUID] ON [dbo].[Record]
(
	[RecordGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [URL]    Script Date: 2/19/2013 10:07:54 AM ******/
CREATE NONCLUSTERED INDEX [URL] ON [dbo].[Record]
(
	[URL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
/****** Object:  Index [PublishedDateIndex]    Script Date: 2/19/2013 10:07:54 AM ******/
CREATE NONCLUSTERED INDEX [PublishedDateIndex] ON [dbo].[SubRecord]
(
	[PublishedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [SubRecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
/****** Object:  Index [RecordIDIndex]    Script Date: 2/19/2013 10:07:54 AM ******/
CREATE NONCLUSTERED INDEX [RecordIDIndex] ON [dbo].[SubRecord]
(
	[RecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [SubRecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
/****** Object:  Index [SiteGUIDIndex]    Script Date: 2/19/2013 10:07:54 AM ******/
CREATE NONCLUSTERED INDEX [SiteGUIDIndex] ON [dbo].[SubRecord]
(
	[SiteGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [SubRecordShreddingInSiteGUIDSchema]([SiteGUID])
GO
ALTER TABLE [dbo].[SubRecord]  WITH CHECK ADD  CONSTRAINT [FK_Record_SubRecord] FOREIGN KEY([RecordID])
REFERENCES [dbo].[Record] ([RecordID])
GO
ALTER TABLE [dbo].[SubRecord] CHECK CONSTRAINT [FK_Record_SubRecord]
GO
USE [master]
GO
ALTER DATABASE [MediaBotData] SET  READ_WRITE 
GO
