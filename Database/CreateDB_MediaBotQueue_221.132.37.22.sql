USE [master]
GO
/****** Object:  Database [MediaBotQueue]    Script Date: 2/19/2013 10:10:37 AM ******/
CREATE DATABASE [MediaBotQueue]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'MediaBot', FILENAME = N'D:\Database\MediaBot.mdf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'MediaBot_log', FILENAME = N'D:\Database\MediaBot_log.ldf' , SIZE = 3072KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [MediaBotQueue] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [MediaBotQueue].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [MediaBotQueue] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [MediaBotQueue] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [MediaBotQueue] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [MediaBotQueue] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [MediaBotQueue] SET ARITHABORT OFF 
GO
ALTER DATABASE [MediaBotQueue] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [MediaBotQueue] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [MediaBotQueue] SET AUTO_SHRINK ON 
GO
ALTER DATABASE [MediaBotQueue] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [MediaBotQueue] SET CURSOR_CLOSE_ON_COMMIT ON 
GO
ALTER DATABASE [MediaBotQueue] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [MediaBotQueue] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [MediaBotQueue] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [MediaBotQueue] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [MediaBotQueue] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [MediaBotQueue] SET  DISABLE_BROKER 
GO
ALTER DATABASE [MediaBotQueue] SET AUTO_UPDATE_STATISTICS_ASYNC ON 
GO
ALTER DATABASE [MediaBotQueue] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [MediaBotQueue] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [MediaBotQueue] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [MediaBotQueue] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [MediaBotQueue] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [MediaBotQueue] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [MediaBotQueue] SET RECOVERY FULL 
GO
ALTER DATABASE [MediaBotQueue] SET  MULTI_USER 
GO
ALTER DATABASE [MediaBotQueue] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [MediaBotQueue] SET DB_CHAINING OFF 
GO
ALTER DATABASE [MediaBotQueue] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [MediaBotQueue] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'MediaBotQueue', N'ON'
GO
USE [MediaBotQueue]
GO
/****** Object:  StoredProcedure [dbo].[PickupImportThreadToCrawl]    Script Date: 2/19/2013 10:10:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Nov 2, 2012
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[PickupImportThreadToCrawl]
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @QueueID int

	WHILE(1=1)
	BEGIN
		SET @QueueID = (SELECT TOP 1 Id
			FROM [dbo].[ImportQueue] WITH (ROWLOCK)
			WHERE IsCompleted = 0 AND IsRunning = 0 AND SiteGuid IS NOT NULL
			ORDER BY InsertedDate DESC)

		IF(@QueueID IS NULL) OR (@QueueID <= 0)
			BREAK
		
		UPDATE [dbo].[ImportQueue] 
		SET IsRunning = 1
		WHERE Id = @QueueID AND IsCompleted = 0 AND IsRunning = 0
	
		IF @@ROWCOUNT = 1
			BREAK
	END
	
	SELECT *
	FROM [dbo].[ImportQueue]
	WHERE Id = @QueueID

END
RETURN

GO
/****** Object:  StoredProcedure [dbo].[PickupThreadToCrawl]    Script Date: 2/19/2013 10:10:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Nov 2, 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PickupThreadToCrawl]
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @QueueID int

	WHILE(1=1)
	BEGIN
		SET @QueueID = (SELECT TOP 1 Id
			FROM [dbo].[Queue] WITH (NOLOCK)
			WHERE IsCompleted = 0 AND IsRunning = 0
			ORDER BY PublishedDate DESC)

		IF(@QueueID IS NULL) OR (@QueueID <= 0)
			BREAK
		
		UPDATE [dbo].[Queue] 
		SET IsRunning = 1
		WHERE Id = @QueueID AND IsCompleted = 0 AND IsRunning = 0
	
		IF @@ROWCOUNT = 1
			BREAK
	END
	
	SELECT *
	FROM [dbo].[Queue]
	WHERE Id = @QueueID

END
RETURN

GO
/****** Object:  Table [dbo].[ImportQueue]    Script Date: 2/19/2013 10:10:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ImportQueue](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SiteGUID] [uniqueidentifier] NULL,
	[InsertedDate] [datetime] NOT NULL,
	[IsCompleted] [bit] NOT NULL,
	[Order] [int] NOT NULL,
	[PublishedDate] [datetime] NULL,
	[LatestPageUrl] [nvarchar](512) NULL,
	[IsRunning] [bit] NULL,
	[URL] [nvarchar](512) NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Title] [nvarchar](512) NOT NULL,
	[NumberOfRetries] [int] NOT NULL,
	[KeywordGUID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_ImportQueue] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Queue]    Script Date: 2/19/2013 10:10:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Queue](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[IsCompleted] [bit] NOT NULL,
	[Order] [int] NOT NULL,
	[PublishedDate] [datetime] NOT NULL,
	[LatestPageUrl] [nvarchar](512) NULL,
	[IsRunning] [bit] NULL,
	[URL] [nvarchar](512) NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Title] [nvarchar](512) NOT NULL,
	[NumberOfRetries] [int] NOT NULL,
 CONSTRAINT [PK_Queue] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SiteTask]    Script Date: 2/19/2013 10:10:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SiteTask](
	[SiteTaskID] [int] IDENTITY(1,1) NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[Completed] [bit] NOT NULL,
	[MachineIP] [varchar](64) NOT NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Order] [int] NOT NULL,
	[Succeeded] [bit] NULL,
	[TaskName] [nvarchar](128) NULL,
 CONSTRAINT [PK_Task] PRIMARY KEY CLUSTERED 
(
	[SiteTaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [NonClusteredIndex-20121106-010654]    Script Date: 2/19/2013 10:10:37 AM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20121106-010654] ON [dbo].[Queue]
(
	[URL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20121106-010707]    Script Date: 2/19/2013 10:10:37 AM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20121106-010707] ON [dbo].[Queue]
(
	[PublishedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20121106-010756]    Script Date: 2/19/2013 10:10:37 AM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20121106-010756] ON [dbo].[SiteTask]
(
	[SiteGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ImportQueue] ADD  CONSTRAINT [DF_ImportQueue_InsertedDate]  DEFAULT (getdate()) FOR [InsertedDate]
GO
ALTER TABLE [dbo].[ImportQueue] ADD  CONSTRAINT [DF_ImportQueue_IsCompleted]  DEFAULT ((0)) FOR [IsCompleted]
GO
ALTER TABLE [dbo].[ImportQueue] ADD  CONSTRAINT [DF_ImportQueue_Order]  DEFAULT ((0)) FOR [Order]
GO
ALTER TABLE [dbo].[ImportQueue] ADD  CONSTRAINT [DF_ImportQueue_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[ImportQueue] ADD  CONSTRAINT [DF_ImportQueue_Title]  DEFAULT ('') FOR [Title]
GO
ALTER TABLE [dbo].[ImportQueue] ADD  CONSTRAINT [DF_ImportQueue_NumberOfRetries]  DEFAULT ((0)) FOR [NumberOfRetries]
GO
ALTER TABLE [dbo].[Queue] ADD  CONSTRAINT [DF_Queue_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[Queue] ADD  CONSTRAINT [DF_Queue_Title]  DEFAULT ('') FOR [Title]
GO
ALTER TABLE [dbo].[Queue] ADD  CONSTRAINT [DF_Queue_NumberOfRetries]  DEFAULT ((0)) FOR [NumberOfRetries]
GO
ALTER TABLE [dbo].[SiteTask] ADD  CONSTRAINT [DF_Task_InsertedDate]  DEFAULT (getdate()) FOR [InsertedDate]
GO
ALTER TABLE [dbo].[SiteTask] ADD  CONSTRAINT [DF_Task_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[SiteTask] ADD  CONSTRAINT [DF_Task_Completed]  DEFAULT ((0)) FOR [Completed]
GO
ALTER TABLE [dbo].[SiteTask] ADD  CONSTRAINT [DF_Task_Succeeded]  DEFAULT ((0)) FOR [Succeeded]
GO
USE [master]
GO
ALTER DATABASE [MediaBotQueue] SET  READ_WRITE 
GO
