USE [master]
GO
/****** Object:  Database [MediaBotQueue]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE DATABASE [MediaBotQueue]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'MediaBot', FILENAME = N'D:\DATABASE_ALL\MediaBot.mdf' , SIZE = 9352448KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'MediaBot_log', FILENAME = N'D:\DATABASE_ALL\MediaBot_log.ldf' , SIZE = 1280KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
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
ALTER DATABASE [MediaBotQueue] SET RECOVERY SIMPLE 
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
/****** Object:  StoredProcedure [dbo].[CopyFacebookDataToProduction]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Feb 20, 2013
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CopyFacebookDataToProduction] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--
	SET NOCOUNT ON;

	DECLARE @KeywordGUID uniqueidentifier
	DECLARE @SiteGUID uniqueidentifier
	DECLARE @PublishedDate datetime
	DECLARE @Url nvarchar(256)
	DECLARE @RecordGUID uniqueidentifier
	DECLARE @RecordID int
	DECLARE @OriginalRecordID int
	DECLARE @FRDId int

	DECLARE recordCursor CURSOR
		FOR (SELECT frd.id, frd.KeywordGUID, fq.[SiteGUID], fq.[PublishedDate], fq.[URL]
			FROM (SELECT *
					FROM [dbo].[FacebookRecordDispatcher] WITH(NOLOCK)
					where IsCompleted = 0) frd
				INNER JOIN (SELECT *
							FROM FacebookQueue  WITH(NOLOCK)
							WHERE IsCompleted = 1) fq ON fq.Url = frd.Url)
	OPEN recordCursor
	FETCH NEXT FROM recordCursor
	INTO @FRDId, @KeywordGUID, @SiteGUID, @PublishedDate, @Url

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		SET @RecordGUID = (SELECT RecordGUID
					FROM MediaBotData.dbo.Record  WITH(NOLOCK)
					WHERE SiteGUID = @SiteGUID AND URL = @Url)

		IF @RecordGUID IS NULL 
			CONTINUE;

	
 		--BEGIN TRANSACTION CopyData

			SET @RecordID = (SELECT RecordID
						FROM [221.132.35.146].[ContentCrawler].dbo.Record  WITH(NOLOCK)
						WHERE SiteGUID = @SiteGUID AND [RecordGUID] = @RecordGUID AND [KeywordGUID] = @KeywordGUID)

			BEGIN TRANSACTION
			IF @RecordID IS NULL
			BEGIN
				INSERT INTO [221.132.35.146].[ContentCrawler].dbo.Record([RecordGUID], [KeywordGUID], [SiteGUID], [Title], [URL], [Author], [PublishedDate])
				SELECT [RecordGUID], @KeywordGUID, [SiteGUID], [Title], [URL], [Author], [PublishedDate]
				FROM MediaBotData.dbo.Record  WITH(NOLOCK)
				WHERE SiteGUID = @SiteGUID AND RecordGUID = @RecordGUID

				SET @RecordID = @@Identity
			END
			ELSE
			BEGIN
				UPDATE [221.132.35.146].[ContentCrawler].dbo.Record
				SET [PublishedDate] = r.PublishedDate
				FROM MediaBotData.dbo.Record r  WITH(NOLOCK)
				WHERE r.SiteGUID = @SiteGUID AND r.RecordGUID = @RecordGUID
			END
			COMMIT TRANSACTION
		
			SET @OriginalRecordID = (SELECT RecordID FROM MediaBotData.dbo.Record WITH(NOLOCK) WHERE SiteGUID = @SiteGUID AND RecordGUID  = @RecordGUID);
			
			BEGIN TRANSACTION
			INSERT INTO [221.132.35.146].[ContentCrawler].dbo.SubRecord([SubRecordGUID], [KeywordGUID], [SiteGUID], [RecordID], [Content], [URL], [Author], [PublishedDate])
				SELECT osr.[SubRecordGUID], @KeywordGUID, osr.[SiteGUID], @RecordID, osr.[Content], osr.[URL], osr.[Author], osr.[PublishedDate]
				FROM (SELECT * FROM MediaBotData.dbo.SubRecord WITH(NOLOCK) WHERE SiteGUID = @SiteGUID AND  RecordID = @OriginalRecordID) osr
					LEFT JOIN (SELECT * FROM [221.132.35.146].[ContentCrawler].dbo.SubRecord  WITH(NOLOCK) WHERE SiteGUID = @SiteGUID AND  RecordID = @RecordID) sr
					ON sr.SubRecordGUID = osr.SubRecordGUID
				WHERE sr.SubRecordGUID IS NULL
		
			COMMIT TRANSACTION 

			UPDATE [dbo].[FacebookRecordDispatcher]
			SET IsCompleted = 1
			WHERE Id = @FRDId
			

		FETCH NEXT FROM recordCursor 
		INTO @FRDId, @KeywordGUID, @SiteGUID, @PublishedDate, @Url
	END 
	CLOSE recordCursor;
	DEALLOCATE recordCursor;

END


GO
/****** Object:  StoredProcedure [dbo].[CreateFanPageScheduleTask]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Toan Huynh
-- Create date: Feb 20, 2013
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CreateFanPageScheduleTask] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	WITH FanPageCompletedTask(SiteGUID, SubSiteGUID, EndDate)
	AS (select SiteGUID, SubSiteGUID, EndDate
	from FanPageTask)
	--group by SiteGUID, SubSiteGUID) 
	INSERT INTO [dbo].[FanPageTask]([SiteGUID], [SubSiteGUID], [StartDate], EndDate)
	SELECT fp.SiteGUID, fp.GUID, fpct.EndDate, getdate()
	FROM FanPage fp
		LEFT JOIN FanPageCompletedTask fpct ON fp.SiteGUID = fpct.SiteGUID and fp.GUID = fpct.SubSiteGUID
	WHERE fpct.SiteGUID is null

	INSERT INTO FanPageTaskCache([SiteGUID], [SubSiteGUID], [StartDate],[EndDate], [PreviousPage], [NextPage])
	SELECT [SiteGUID], [SubSiteGUID], [StartDate],[EndDate], [PreviousPage], [NextPage]
	FROM FanPageTask
	WHERE IsCompleted = 1

	UPDATE FanPageTask
	SET IsCompleted = 0, UpdatedDate = getdate()
	FROM FanPageTask q
	WHERE q.IsCompleted = 1 AND (DATEDIFF(mi, q.UpdatedDate, getdate()) >= 30)
END


GO
/****** Object:  StoredProcedure [dbo].[CreateSearchScheduleTask]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Feb 20, 2013
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CreateSearchScheduleTask] 
@SiteGUID uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	WITH SearchQueueCompleted([KeywordGUID], [WordGUID], EndDate, StartDate)
	AS (select[KeywordGUID], [WordGUID],  max(EndDate), min(StartDate)
	from SearchQueue
	where SiteGuid = @SiteGUID
	group by [KeywordGUID], [WordGUID]) 
	INSERT INTO [dbo].[SearchQueue](SiteGUID, [KeywordGUID], [WordGUID], [StartDate], EndDate)
	SELECT @SiteGUID, kt.KeywordGUID, kt.WordGUID, CASE WHEN fsqc.EndDate > kt.StartDate THEN fsqc.EndDate ELSE kt.StartDate END, CASE WHEN kt.EndDate is NULL THEN getdate() WHEN kt.EndDate < getdate() THEN kt.EndDate ELSE getdate() END
	FROM (select kw.GUID as KeywordGUID, wd.GUID as WordGUID, kw.StartDate as StartDate, kw.EndDate as EndDate
		from (SELECT * FROM [221.132.35.146].[ContentAggregator].dbo.Keyword 
				where IsActive = 1 and (EndDate is null or datediff(dd, EndDate, getdate()) <= 0)) kw inner join [221.132.35.146].[ContentAggregator].dbo.Word wd on kw.KeywordID = wd.KeywordID
		where wd.IsDeleted = 0) kt
		LEFT JOIN SearchQueueCompleted fsqc ON kt.KeywordGUID = fsqc.KeywordGUID and kt.WordGUID = fsqc.WordGUID
	WHERE fsqc.WordGUID IS NULL 

	INSERT INTO [dbo].[SearchQueueCache](SiteGUID, [InsertedDate], [EndDate], [UpdatedDate], [KeywordGUID], [WordGUID], [StartDate], [PreviousPage], [NextPage])
	SELECT q.SiteGUID, q.[InsertedDate], q.[EndDate], q.[UpdatedDate], q.[KeywordGUID], q.[WordGUID], q.[StartDate], q.[PreviousPage], q.[NextPage]
	FROM SearchQueue q
	WHERE q.IsCompleted = 1  and q.SiteGUID = @SiteGUID

	UPDATE SearchQueue
	SET IsCompleted = 0, UpdatedDate = getdate()
	FROM SearchQueue q
	WHERE q.SiteGUID = @SiteGUID and q.IsCompleted = 1 AND (DATEDIFF(mi, q.UpdatedDate, getdate()) >= 30)
END


GO
/****** Object:  StoredProcedure [dbo].[GetDBMediaBotQueueReportCrawler]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBMediaBotQueueReportCrawler]
    @StartDate datetime,
    @EndDate datetime
WITH recompile
AS
BEGIN
	SET NOCOUNT ON

	select '221.132.37.4.MediaBotQueue' AS 'Ip', 3 AS 'ServerID', q.SiteGUID as 'siteGUID',
				COUNT(distinct q.Id) as 'NumRecordID', 0 as 'NumSubRecordID', q.IsCompleted as 'IsCompleted'
	from [MediaBotQueue].[dbo].[Queue] q with(NOLOCK) 				
	where q.PublishedDate>=@StartDate and q.PublishedDate<=@EndDate
	group by q.SiteGUID, q.IsCompleted

END


GO
/****** Object:  StoredProcedure [dbo].[PickupFacebookPostToCrawl]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Nov 2, 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PickupFacebookPostToCrawl]
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @PostID int

	WHILE(1=1)
	BEGIN
		SET @PostID = (SELECT TOP 1 Id
			FROM [dbo].[FacebookQueue] WITH (ROWLOCK)
			WHERE IsCompleted = 0 AND IsRunning = 0
			ORDER BY PublishedDate DESC)

		IF(@PostID IS NULL) OR (@PostID <= 0)
			BREAK
		
		UPDATE [dbo].[FacebookQueue] 
		SET IsRunning = 1
		WHERE Id = @PostID AND IsCompleted = 0 AND IsRunning = 0
	
		IF @@ROWCOUNT = 1
			BREAK
	END
	
	SELECT *
	FROM [dbo].[FacebookQueue]
	WHERE Id = @PostID

END
RETURN



GO
/****** Object:  StoredProcedure [dbo].[PickupFacebookSearchQueueThreadToCrawl]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PickupFacebookSearchQueueThreadToCrawl]
AS
BEGIN
	
	SET NOCOUNT ON;

	exec PickupSNSSiteSearchQueueThreadToCrawl @SiteGUID = '9BC07398-BE9C-4B57-B9A1-EA7F528921C9'
	
END
RETURN


GO
/****** Object:  StoredProcedure [dbo].[PickupFanPageTaskToCrawl]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Nov 2, 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PickupFanPageTaskToCrawl]
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @TaskID int
	
	SET @TaskID = 0

	WHILE(1=1)
	BEGIN
		SET @TaskID = (SELECT TOP 1 Id
			FROM [dbo].[FanPageTask] WITH (ROWLOCK)
			WHERE IsCompleted = 0 AND IsRunning = 0
			ORDER BY UpdatedDate)

		IF(@TaskID IS NULL) OR (@TaskID <= 0)
			BREAK
		
		UPDATE [dbo].[FanPageTask] 
		SET IsRunning = 1
		WHERE Id = @TaskID AND IsCompleted = 0 AND IsRunning = 0
	
		IF @@ROWCOUNT = 1
			BREAK
	END
	
	SELECT *
	FROM [dbo].[FanPageTask]
	WHERE id = @TaskID

END
RETURN


GO
/****** Object:  StoredProcedure [dbo].[PickupImportThreadToCrawl]    Script Date: 6/14/2013 4:08:47 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PickupSNSSiteSearchQueueThreadToCrawl]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Feb 28, 2013
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PickupSNSSiteSearchQueueThreadToCrawl]
	@SiteGUID uniqueidentifier
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @QueueID int

	WHILE(1=1)
	BEGIN
		SET @QueueID = (SELECT TOP 1 Id
			FROM [dbo].[SearchQueue] WITH (ROWLOCK)
			WHERE IsCompleted = 0 AND IsRunning = 0 AND SiteGUID = @SiteGUID
			ORDER BY [Order] DESC, UpdatedDate)

		IF(@QueueID IS NULL) OR (@QueueID <= 0)
			BREAK
		
		UPDATE [dbo].[SearchQueue] 
		SET IsRunning = 1
		WHERE Id = @QueueID AND IsCompleted = 0 AND IsRunning = 0
	
		IF @@ROWCOUNT = 1
			BREAK
	END
	
	SELECT *
	FROM [dbo].[SearchQueue]
	WHERE Id = @QueueID

END
RETURN



GO
/****** Object:  StoredProcedure [dbo].[PickupThreadToCrawl]    Script Date: 6/14/2013 4:08:47 PM ******/
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
/****** Object:  StoredProcedure [dbo].[PickupYouTubeSearchQueueThreadToCrawl]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Toan Huynh
-- Create date: Feb 28, 2013
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PickupYouTubeSearchQueueThreadToCrawl]
AS
BEGIN
	
	SET NOCOUNT ON;

	exec PickupSNSSiteSearchQueueThreadToCrawl @SiteGUID = '2FF3F9B3-088E-48A8-AE5B-4B08CCC74370'
	

END
RETURN



GO
/****** Object:  Table [dbo].[Connection]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Connection](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[ConnectionString] [varchar](256) NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Connection] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FacebookQueue]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FacebookQueue](
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
	[Content] [nvarchar](max) NOT NULL,
	[PreviousPage] [nvarchar](512) NULL,
	[NextPage] [nvarchar](512) NULL,
	[PostID] [nvarchar](256) NOT NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_FAcebookQueueID] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FacebookRecordDispatcher]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FacebookRecordDispatcher](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Url] [nvarchar](512) NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[IsCompleted] [bit] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[PublishedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_FacebookRecordDispatcher] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FanPage]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FanPage](
	[Id] [int] NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[PageId] [nvarchar](512) NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[LatestUpdatedDate] [datetime] NULL,
	[Active] [bit] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FanPageTask]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FanPageTask](
	[Id] [int] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[SubSiteGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[StartDate] [datetime] NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[NumberOfRetries] [int] NOT NULL,
	[PreviousPage] [nvarchar](512) NULL,
	[NextPage] [nvarchar](512) NULL,
	[IsCompleted] [bit] NOT NULL,
	[IsRunning] [bit] NOT NULL,
	[Order] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FanPageTaskCache]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FanPageTaskCache](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[SubSiteGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[StartDate] [datetime] NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[PreviousPage] [nvarchar](256) NULL,
	[NextPage] [nvarchar](256) NULL,
 CONSTRAINT [PK_FanPageTaskCache] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ImportQueue]    Script Date: 6/14/2013 4:08:47 PM ******/
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
/****** Object:  Table [dbo].[Queue]    Script Date: 6/14/2013 4:08:47 PM ******/
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
/****** Object:  Table [dbo].[SearchQueue]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SearchQueue](
	[Id] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[IsCompleted] [bit] NOT NULL,
	[Order] [int] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[IsRunning] [bit] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[NumberOfRetries] [int] NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[WordGUID] [uniqueidentifier] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[ConsoleIP] [nvarchar](128) NULL,
	[PreviousPage] [nvarchar](512) NULL,
	[NextPage] [nvarchar](512) NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_SearchQueue] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SearchQueueCache]    Script Date: 6/14/2013 4:08:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SearchQueueCache](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[WordGUID] [uniqueidentifier] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[PreviousPage] [nvarchar](512) NULL,
	[NextPage] [nvarchar](512) NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_FacebookSearchQueueCache] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SiteTask]    Script Date: 6/14/2013 4:08:47 PM ******/
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
/****** Object:  Index [IsCompletedIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [IsCompletedIndex] ON [dbo].[FacebookQueue]
(
	[IsCompleted] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IsRunningIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [IsRunningIndex] ON [dbo].[FacebookQueue]
(
	[IsRunning] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PostIDIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [PostIDIndex] ON [dbo].[FacebookQueue]
(
	[PostID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [PublishedDateIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [PublishedDateIndex] ON [dbo].[FacebookQueue]
(
	[PublishedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [URLIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [URLIndex] ON [dbo].[FacebookQueue]
(
	[URL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IsCompletedIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [IsCompletedIndex] ON [dbo].[Queue]
(
	[IsCompleted] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IsRunningIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [IsRunningIndex] ON [dbo].[Queue]
(
	[IsRunning] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [NonClusteredIndex-20121106-010654]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20121106-010654] ON [dbo].[Queue]
(
	[URL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20121106-010707]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20121106-010707] ON [dbo].[Queue]
(
	[PublishedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IsCompletedIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [IsCompletedIndex] ON [dbo].[SearchQueue]
(
	[IsCompleted] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [KeywordIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [KeywordIndex] ON [dbo].[SearchQueue]
(
	[KeywordGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [SiteGUIDIndex]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [SiteGUIDIndex] ON [dbo].[SearchQueue]
(
	[SiteGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20121106-010756]    Script Date: 6/14/2013 4:08:47 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20121106-010756] ON [dbo].[SiteTask]
(
	[SiteGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Connection] ADD  CONSTRAINT [DF_Connection_InsertedDate]  DEFAULT (getdate()) FOR [InsertedDate]
GO
ALTER TABLE [dbo].[Connection] ADD  CONSTRAINT [DF_Connection_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[FacebookRecordDispatcher] ADD  CONSTRAINT [DF_FacebookRecordDispatcher_IsCompleted]  DEFAULT ((0)) FOR [IsCompleted]
GO
ALTER TABLE [dbo].[FacebookRecordDispatcher] ADD  CONSTRAINT [DF_FacebookRecordDispatcher_InsertedDate]  DEFAULT (getdate()) FOR [InsertedDate]
GO
ALTER TABLE [dbo].[FacebookRecordDispatcher] ADD  CONSTRAINT [DF_FacebookRecordDispatcher_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[FanPageTaskCache] ADD  CONSTRAINT [DF_FanPageTaskCache_InsertedDate]  DEFAULT (getdate()) FOR [InsertedDate]
GO
ALTER TABLE [dbo].[FanPageTaskCache] ADD  CONSTRAINT [DF_FanPageTaskCache_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
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
ALTER TABLE [dbo].[SearchQueueCache] ADD  CONSTRAINT [DF_FacebookSearchQueueCache_InsertedDate]  DEFAULT (getdate()) FOR [InsertedDate]
GO
ALTER TABLE [dbo].[SearchQueueCache] ADD  CONSTRAINT [DF_FacebookSearchQueueCache_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
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
