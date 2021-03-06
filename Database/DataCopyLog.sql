USE [master]
GO
/****** Object:  Database [DataCopyLog]    Script Date: 6/26/2013 2:24:19 PM ******/
CREATE DATABASE [DataCopyLog]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DataCopyLog', FILENAME = N'D:\DATABASE_ALL\DataCopyLog.mdf' , SIZE = 20352KB , MAXSIZE = 5120000KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'DataCopyLog_log', FILENAME = N'D:\DATABASE_ALL\DataCopyLog_log.ldf' , SIZE = 1024KB , MAXSIZE = 102400KB , FILEGROWTH = 10%)
GO
ALTER DATABASE [DataCopyLog] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DataCopyLog].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [DataCopyLog] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [DataCopyLog] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [DataCopyLog] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [DataCopyLog] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [DataCopyLog] SET ARITHABORT OFF 
GO
ALTER DATABASE [DataCopyLog] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [DataCopyLog] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [DataCopyLog] SET AUTO_SHRINK ON 
GO
ALTER DATABASE [DataCopyLog] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DataCopyLog] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DataCopyLog] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DataCopyLog] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [DataCopyLog] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DataCopyLog] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [DataCopyLog] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DataCopyLog] SET  DISABLE_BROKER 
GO
ALTER DATABASE [DataCopyLog] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DataCopyLog] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DataCopyLog] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DataCopyLog] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DataCopyLog] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DataCopyLog] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DataCopyLog] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DataCopyLog] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [DataCopyLog] SET  MULTI_USER 
GO
ALTER DATABASE [DataCopyLog] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DataCopyLog] SET DB_CHAINING OFF 
GO
ALTER DATABASE [DataCopyLog] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [DataCopyLog] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'DataCopyLog', N'ON'
GO
USE [DataCopyLog]
GO
/****** Object:  User [thongpd]    Script Date: 6/26/2013 2:24:19 PM ******/
CREATE USER [thongpd] FOR LOGIN [thongpd] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [thongpd]
GO
/****** Object:  Table [dbo].[ExistedRecordCopyQueue]    Script Date: 6/26/2013 2:24:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExistedRecordCopyQueue](
	[ExistedRecordCopyQueueID] [int] IDENTITY(1,1) NOT NULL,
	[FromSubRecordID] [int] NOT NULL,
	[ToSubRecordID] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[RunningDate] [datetime] NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Logs] [nvarchar](max) NULL,
	[SubRecords] [int] NULL,
 CONSTRAINT [PK_ExistedRecordCopyQueueID] PRIMARY KEY CLUSTERED 
(
	[ExistedRecordCopyQueueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[KeywordCopyInfo]    Script Date: 6/26/2013 2:24:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[KeywordCopyInfo](
	[KeywordID] [int] NOT NULL,
	[LatestCopyRecordID] [int] NOT NULL,
	[LatestCopySubRecordID] [int] NOT NULL,
	[IsRunning] [bit] NOT NULL,
	[RunningDate] [datetime] NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_KeywordID] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[KeywordCopyLog]    Script Date: 6/26/2013 2:24:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[KeywordCopyLog](
	[KeywordCopyLogID] [int] IDENTITY(1,1) NOT NULL,
	[KeywordID] [int] NOT NULL,
	[FromRecordID] [int] NOT NULL,
	[ToRecordID] [int] NOT NULL,
	[FromSubRecordID] [int] NOT NULL,
	[ToSubRecordID] [int] NOT NULL,
	[Records] [int] NOT NULL,
	[SubRecords] [int] NOT NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Status] [varchar](50) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Logs] [nvarchar](max) NULL,
 CONSTRAINT [PK_KeywordCopyLogID] PRIMARY KEY CLUSTERED 
(
	[KeywordCopyLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RecordCopyLog]    Script Date: 6/26/2013 2:24:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RecordCopyLog](
	[RecordCopyLogID] [int] IDENTITY(1,1) NOT NULL,
	[KeywordID] [int] NOT NULL,
	[RecordID] [int] NOT NULL,
	[DHRecordID] [int] NOT NULL,
	[SubRecords] [int] NOT NULL,
	[PublishedDate] [datetime] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Logs] [nvarchar](max) NULL,
 CONSTRAINT [PK_RecordCopyLogID] PRIMARY KEY CLUSTERED 
(
	[RecordCopyLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Index [DHRecordID]    Script Date: 6/26/2013 2:24:19 PM ******/
CREATE NONCLUSTERED INDEX [DHRecordID] ON [dbo].[RecordCopyLog]
(
	[DHRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
USE [master]
GO
ALTER DATABASE [DataCopyLog] SET  READ_WRITE 
GO
