USE [master]
GO
/****** Object:  Database [ContentAgg_ReplSub]    Script Date: 6/26/2013 8:55:00 AM ******/
CREATE DATABASE [ContentAgg_ReplSub]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'ContentAggregatorV2', FILENAME = N'D:\DB_RESTORE_ALL\ContentAggregator_Sub.mdf' , SIZE = 13568KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'ContentAggregatorV2_log', FILENAME = N'D:\DB_RESTORE_ALL\ContentAggregator_Sub_log.ldf' , SIZE = 136064KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [ContentAgg_ReplSub] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [ContentAgg_ReplSub].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [ContentAgg_ReplSub] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET ARITHABORT OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET  DISABLE_BROKER 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET RECOVERY FULL 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET  MULTI_USER 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [ContentAgg_ReplSub] SET DB_CHAINING OFF 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [ContentAgg_ReplSub] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'ContentAgg_ReplSub', N'ON'
GO
USE [ContentAgg_ReplSub]
GO
/****** Object:  StoredProcedure [dbo].[GetCMSRecordCount]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetCMSRecordCount]
	@KeywordID int,
	@SubKeywordID int,
	@SiteIDs varchar(max),
	@TagGroupID int,
	@TagIDs varchar(1024),	
	@Reviewed varchar(128),	
	@RecordUserID int,
	@UserID int,
    @StartDate datetime,
    @EndDate datetime,
    @Emotion int,
	@Deleted varchar(32),
	@Approved varchar(32)        
AS 
/*
* Description: count total record, subrecord of keyword, by advanced filter
* Params
	Emotion: 8 emotions
	SubKeywordID: -1: all
	TagGroupID: filter records that tagged by tag in this tag group		
	Bookmarked: followed, unfollowed	
	Reviewed: null, reviewed, unreviewed
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetCMSRecordCount 
	@KeywordID = 1,
	@SubKeywordID = -1,
	@SiteIDs = null,
	@TagGroupID = -1,	
	@TagIDs = null,	
	@Reviewed = null,
	@RecordUserID = -1,
	@UserID = -1,		
	@StartDate = '11/1/2013',
	@EndDate = '11/20/2013',
	@Emotion = -1,
	@Deleted = null,
	@Approved = null
*/
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	); '
	
	SET @SQLString = @SQLString + '
		select count(distinct rd.RecordID) RecordCount, count(distinct sr.SubRecordID) SubRecordCount
		from ContentCrawler.dbo.Record rd WITH(NOLOCK)
		inner join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on sr.RecordID = rd.RecordID 
		'
	
	IF @SiteIDs is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
		join ContentAggregator.dbo.Site s with(nolock) on s.GUID = rd.SiteGUID ';
	END
				
	SET @SQLString = @SQLString + ' 
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](rd.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and sr.KeywordGUID = @KeywordGUID and rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate '
	
	IF @SiteIDs is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
		and s.SiteID in( '+ @SiteIDs +' ) and (s.IsDeleted=0 or s.IsDeleted is null) and s.IsActive=1 ';
	END
		
	IF @Deleted = 'deleted'
	BEGIN
		SET @SQLString = @SQLString + ' 
		and rd.IsDeleted = 1 and sr.IsDeleted = 1 '
	END
	ELSE IF @Deleted = 'irrelevant'
	BEGIN
		SET @SQLString = @SQLString + ' 
		and rd.Irrelevant = 1 and sr.Irrelevant = 1 '
	END
	ELSE IF @Deleted = 'NotDeletedAndIrrelevnet'
	BEGIN
		SET @SQLString = @SQLString + ' 
		and rd.IsDeleted = 0 and (rd.Irrelevant = 0 or rd.Irrelevant is null) 
		and sr.IsDeleted = 0 and (sr.Irrelevant = 0 or sr.Irrelevant is null)
		'
	END
	
	IF @Reviewed = 'reviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 
		and rd.IsReviewed = 1 
		and (
				select Count(distinct sr1.SubRecordID) Reviewed
				from ContentCrawler.dbo.SubRecord sr1		
				where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr1.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
						and sr1.RecordID = rd.RecordID
						and sr1.IsDeleted = 0 
						and (sr1.Irrelevant is null or sr1.Irrelevant = 0) 
						and ( sr1.IsReviewed = 0 or sr1.IsReviewed is null)
			) = 0 '
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 		
		and ( rd.IsReviewed = 0 or rd.IsReviewed is null ) '	
	END	
	ELSE IF @Reviewed = 'unreviewedAndReviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 
		and rd.IsReviewed = 1 
		and (
				select Count(distinct sr1.SubRecordID) Reviewed
				from ContentCrawler.dbo.SubRecord sr1		
				where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr1.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
						and sr1.RecordID = rd.RecordID
						and sr1.IsDeleted = 0 
						and (sr1.Irrelevant is null or sr1.Irrelevant = 0) 
						and ( sr1.IsReviewed = 0 or sr1.IsReviewed is null)
			) <> 0 '
	END	

	if @RecordUserID  = 0
	BEGIN
		SET @SQLString = @SQLString + ' 		
		and rd.CreatedBy = 0'	
	END
	ELSE IF @RecordUserID = 1
	BEGIN
		SET @SQLString = @SQLString + ' 		
		and rd.CreatedBy <> 0'	
	END

	IF @Approved = 'approved'
	BEGIN		
		IF @TagIDs is null and @UserID = -1 and @Reviewed is null
		BEGIN
			SET @SQLString = @SQLString + ' 
			and exists (select * from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) where rd.RecordID = sr.RecordID and sr.IsApproved = 1)'
		END
	END

	--filter records by brief content emotion
	if @Emotion <> -1 and @Emotion is not null
	BEGIN
		SET @SQLString = @SQLString + '
		and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK) 
		where bc.RecordID = rd.RecordID and bc.Sentiment = @Emotion and bc.IsDeleted = 0 )
		'
	END

	if @TagIDs is not null
	BEGIN		
		SET @SQLString = @SQLString + ' 
		and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK)		
		inner join ContentCrawler.dbo.BriefContentTag bct WITH(NOLOCK) on bc.BriefContentID = bct.BriefContentID and bct.IsDeleted = 0
		inner join ContentAggregator.dbo.Tag tt WITH(NOLOCK) on bct.TagGUID = tt.TagGUID 
		where tt.TagID in ( ' + @TagIDs + ' ) bc.RecordID = rd.RecordID and bc.IsDeleted = 0 ' + (case when @UserID <> -1 then 'and bct.UserID = @UserID' else '' end) + ' )'
		
		SET @Reviewed = null;
		SET @UserID = -1;
		SET @TagGroupID = -1;
	END

	IF @UserID <> -1
	BEGIN
		SET @Reviewed = null; --if user is selected, it mean reviewed records
		SET @SQLString = @SQLString + '
		and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK)		
		where bc.RecordID = rd.RecordID and bc.UserUpdate = @UserID and bc.IsDeleted = 0 ' + (case when @Approved is not null then 'and sr.IsApproved = 1' else '' end) + ' )'
	END

	
	
	IF @TagGroupID <> -1 --all
	BEGIN		
		SET @SQLString = @SQLString + '
			and rd.RecordID in (select distinct sr.RecordID from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)			
			inner join ContentCrawler.dbo.BriefContentTag bct WITH(NOLOCK) on sr.SubRecordID = bct.SubRecordID and bct.IsDeleted = 0
			inner join ContentAggregator.dbo.Tag t with(nolock) on bct.TagGUID = t.GUID and t.TagGroupID = @TagGroupID) '
	END;					
					
	SET @ParmDefinition = '
				@KeywordID int,
				@SiteIDs varchar(max),
				@TagGroupID int,
				@TagIDs varchar(1024),
				@SubKeywordID int,	
				@RecordUserID int,									
				@UserID int,				
				@StartDate datetime,
				@EndDate datetime,
				@Emotion int';
	
	print @SQLString;
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@SiteIDs,
						@TagGroupID,
						@TagIDs,
					  	@SubKeywordID,
						@RecordUserID,									
						@UserID,						
						@StartDate,
						@EndDate,
						@Emotion;			
END


GO
/****** Object:  StoredProcedure [dbo].[GetCMSRecords]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCMSRecords]
	@KeywordID int,
	@SubKeywordID int,
	@SiteIDs varchar(max),	
	@TagGroupID int,	
	@TagIDs varchar(1024),	
	@Reviewed varchar(128),	
	@RecordUserID int,
	@UserID int,
    @StartDate datetime,
    @EndDate datetime,
    @Emotion int,
	@Deleted varchar(32),
	@Approved varchar(32),
    @Sorting varchar(128),
    @FromRecord int,
    @ToRecord int
	/*
	EXEC [GetCMSRecords] 
			@KeywordID = 12,
			@SubKeywordID = -1,
			@SiteIDs = null,
			@TagGroupID = -1,	
			@TagIDs = null,	
			@Reviewed = null,
			@RecordUserID = -1,
			@UserID = -1,		
			@StartDate = '4/1/2013',
			@EndDate = '4/30/2013',
			@Emotion = -1,
			@Deleted = 'NotDeletedAndIrrelevnet',
			@Approved = null,
			@Sorting ='PublishedDate',
			@FromRecord =25,
			@ToRecord =0
	*/
WITH RECOMPILE
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	); '
	
	SET @SQLString = @SQLString + ' 
		select rd.RecordID, rd.Title, s.URL as ''SiteURL'', s.SiteTypeID Type, rd.URL, rd.PublishedDate as ''PublishedDate'', rd.Score,rd.IsDeleted, rd.Irrelevant
		from ContentCrawler.dbo.Record rd WITH(NOLOCK) 
		join ContentAggregator.dbo.Site s with(nolock) on s.GUID = rd.SiteGUID 
		'			
			
	--Where clause
	SET @SQLString = @SQLString + ' 
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](rd.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate 
		and rd.RecordID in (	select distinct rdt.RecordID 
									from ContentCrawler.dbo.Record rdt join ContentCrawler.dbo.SubRecord srdt on rdt.RecordID=srdt.RecordID
									where	rdt.KeywordGUID = @KeywordGUID and srdt.KeywordGUID = @KeywordGUID 
												and rdt.PublishedDate >= @StartDate and rdt.PublishedDate <= @EndDate ';
											
											IF @Deleted = 'deleted'
											BEGIN
												SET @SQLString = @SQLString + ' 
												and rdt.IsDeleted = 1 and srdt.IsDeleted = 1 '
											END
											ELSE IF @Deleted = 'irrelevant'
											BEGIN
												SET @SQLString = @SQLString + ' 
												and rdt.Irrelevant = 1 and srdt.Irrelevant = 1 '
											END
											ELSE IF @Deleted = 'NotDeletedAndIrrelevnet'
											BEGIN
												SET @SQLString = @SQLString + ' 
												and rdt.IsDeleted = 0 and (rdt.Irrelevant = 0 or rdt.Irrelevant is null)
												and srdt.IsDeleted = 0 and (srdt.Irrelevant = 0 or srdt.Irrelevant is null) '
											END

		SET @SQLString = @SQLString + ' ) ';
		
	IF @SiteIDs is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
		and s.SiteID in( '+ @SiteIDs +' ) and (s.IsDeleted=0 or s.IsDeleted is null) and s.IsActive=1 ';
	END
	ELSE 
	BEGIN
		SET @SQLString = @SQLString + '
		and (s.IsDeleted=0 or s.IsDeleted is null) and s.IsActive=1 ';
	END

	IF @Deleted = 'deleted'
	BEGIN
		SET @SQLString = @SQLString + ' 
		and rd.IsDeleted = 1 '
	END
	ELSE IF @Deleted = 'irrelevant'
	BEGIN
		SET @SQLString = @SQLString + ' 
		and rd.Irrelevant = 1 '
	END
	ELSE IF @Deleted = 'NotDeletedAndIrrelevnet'
	BEGIN
		SET @SQLString = @SQLString + ' 
		and rd.IsDeleted = 0 and (rd.Irrelevant = 0 or rd.Irrelevant is null) '
	END
	--ELSE
	--BEGIN
	--	SET @SQLString = @SQLString + ' 
	--	and rd.IsDeleted = 0 and (rd.Irrelevant = 0 or rd.Irrelevant is null)'
	--END

	IF @Reviewed = 'reviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 
		and rd.IsReviewed = 1 
		and (
				select Count(distinct sr1.SubRecordID) Reviewed
				from ContentCrawler.dbo.SubRecord sr1		
				where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr1.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
						and sr1.RecordID = rd.RecordID
						and sr1.IsDeleted = 0 
						and (sr1.Irrelevant is null or sr1.Irrelevant = 0) 
						and ( sr1.IsReviewed = 0 or sr1.IsReviewed is null)
			) = 0 '
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 		
		and ( rd.IsReviewed = 0 or rd.IsReviewed is null ) '	
	END	
	ELSE IF @Reviewed = 'unreviewedAndReviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 
		and rd.IsReviewed = 1 
		and (
				select Count(distinct sr1.SubRecordID) Reviewed
				from ContentCrawler.dbo.SubRecord sr1		
				where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr1.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
						and sr1.RecordID = rd.RecordID
						and sr1.IsDeleted = 0 
						and (sr1.Irrelevant is null or sr1.Irrelevant = 0) 
						and ( sr1.IsReviewed = 0 or sr1.IsReviewed is null)
			) <> 0 '
	END

	if @RecordUserID  = 0
	BEGIN
		SET @SQLString = @SQLString + ' 		
		and rd.CreatedBy = 0'	
	END
	ELSE IF @RecordUserID = 1
	BEGIN
		SET @SQLString = @SQLString + ' 		
		and rd.CreatedBy <> 0'	
	END

	IF @Approved = 'approved'
	BEGIN		
		IF @TagIDs is null and @UserID = -1 and @Reviewed is null
		BEGIN
			SET @SQLString = @SQLString + ' 
			and exists (select * from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) where rd.RecordID = sr.RecordID and sr.IsApproved = 1)'
		END
	END

	--filter records by brief content emotion
	if @Emotion <> -1 and @Emotion is not null
	BEGIN
		SET @SQLString = @SQLString + '
		and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK) 
		where bc.RecordID = rd.RecordID and bc.Sentiment = @Emotion and bc.IsDeleted = 0 )
		'
	END


	if @TagIDs is not null
	BEGIN		
		SET @SQLString = @SQLString + ' 
		and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK)		
		inner join ContentCrawler.dbo.BriefContentTag bct WITH(NOLOCK) on bc.BriefContentID = bct.BriefContentID and bct.IsDeleted = 0
		inner join ContentAggregator.dbo.Tag tt WITH(NOLOCK) on bct.TagGUID = tt.TagGUID 
		where tt.TagID in ( ' + @TagIDs + ' ) and bc.RecordID = rd.RecordID and bc.IsDeleted = 0 ' + (case when @UserID <> -1 then 'and bct.UserID = @UserID' else '' end) + ' )'
		
		SET @Reviewed = null;
		SET @UserID = -1;
		SET @TagGroupID = -1;
	END
	
	IF @UserID <> -1
	BEGIN
		SET @Reviewed = null; --if user is selected, it mean reviewed records
		SET @SQLString = @SQLString + '
		and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK)		
		where bc.RecordID = rd.RecordID and bc.UserUpdate = @UserID and bc.IsDeleted = 0 ' + (case when @Approved is not null then 'and sr.IsApproved = 1' else '' end) + ' )'
	END
			
	IF @TagGroupID <> -1 --all
	BEGIN		
		SET @SQLString = @SQLString + '
			and rd.RecordID in (select distinct sr.RecordID from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)			
			inner join ContentCrawler.dbo.BriefContentTag bct WITH(NOLOCK) on sr.SubRecordID = bct.SubRecordID and bct.IsDeleted = 0
			inner join ContentAggregator.dbo.Tag t with(nolock) on bct.TagGUID = t.GUID and t.TagGroupID = @TagGroupID) '
	END;			
		
	SET @SQLString = @SQLString + '							
		order by rd.PublishedDate asc offset @FromRecord rows fetch next 20 rows only';	
	
	SET @ParmDefinition = '
				@KeywordID int,
				@SiteIDs varchar(max),
				@TagGroupID int,
				@TagIDs varchar(1024),
				@SubKeywordID int,	
				@RecordUserID int,									
				@UserID int,				
				@StartDate datetime,
				@EndDate datetime,
				@Emotion int,
				@FromRecord int,
				@ToRecord int';
	
	print @SQLString;	
	--print len(@SQLString)
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@SiteIDs,
						@TagGroupID,
						@TagIDs,
					  	@SubKeywordID,
						@RecordUserID,									
						@UserID,						
						@StartDate,
						@EndDate,
						@Emotion,
						@FromRecord,
						@ToRecord;			
END


GO
/****** Object:  StoredProcedure [dbo].[GetCMSSubRecordCount]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCMSSubRecordCount]
	@KeywordGUID uniqueidentifier,
	@RecordID int
AS
BEGIN	
	DECLARE @LocRecordID int
	SET @LocRecordID = @RecordID
	select 
		(select Count(distinct sr.SubRecordID) Reviewed
			from ContentCrawler.dbo.SubRecord sr		
			where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
					and sr.RecordID = @LocRecordID 
					and sr.IsDeleted = 0 
					and sr.IsReviewed = 1
		) Reviewed 
		, (select count(sr1.SubRecordID) 
			from ContentCrawler.dbo.SubRecord sr1 
			where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr1.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
					and sr1.RecordID = @LocRecordID 
					and sr1.IsDeleted = 0 
					and (sr1.Irrelevant is null or sr1.Irrelevant = 0) 
			) Total
			
END

GO
/****** Object:  StoredProcedure [dbo].[GetCMSSubRecordCount_2]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetCMSSubRecordCount_2]
	@KeywordGUID uniqueidentifier,
	@RecordID int,
	@StartDate datetime,
    @EndDate datetime

	/*
	EXEC [GetCMSSubRecordCount_2] 
	@RecordID = 310313,
	@KeywordGUID='1c06e0d6-5c7f-48db-b2dd-1d0e15c84f13',
	@StartDate = '4/15/2013 00:00:00',
	@EndDate = '4/21/2013 23:59:59'
	*/
AS
BEGIN	
	DECLARE @LocRecordID int
	SET @LocRecordID = @RecordID
	select 
		(select Count(distinct sr.SubRecordID) Reviewed
			from ContentCrawler.dbo.SubRecord sr		
			where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
					and sr.RecordID = @LocRecordID 
					and sr.IsDeleted = 0 
					and sr.IsReviewed = 1
					and sr.PublishedDate >= @StartDate and sr.PublishedDate <= @EndDate
		) Reviewed 
		, (select count(sr1.SubRecordID) 
			from ContentCrawler.dbo.SubRecord sr1 
			where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr1.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
					and sr1.RecordID = @LocRecordID 
					and sr1.IsDeleted = 0 
					and (sr1.Irrelevant is null or sr1.Irrelevant = 0) 
					and sr1.PublishedDate >= @StartDate and sr1.PublishedDate <= @EndDate
			) Total
			
END


GO
/****** Object:  StoredProcedure [dbo].[GetCMSSubRecordCountInRange]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
* Description: count reviewed subrecords in date range, and total in all time
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetCMSSubRecordCountInRange 
	@KeywordGUID = '6F2A0198-08C0-490B-84D8-E0631187F9A7',
	@RecordID = 1708,
	@StartDate = '2/10/2012',
	@EndDate = '2/12/2013'
*/
CREATE PROCEDURE [dbo].[GetCMSSubRecordCountInRange]
	@KeywordGUID uniqueidentifier,
	@RecordID int,
	@StartDate datetime,
    @EndDate datetime
WITH RECOMPILE
AS
BEGIN	
	declare @LocRecordID int; SET @LocRecordID = @RecordID;
	declare @LocStartDate datetime; set @LocStartDate = @StartDate;
	declare @LocEndDate datetime; set @LocEndDate = @EndDate
	select 
	(select Count(distinct sr.SubRecordID) from ContentCrawler.dbo.SubRecord sr 		
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and sr.RecordID = @LocRecordID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and (sr.Irrelevant is null or sr.Irrelevant = 0)) Reviewed,
	(select Count(distinct sr.SubRecordID) from ContentCrawler.dbo.SubRecord sr 
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)		
		and sr.RecordID = @LocRecordID and sr.PublishedDate between @LocStartDate and @LocEndDate and sr.IsReviewed = 1 and sr.IsDeleted = 0 and (sr.Irrelevant is null or sr.Irrelevant = 0)) ReviewedInRange,
	(select count(sr2.SubRecordID) from ContentCrawler.dbo.SubRecord sr2 
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr2.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and sr2.RecordID = @LocRecordID and sr2.PublishedDate between @LocStartDate and @LocEndDate and sr2.IsDeleted = 0 and (sr2.Irrelevant is null or sr2.Irrelevant = 0) ) TotalInRange,
	(select count(sr1.SubRecordID) from ContentCrawler.dbo.SubRecord sr1
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr1.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and sr1.RecordID = @LocRecordID and sr1.IsDeleted = 0 and (sr1.Irrelevant is null or sr1.Irrelevant = 0) ) Total	
END

GO
/****** Object:  StoredProcedure [dbo].[GetCMSSubRecords]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCMSSubRecords]
	@RecordID int,	
	@KeywordGUID uniqueidentifier,
	@TagGroupID int,		
	@TagIDs varchar(1024),
	@Reviewed varchar(128),	
	@UserID int,
    @StartDate datetime,
    @EndDate datetime,
    @Emotion int,
	@Deleted varchar(32),
	@Approved varchar(32), 
	@Words nvarchar(1024),   
    @FromRecord int,
    @ToRecord int,
	@Pre int,
	@Post int
WITH RECOMPILE
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	declare @SQLUserID nvarchar(512);
	set @SQLUserID = '';
	if @UserID <> -1
	BEGIN
		set @SQLUserID = 'and bc.UserID = ' + CONVERT(varchar(5), @UserID)
	END
				
	SET @SQLString = '
		declare @srtb table
		(
			RowNumber int,
			SubRecordID int,
			Content nvarchar(max),
			Author nvarchar(256),
			PublishedDate datetime,
			IsDelete bit,
			Irrelevant bit,
			IsApproved bit,
			SentimentID int
		)

		insert into @srtb (RowNumber, SubRecordID, Content, Author, PublishedDate, IsApproved, IsDelete, Irrelevant, SentimentID)
		select ROW_NUMBER() OVER(ORDER BY sr.PublishedDate ASC) , sr.SubRecordID, sr.Content, sr.Author, sr.PublishedDate, sr.IsApproved, sr.IsDeleted, sr.Irrelevant, sr.SentimentID
		from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and sr.RecordID = @RecordID '
	if @Pre is null or @Post is null
	BEGIN
		IF @Reviewed = 'reviewed'
		BEGIN					
			set @SQLString = @SQLString + ' and sr.IsReviewed = 1'
		END	
		ELSE IF @Reviewed = 'reviewedinrange'
		BEGIN		
			SET @SQLString = @SQLString + ' 
			and sr.PublishedDate between @StartDate and @EndDate and sr.IsReviewed = 1 '			
		END	
		ELSE IF @Reviewed = 'unreviewed'
		BEGIN		
			SET @SQLString = @SQLString + ' 
			  and sr.IsReviewed = 0 '			
		END	
		ELSE IF @Reviewed = 'unreviewedinrange'
		BEGIN					
			SET @SQLString = @SQLString + ' 
			and sr.PublishedDate between @StartDate and @EndDate 
			and sr.IsReviewed = 0 '			
		END	
		ELSE IF @Reviewed = 'allinrange'
		BEGIN					
			SET @SQLString = @SQLString + ' 
			and sr.PublishedDate between @StartDate and @EndDate'
		END	
		ELSE IF @Reviewed = 'approved'
		BEGIN					
			SET @SQLString = @SQLString + ' 
			and sr.IsApproved = 1 and sr.IsReviewed = 1 '			
		END
		ELSE IF @Reviewed = 'unapproved'
		BEGIN					
			SET @SQLString = @SQLString + ' 
			and sr.IsApproved = 0 and sr.IsReviewed = 1 '
		END
		
		IF @Emotion <> -1 and @Emotion is not null
		BEGIN
			SET @SQLString = @SQLString + ' 
			and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK) 
			where bc.SubRecordID = sr.SubRecordID and bc.Sentiment = @Emotion and bc.IsDeleted = 0 ) '
		END

		SET @SQLString = @SQLString + ' 
		select tb.SubRecordID, tb.Content, tb.Author, tb.PublishedDate, tb.IsApproved,tb.IsDelete, tb.Irrelevant, tb.SentimentID
			,(select count(1) from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK) where bc.SubRecordID = tb.SubRecordID and bc.IsDeleted = 0) BriefContents
		from @srtb tb
		where tb.RowNumber > @FromRecord and tb.RowNumber <= @ToRecord
		order by tb.RowNumber asc;

		select count(1) Total from @srtb
		';
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		declare @bctb table --contain rownumver that has brief contents
		(
			RowNumber int
		)
		insert into @bctb (RowNumber)
		select distinct RowNumber
		from (
			select RowNumber
			from @srtb tb
			inner join ContentCrawler.dbo.BriefContent bc WITH(NOLOCK) on bc.SubRecordID = tb.SubRecordID and bc.IsDeleted = 0 ' + @SQLUserID + '
			union all
			select RowNumber
			from @srtb tb
			inner join ContentCrawler.dbo.SubRecord sr on tb.SubRecordID = sr.SubRecordID 
			and contains(sr.Content, ''' + @Words + ''')
		) a

		select distinct tb.SubRecordID, tb.Content, tb.Author, tb.PublishedDate, tb.IsApproved,tb.IsDelete, tb.Irrelevant, tb.SentimentID
		,(select count(1) from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK) where bc.SubRecordID = tb.SubRecordID and bc.IsDeleted = 0) BriefContents
		from @srtb tb
		inner join @bctb bctb on tb.RowNumber >= bctb.RowNumber - @Pre and tb.RowNumber <= bctb.RowNumber + @Post
		order by tb.PublishedDate asc;
		
		select count(1) Total from @srtb'

	END	
	
	SET @ParmDefinition = '
				@RecordID int,
				@KeywordGUID uniqueidentifier,				        
				@FromRecord int,
				@ToRecord int,
				@Pre int,
				@Post int,
				@Emotion int,
				@StartDate datetime,
				@EndDate datetime';
	print @SQLString
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID,
						@KeywordGUID,
					  	@FromRecord,
					  	@ToRecord,						
						@Pre,
						@Post,
						@Emotion,
						@StartDate,
						@EndDate;			
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBAuthorCount]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBAuthorCount]
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime
WITH recompile
AS
BEGIN
	SET NOCOUNT ON
	declare @StartTimeID int
	declare @EndTimeID int	
	
	set @StartTimeID = (select DimTimeID from WareHouse.dbo.DimTime where datediff(dd,[DATE], @StartDate) = 0)
	set @EndTimeID = (select DimTimeID from WareHouse.dbo.DimTime where DATEDIFF(dd, [DATE], @EndDate) = 0)
	
	select top 10 fka.Author, s.URLName, sum(fka.Total) Total
	from WareHouse.dbo.FactKeywordAuthor fka
		inner join ContentAggregator.dbo.Site s with(NOLOCK) on fka.SiteID = s.SiteID
	where fka.DimTimeID between @StartTimeID and @EndTimeID
		and fka.KeywordID = @KeywordID
	group by fka.Author, s.URLName
	order by Total desc
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBBuzzByDate]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBBuzzByDate]
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime,
	@SiteType int
WITH recompile
AS
BEGIN
	SET NOCOUNT ON
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from WareHouse.dbo.DimTime where datediff(dd,[DATE], @StartDate) = 0)
	set @EndTimeID = (select DimTimeID from WareHouse.dbo.DimTime where DATEDIFF(dd, [DATE], @EndDate) = 0)
	
	select dt.Date, ISNULL(rightside.Total, 0) Total
	from WareHouse.dbo.DimTime dt
	left join (
			select dt.Date, sum(fks.Total) as Total
			from WareHouse.dbo.FactKeywordSite fks inner join WareHouse.dbo.DimTime dt on fks.DimTimeID = dt.DimTimeID
				inner join ContentAggregator.dbo.Site s on fks.SiteID = s.SiteID
			where fks.DimTimeID between @StartTimeID and @EndTimeID
				and fks.KeywordID = @KeywordID
				and (@SiteType = -1 or @SiteType = s.SiteTypeID)
			group by dt.Date) 
		rightside on dt.Date = rightside.Date
	where dt.DimTimeID between @StartTimeID and @EndTimeID 
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBConversationExport]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBConversationExport]
	@KeywordID int,
	@SiteIDs varchar(1024),
	@Emotion int,
	@TagGroupID int,
    @StartDate datetime,
    @EndDate datetime	
AS
/*
* Description: get records for context records
* Params
* Sample:
EXEC GetDBConversationExport 
	@KeywordID = 1,
	@SiteIDs = null,
	@Emotion = 1,
	@TagGroupID = 196,
	@StartDate = '1/16/2013 12:00:00 AM',
	@EndDate = '1/29/2013 11:59:59 PM'	
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @SQLString nvarchar(max);	

	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier	
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	);
	declare @TagGroupGUID uniqueidentifier
	set @TagGroupGUID = (select GUID from ContentAggregator.dbo.TagGroup where TagGroupID = @TagGroupID	);

	DECLARE @Pos int		
	-- create temp site id
	DECLARE @TempSite table
	(
		SiteID int,
		SiteGUID uniqueidentifier,
		URL varchar(1024),
		SiteTypeID int
	)
	DECLARE @SiteID varchar(10)

	SET @SiteIDs = LTRIM(RTRIM(@SiteIDs))+ '',''
	SET @Pos = CHARINDEX('','', @SiteIDs, 1)

	IF REPLACE(@SiteIDs, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @SiteID = LTRIM(RTRIM(LEFT(@SiteIDs, @Pos - 1)))
			IF @SiteID <> ''''
			BEGIN
				INSERT INTO @TempSite (SiteID, SiteGUID, URL, SiteTypeID) select SiteID, GUID, URL, SiteTypeID from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @SiteIDs = RIGHT(@SiteIDs, LEN(@SiteIDs) - @Pos)
			SET @Pos = CHARINDEX('','', @SiteIDs, 1)
		END
	END;	
	'
	
	SET @SQLString = @SQLString + '
		select rightside.SubRecordID ID, r.Title, rightside.Content, rightside.BriefContent, rightside.URL , rightside.PublishedDate ''Published Date'', 
		rightside.[Group], rightside.Sub, rightside.Tags, rightside.Sentiment, rightside.Behavior, s.urlname ''Source'', st.Name ''Channel'' , rightside.Author
		from ContentCrawler.dbo.Record r with( NOLOCK)
		inner join
			(select sr.RecordID, sr.SubRecordID , sr.Content, bc.Content BriefContent, sr.URL , sr.PublishedDate, sr.Author, 
				(select distinct pg.Name + '';''
				from ContentCrawler.dbo.BriefContentTag bct
				 inner join ContentAggregator.dbo.TagGroup tg on bct.TagGroupGUID = tg.GUID
				 left join ContentAggregator.dbo.TagGroup pg on tg.ParentID = pg.TagGroupID
				 where bct.BriefContentID = bc.BriefContentID and bct.IsDeleted = 0
				 for xml path('''')) ''Group'',
				(select distinct tg.Name + '';'' 
				from ContentCrawler.dbo.BriefContentTag bct
				 inner join ContentAggregator.dbo.TagGroup tg on bct.TagGroupGUID = tg.GUID
				 where bct.BriefContentID = bc.BriefContentID and bct.IsDeleted = 0
				 for xml path('''')) Sub,
				(select t.Word + '';'' 
				from ContentCrawler.dbo.BriefContentTag bct
				 inner join ContentAggregator.dbo.Tag t on bct.TagGUID = t.GUID
				 where bct.BriefContentID = bc.BriefContentID and bct.IsDeleted = 0 and t.IsDeleted = 0
				 for xml path('''')) Tags,
				(select t.Name from ContentAggregator.dbo.Type t
				where bc.Sentiment = t.TypeID ) Sentiment,
				(select t.Word from ContentAggregator.dbo.Tag t	
				where t.TagId = sr.SentimentID) Behavior
			from ContentCrawler.dbo.SubRecord sr with( NOLOCK)	
			inner join ContentCrawler.dbo.BriefContent bc with(NOLOCK) on sr.SubRecordID = bc.SubRecordID and bc.IsDeleted = 0 ' + 
			(CASE WHEN (@Emotion is not null and @Emotion <> -1) THEN 'and bc.Sentiment = @Emotion' ELSE ' ' END) +
			(CASE WHEN (@TagGroupID is not null and @TagGroupID <> -1) THEN '
			inner join ContentCrawler.dbo.BriefContentTag bct on bct.BriefContentID = bc.BriefContentID and bct.TagGroupGUID = @TagGroupGUID' ELSE ' ' END) + 
			'
			where ContentCrawler.$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = ContentCrawler.$partition.[KeywordGUIDPartitionFunction]( @KeywordGUID)
			and sr.KeywordGUID = @KeywordGUID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @startdate and @enddate
		) rightside on r.RecordID = rightside.RecordID 
		'
	

	IF @SiteIDs is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
		inner join @TempSite s on s.SiteGUID = r.SiteGUID '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		left join ContentAggregator.dbo.Site s with(nolock) on s.GUID = r.SiteGUID '
	END;
	SET @SQLString = @SQLString +	'		
		left join ContentAggregator.dbo.SiteType st on s.SiteTypeID= st.SiteTypeID
		where ContentCrawler.$partition.[KeywordGUIDPartitionFunction](r.KeywordGUID) = ContentCrawler.$partition.[KeywordGUIDPartitionFunction]( @KeywordGUID)
		and r.IsDeleted = 0 '			
	
	SET @ParmDefinition = '
				@KeywordID int,
				@SiteIDs varchar(1024),
				@Emotion int,
				@TagGroupID int,
				@StartDate datetime,
				@EndDate datetime
				';
	
	print @SQLString;
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@SiteIDs,	
						@Emotion,
						@TagGroupID,				
						@StartDate,
						@EndDate;
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBEmotionCounts]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBEmotionCounts]
	@KeywordGUID uniqueidentifier,
	@RecordID int,	
	@TagGroupID int,	
	@TagIDs varchar(1024),
    @Emotion int,
	@StartDate datetime,
    @EndDate datetime	
WITH RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	select bc.Sentiment, count(*) Total
	from ContentCrawler.dbo.BriefContent bc
	inner join ContentCrawler.dbo.SubRecord sr on bc.SubRecordID = sr.SubRecordID and bc.IsDeleted = 0 
	and sr.RecordID = @RecordID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate	
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	group by bc.Sentiment				
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBEmotions]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBEmotions]
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime
WITH recompile
AS
BEGIN
	SET NOCOUNT ON
	declare @StartTimeID int
	declare @EndTimeID int	
	
	set @StartTimeID = (select DimTimeID from WareHouse.dbo.DimTime where datediff(dd,[DATE], @StartDate) = 0)
	set @EndTimeID = (select DimTimeID from WareHouse.dbo.DimTime where DATEDIFF(dd, [DATE], @EndDate) = 0)
	
	select fkse.Sentiment, t.Name, SUM(fkse.Total) as Total
	from WareHouse.dbo.FactKeywordSiteEmotion fkse
		inner join Site s on s.SiteID = fkse.SiteID
		inner join Type t on t.TypeID = fkse.Sentiment
	where fkse.DimTimeID between @StartTimeID and @EndTimeID
		and fkse.KeywordID = @KeywordID
	group by fkse.Sentiment, t.Name	
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBFactCount]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDBFactCount]
	@KeywordGUID uniqueidentifier,	
	@StartDate datetime,
	@EndDate datetime
WITH RECOMPILE
AS
/*
* Description: 
* Sample:
EXEC GetDBFactCount 
	@KeywordGUID = 'F1692832-C5B3-453B-91C6-E2A34E406205',	
	@StartDate = '2013-03-10 00:00:00',
	@EndDate = '2013-03-11 10:10:00'
*/
BEGIN		
	
	declare @StartInsertedDate datetime = DATEADD(DD,0,CONVERT(datetime,CONVERT(VARCHAR(10), @StartDate, 111)+' 00:00:00'));

	select  t.Name, count(distinct bc.BriefContentID) Total
	from ContentCrawler.dbo.SubRecord sr with(NOLOCK)
			inner join ContentCrawler.dbo.BriefContent bc on sr.SubRecordID = bc.SubRecordID
			inner join ContentCrawler.dbo.BriefContentTag bct on bct.BriefContentID = bc.BriefContentID
			inner join Type t on t.TypeID = bc.Sentiment
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
			and sr.PublishedDate between @StartInsertedDate and @EndDate
			and bc.InsertedDate between @StartDate and @EndDate
			and sr.IsReviewed = 1 and sr.IsDeleted = 0 		 
			and bc.IsDeleted = 0 and bct.IsDeleted = 0
	group by t.Name
	
	union

	select 'Site' 'Name', count(distinct sr.SiteGUID) Total
	from ContentCrawler.dbo.SubRecord sr with(NOLOCK)	
			inner join ContentCrawler.dbo.BriefContent bc  on sr.SubRecordID = bc.SubRecordID
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
			and sr.IsReviewed = 1 and sr.IsDeleted = 0 
			and bc.InsertedDate between @StartDate and @EndDate
			and sr.PublishedDate between @StartInsertedDate and @EndDate
	
	union

	select 'Voice' 'Name', count(distinct sr.Author) Total
	from ContentCrawler.dbo.SubRecord sr with(NOLOCK)	
			inner join ContentCrawler.dbo.BriefContent bc  on sr.SubRecordID = bc.SubRecordID
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
			and sr.IsReviewed = 1 and sr.IsDeleted = 0 
			and bc.InsertedDate between @StartDate and @EndDate
			and sr.PublishedDate between @StartInsertedDate and @EndDate
		
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBLatestBriefContents]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDBLatestBriefContents]
	@KeywordGUID uniqueidentifier,
	@Sentiment int,
	@StartDate datetime,
	@EndDate datetime
WITH RECOMPILE
AS
/*
* Description: 
* Sample:
EXEC GetDBLatestBriefContents 
	@KeywordGUID = '6F2A0198-08C0-490B-84D8-E0631187F9A7',
	@Sentiment = 1,
	@StartDate = '2013-01-17 23:29:55',
	@EndDate = '2013-01-30 23:29:55'
*/
BEGIN		
	
	declare @StartInsertedDate datetime = DATEADD(DD,0,CONVERT(datetime,CONVERT(VARCHAR(10), @StartDate, 111)+' 00:00:00'));

	select distinct top 100 bc.BriefContentID, bc.Content, sr.PublishedDate, sr.Author, sr.URL, s.URLName
	from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK)
			inner join ContentCrawler.dbo.BriefContentTag bct WITH(NOLOCK) on bct.BriefContentID = bc.BriefContentID 
			inner join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on bc.SubRecordID = sr.SubRecordID
			inner join ContentAggregator.dbo.Site s WITH(NOLOCK) on sr.SiteGUID = s.GUID
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID) 
			and sr.KeywordGUID = @KeywordGUID and sr.IsReviewed = 1 and sr.IsDeleted = 0 
			and sr.PublishedDate between @StartInsertedDate and @EndDate
			and bc.InsertedDate between @StartDate and @EndDate
			and bc.Sentiment = @Sentiment and bc.IsDeleted = 0 and bct.IsDeleted = 0 and bc.IsDeleted = 0
	order by bc.BriefContentID desc
			
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBLiveMonitoringBuzzTrend]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
* Description: 
* History
* Sample:
EXEC GetDBLiveMonitoringBuzzTrend 
	@KeywordID = 1,
	@Date = '1/19/2013 21:00:00'	
*/
CREATE PROCEDURE [dbo].[GetDBLiveMonitoringBuzzTrend]
	@KeywordID int,
	@Date datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	--get current hour 
	declare @CurDate datetime, @iDate datetime	
	set @CurDate = GETDATE()
	set @iDate = DATEADD(hh, 1, @Date)
	DECLARE @TempHour table
	(
		[Hour] int		
	)
	
	while @iDate <= @CurDate
	begin		
		insert into @TempHour values (datepart(HH, @iDate ))		
		set @iDate = DATEADD(hh, 1, @iDate)
	end
	
	select leftside.Hour, rightside.Buzz
	from @TempHour leftside
	left join (		
		select DATEPART(hour, sr.PublishedDate) 'Hour', COUNT(sr.SubRecordID) as Buzz
		from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and sr.KeywordGUID = @KeywordGUID and sr.IsDeleted = 0 and sr.PublishedDate between @Date and GETDATE()
		group by DATEPART(Hour, sr.PublishedDate)
	) rightside on leftside.Hour = rightside.Hour
	
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBLiveMonitoringLatestRecords]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
* Description: get latest records for emotion boomerang
* Params
	@KeywordID: 
	@RecordID: 
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC [GetDBLiveMonitoringLatestRecords] 
	@KeywordID = 1,
	@RecordID = null,
	@StartDate = '1/19/2013',
	@EndDate = '1/20/2013',
	@FromRecord = 0,
	@ToRecord = 10

*/
CREATE PROCEDURE [dbo].[GetDBLiveMonitoringLatestRecords]
	@KeywordID int,
	@RecordID int,
	@StartDate datetime,
	@EndDate datetime,
	@FromRecord int,
	@ToRecord int
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON	
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	);
	'
	SET @SQLString = @SQLString + '
			select r.RecordID, r.Title, r.Author, r.URL, s.URL as ''SiteURL'', r.PublishedDate, r.Score, rightside.SubRecords
			from ContentCrawler.dbo.Record r WITH(NOLOCK)
			inner join 
				(select sr.RecordID, COUNT(sr.SubRecordID) as SubRecords
				from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)	
				where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
				and sr.KeywordGUID = @KeywordGUID and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate
				group by sr.RecordID 
				having COUNT(sr.SubRecordID) > 0				
				) rightside on r.RecordID = rightside.RecordID
			inner join ContentAggregator.dbo.Site s on r.SiteGUID = s.GUID
			where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](r.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID) 								
			and r.KeywordGUID = @KeywordGUID ' + (case when @RecordID is not null then ' and r.RecordID > @RecordID ' else '' end) + ' and r.IsDeleted = 0
			order by r.PublishedDate desc ' + case when @RecordID is null then 'offset @FromRecord rows fetch next 20 rows only' else '' end
	print @Sqlstring
	SET @ParmDefinition = '
				@KeywordID int,
				@RecordID int,
				@StartDate datetime,
				@EndDate datetime,
				@FromRecord int,
				@ToRecord int';

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@RecordID,
						@StartDate,
						@EndDate,
						@FromRecord,
						@ToRecord;			
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBLiveMonitoringRelatedMentions]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetDBLiveMonitoringRelatedMentions 
	@KeywordID = 1,
	@Date = '2013-01-1 03:29:55'	
*/
CREATE PROCEDURE [dbo].[GetDBLiveMonitoringRelatedMentions]
	@KeywordID int,
	@Date datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
		
	select COUNT(distinct sr.SubRecordID) as Buzz
	from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	and sr.KeywordGUID = @KeywordGUID and sr.IsDeleted = 0 and sr.PublishedDate between @Date and GETDATE() 
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBLiveMonitoringTopSources]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetDBLiveMonitoringTopSources 
	@KeywordID = 1,
	@Date = '1/1/2013'	
*/
CREATE PROCEDURE [dbo].[GetDBLiveMonitoringTopSources]
	@KeywordID int,
	@Date datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	
	select top 10 s.Name,s.URLName, s.URL, COUNT(1) as NoOfPosts
	from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
	inner join ContentAggregator.dbo.Site s WITH(NOLOCK) on s.GUID = sr.SiteGUID	
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	and sr.KeywordGUID = @KeywordGUID and sr.IsDeleted = 0 and sr.PublishedDate between @Date and GETDATE()
	group by s.Name, s.URLName, s.URL
	order by NoOfPosts desc		
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBLiveMonitoringTopTopics]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetDBLiveMonitoringTopTopics 
	@KeywordID = 1,
	@Date = '2013-01-17 23:29:55'	
*/
CREATE PROCEDURE [dbo].[GetDBLiveMonitoringTopTopics]
	@KeywordID int,
	@Date datetime
WITH RECOMPILE
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	
	select r.RecordID, r.Title, r.URL, r.PublishedDate, rightside.NoOfComments, rightside.NoOfAuthors
	from ContentCrawler.dbo.Record r WITH(NOLOCK)
	inner join 
		(select top 10 sr.RecordID, COUNT(sr.SubRecordID) as NoOfComments, COUNT(distinct sr.Author) NoOfAuthors
		from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)	
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and sr.KeywordGUID = @KeywordGUID and sr.IsDeleted = 0 and sr.PublishedDate between @Date and GETDATE()
		group by sr.RecordID 
		having COUNT(sr.SubRecordID) > 0
		order by NoOfComments desc		
		) rightside on r.RecordID = rightside.RecordID
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](r.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID) 
	and r.IsDeleted = 0	
				
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBRecords]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBRecords]
	@KeywordID int,
	@SiteIDs varchar(1024),
	@Emotion int,
	@TagGroupID int,
    @StartDate datetime,
    @EndDate datetime,
	@FromRecord int,
	@ToRecord int
AS
/*
* Description: get records for context records
* Params
* Sample:
EXEC GetDBRecords 
	@KeywordID = 1,
	@SiteIDs = null,
	@Emotion = 1,
	@TagGroupID = -1,
	@StartDate = '1/16/2013 12:00:00 AM',
	@EndDate = '1/29/2013 11:59:59 PM',
	@FromRecord = 0,
	@ToRecord = 30
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @SQLString nvarchar(max);
	DECLARE @SQLSelect nvarchar(max);
	DECLARE @SQLWhere nvarchar(max);
	DECLARE @SQLOrder nvarchar(max);
	DECLARE @SQLGroup nvarchar(max);

	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	);
	declare @TagGroupGUID uniqueidentifier
	set @TagGroupGUID = (select GUID from ContentAggregator.dbo.TagGroup where TagGroupID = @TagGroupID	);

	DECLARE @Pos int		
	-- create temp site id
	DECLARE @TempSite table
	(
		SiteID int,
		SiteGUID uniqueidentifier,
		URL varchar(1024),
		SiteTypeID int
	)
	DECLARE @SiteID varchar(10)

	SET @SiteIDs = LTRIM(RTRIM(@SiteIDs))+ '',''
	SET @Pos = CHARINDEX('','', @SiteIDs, 1)

	IF REPLACE(@SiteIDs, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @SiteID = LTRIM(RTRIM(LEFT(@SiteIDs, @Pos - 1)))
			IF @SiteID <> ''''
			BEGIN
				INSERT INTO @TempSite (SiteID, SiteGUID, URL, SiteTypeID) select SiteID, GUID, URL, SiteTypeID from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @SiteIDs = RIGHT(@SiteIDs, LEN(@SiteIDs) - @Pos)
			SET @Pos = CHARINDEX('','', @SiteIDs, 1)
		END
	END;	
	'
	
	SET @SQLSelect = ' 
		select r.RecordID, r.Title, ISNULL(s.URL, '''') as SiteURL, r.URL, r.PublishedDate as PublishedDate,			
			count(*) SubRecords '
	SET @SQLWhere = '
		from ContentCrawler.dbo.Record r with(NOLOCK) 
		inner join ContentCrawler.dbo.SubRecord sr with(NOLOCK) on r.RecordID = sr.RecordID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and (sr.PublishedDate between @StartDate and @EndDate) '
	
	IF @Emotion is not null and @Emotion <> -1
	BEGIN
		SET @SQLWhere = @SQLWhere + '
		inner join ContentCrawler.dbo.BriefContent bc with(NOLOCK) on sr.SubRecordID = bc.SubRecordID and bc.Sentiment = @Emotion and bc.IsDeleted = 0 '
	END
	
	IF @TagGroupID is not null and @TagGroupID <> -1
	BEGIN
		IF @Emotion is not null and @Emotion <> -1
		BEGIN
			SET @SQLWhere = @SQLWhere + '
			inner join ContentCrawler.dbo.BriefContentTag bct with(NOLOCK) on bct.BriefContentID = bc.BriefContentID and bct.TagGroupGUID = @TagGroupGUID '
		END
		ELSE
		BEGIN
			SET @SQLWhere = @SQLWhere + '
			inner join ContentCrawler.dbo.BriefContent bc with(NOLOCK) on sr.SubRecordID = bc.SubRecordID and bc.IsDeleted = 0
			inner join ContentCrawler.dbo.BriefContentTag bct with(NOLOCK) on bct.BriefContentID = bc.BriefContentID and bct.TagGroupGUID = @TagGroupGUID '
		END
	END

	IF @SiteIDs is NOT NULL
	BEGIN
		SET @SQLWhere = @SQLWhere + '
		inner join @TempSite s on s.SiteGUID = r.SiteGUID '
	END
	ELSE
	BEGIN
		SET @SQLWhere = @SQLWhere + '
		left join Site s with(nolock) on s.GUID = r.SiteGUID '
	END;
	SET @SQLWhere = @SQLWhere +	'
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](r.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and r.KeywordGUID = @KeywordGUID		
		and r.IsReviewed = 1 and r.IsDeleted = 0  '
	SET @SQLGroup = ' group by r.RecordID, r.Title, s.URL, r.URL, r.PublishedDate having count(*) > 0 '
	SET @SQLOrder = '		
		order by r.PublishedDate desc offset @FromRecord rows fetch next (@ToRecord - @FromRecord) rows only '
	
	SET @SQLString = @SQLString + @SQLSelect + @SQLWhere + @SQLGroup + @SQLOrder;
	
	SET @SQLString = @SQLString + '
		select count(distinct r.RecordID) Total ' + @SQLWhere;
	
	SET @ParmDefinition = '
				@KeywordID int,
				@SiteIDs varchar(1024),
				@Emotion int,
				@TagGroupID int,
				@StartDate datetime,
				@EndDate datetime,
				@FromRecord int,
				@ToRecord int';
	
	print @SQLString;
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@SiteIDs,	
						@Emotion,
						@TagGroupID,				
						@StartDate,
						@EndDate,						
						@FromRecord,
						@ToRecord;
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBRecords_AllKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[GetDBRecords_AllKeyword]
	@KeywordID nvarchar(1024),
	@SiteIDs varchar(1024),
	@Emotion int,
	@TagGroupID int,
    @StartDate datetime,
    @EndDate datetime,
	@FromRecord int,
	@ToRecord int
AS
/*
* Description: get records for context records
* Params
* Sample:
EXEC [GetDBRecords_AllKeyword]
	@KeywordID = '72,63,23',
	@SiteIDs = null,
	@Emotion = 1,
	@TagGroupID = -1,
	@StartDate = '1/16/2013 12:00:00 AM',
	@EndDate = '1/29/2013 11:59:59 PM',
	@FromRecord = 0,
	@ToRecord = 30
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @SQLString nvarchar(max);
	DECLARE @SQLSelect nvarchar(max);

	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	declare @TagGroupGUID uniqueidentifier
	set @TagGroupGUID = (select GUID from ContentAggregator.dbo.TagGroup where TagGroupID = @TagGroupID	);

	DECLARE @Pos int		
	-- create temp site id
	DECLARE @TempSite table
	(
		SiteID int,
		SiteGUID uniqueidentifier,
		URL varchar(1024),
		SiteTypeID int
	)
	DECLARE @SiteID varchar(10)

	SET @SiteIDs = LTRIM(RTRIM(@SiteIDs))+ '',''
	SET @Pos = CHARINDEX('','', @SiteIDs, 1)

	IF REPLACE(@SiteIDs, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @SiteID = LTRIM(RTRIM(LEFT(@SiteIDs, @Pos - 1)))
			IF @SiteID <> ''''
			BEGIN
				INSERT INTO @TempSite (SiteID, SiteGUID, URL, SiteTypeID) select SiteID, GUID, URL, SiteTypeID from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @SiteIDs = RIGHT(@SiteIDs, LEN(@SiteIDs) - @Pos)
			SET @Pos = CHARINDEX('','', @SiteIDs, 1)
		END
	END;	
	'
	
	SET @SQLSelect = ' declare @TempGetDBRecords table
						(
							RecordID int,
							Title nvarchar(1024),
							SiteURL nvarchar(1024),
							URL nvarchar(1024),
							PublishedDate datetime,
							SubRecordID int 
						)

						DECLARE @tmpKeywordGUID uniqueidentifier;
						DECLARE c1 CURSOR FOR (						
													select GUID from ContentAggregator.dbo.Keyword where KeywordID in ( '+@KeywordID+' )
												);

							OPEN c1   
							FETCH NEXT FROM c1 
										INTO @tmpKeywordGUID
 
							WHILE @@FETCH_STATUS = 0   
							BEGIN ';

	SET @SQLSelect += ' 
		insert into @TempGetDBRecords 
		select r.RecordID, r.Title, ISNULL(s.URL, '''') as SiteURL, r.URL, r.PublishedDate as PublishedDate, sr.SubRecordID 	
		from ContentCrawler.dbo.Record r with(NOLOCK) 
		inner join ContentCrawler.dbo.SubRecord sr with(NOLOCK) on r.RecordID = sr.RecordID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and (sr.PublishedDate between @StartDate and @EndDate) '
	
	IF @Emotion is not null and @Emotion <> -1
	BEGIN
		SET @SQLSelect += '
		inner join ContentCrawler.dbo.BriefContent bc with(NOLOCK) on sr.SubRecordID = bc.SubRecordID and bc.Sentiment = @Emotion and bc.IsDeleted = 0 '
	END
	
	IF @TagGroupID is not null and @TagGroupID <> -1
		BEGIN
			IF @Emotion is not null and @Emotion <> -1
			BEGIN
				SET @SQLSelect += '
				inner join ContentCrawler.dbo.BriefContentTag bct with(NOLOCK) on bct.BriefContentID = bc.BriefContentID and bct.TagGroupGUID = @TagGroupGUID '
			END
			ELSE
			BEGIN
				SET @SQLSelect += '
				inner join ContentCrawler.dbo.BriefContent bc with(NOLOCK) on sr.SubRecordID = bc.SubRecordID and bc.IsDeleted = 0
				inner join ContentCrawler.dbo.BriefContentTag bct with(NOLOCK) on bct.BriefContentID = bc.BriefContentID and bct.TagGroupGUID = @TagGroupGUID '
			END
		END

	IF @SiteIDs is NOT NULL
	BEGIN
		SET @SQLSelect += '
		inner join @TempSite s on s.SiteGUID = r.SiteGUID '
	END
	ELSE
	BEGIN
		SET @SQLSelect += '
		left join Site s with(nolock) on s.GUID = r.SiteGUID '
	END;

	SET @SQLSelect += '
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](r.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@tmpKeywordGUID)
		and [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@tmpKeywordGUID)
		and r.KeywordGUID = @tmpKeywordGUID		
		and r.IsReviewed = 1 and r.IsDeleted = 0  '
	
	SET @SQLSelect += ' 
		FETCH NEXT FROM c1 
					INTO @tmpKeywordGUID
		END   
  
		CLOSE c1   
		DEALLOCATE c1 ';

	SET @SQLSelect +=' 
		select t.RecordID, t.Title, ISNULL(t.URL, '''') as SiteURL, t.URL, t.PublishedDate as PublishedDate,			
			count(*) SubRecords 
		from @TempGetDBRecords t
		group by t.RecordID, t.Title, t.URL, t.URL, t.PublishedDate having count(*) > 0 		
		order by t.PublishedDate desc offset @FromRecord rows fetch next (@ToRecord - @FromRecord) rows only 

		select count(distinct t.RecordID) Total
		from @TempGetDBRecords t ';

	SET @SQLString = @SQLString + @SQLSelect ;
	
	SET @ParmDefinition = '
				@KeywordID nvarchar(1024),
				@SiteIDs varchar(1024),
				@Emotion int,
				@TagGroupID int,
				@StartDate datetime,
				@EndDate datetime,
				@FromRecord int,
				@ToRecord int';
	
	print @SQLString;
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@SiteIDs,	
						@Emotion,
						@TagGroupID,				
						@StartDate,
						@EndDate,						
						@FromRecord,
						@ToRecord;
END





GO
/****** Object:  StoredProcedure [dbo].[GetDBSiteCount]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBSiteCount]
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime
WITH recompile
AS
BEGIN
	SET NOCOUNT ON
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from WareHouse.dbo.DimTime where datediff(dd,[DATE], @StartDate) = 0)
	set @EndTimeID = (select DimTimeID from WareHouse.dbo.DimTime where DATEDIFF(dd, [DATE], @EndDate) = 0)
	
	select s.SiteID, s.URLName as 'Name', SUM(fks.Total) as Total
	from WareHouse.dbo.FactKeywordSite fks
		inner join Site s on s.SiteID = fks.SiteID
	where fks.DimTimeID between @StartTimeID and @EndTimeID
		and fks.KeywordID = @KeywordID
	group by s.SiteID, s.URLName
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBSiteTypeAuthorCount]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBSiteTypeAuthorCount]
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime
WITH recompile
AS
BEGIN
	SET NOCOUNT ON
	declare @StartTimeID int
	declare @EndTimeID int	
	
	set @StartTimeID = (select DimTimeID from WareHouse.dbo.DimTime where datediff(dd,[DATE], @StartDate) = 0)
	set @EndTimeID = (select DimTimeID from WareHouse.dbo.DimTime where DATEDIFF(dd, [DATE], @EndDate) = 0)
	
	select st.SiteTypeID, st.Name, sum(fka.Total) Total
	from WareHouse.dbo.FactKeywordAuthor fka
		inner join ContentAggregator.dbo.Site s with(NOLOCK) on fka.SiteID = s.SiteID
		inner join ContentAggregator.dbo.SiteType st on s.SiteTypeID = st.SiteTypeID	
	where fka.DimTimeID between @StartTimeID and @EndTimeID
		and fka.KeywordID = @KeywordID
	group by st.SiteTypeID, st.Name
	
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBSiteTypeCount]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBSiteTypeCount]
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime
WITH recompile
AS
BEGIN
	SET NOCOUNT ON
	declare @StartTimeID int
	declare @EndTimeID int	
	
	set @StartTimeID = (select DimTimeID from WareHouse.dbo.DimTime where datediff(dd,[DATE], @StartDate) = 0)
	set @EndTimeID = (select DimTimeID from WareHouse.dbo.DimTime where DATEDIFF(dd, [DATE], @EndDate) = 0)
	
	select st.SiteTypeID, st.Name, SUM(fks.Total) as Total
	from WareHouse.dbo.FactKeywordSite fks
		inner join ContentAggregator.dbo.Site s on s.SiteID = fks.SiteID
		inner join ContentAggregator.dbo.SiteType st with(NOLOCK) on s.SiteTypeID = st.SiteTypeID	
	where fks.DimTimeID between @StartTimeID and @EndTimeID
		and fks.KeywordID = @KeywordID
	group by st.SiteTypeID, st.Name	
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBSubRecords]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBSubRecords]
	@KeywordGUID uniqueidentifier,
	@RecordID int,	
	@TagGroupID int,	
	@TagIDs varchar(1024),
    @Emotion int,
	@StartDate datetime,
    @EndDate datetime,
	@FromRecord int,
	@ToRecord int
WITH RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	DECLARE @Pos int;
	-- create temp category table	
	DECLARE @TempTag table
	(
		TagID int,
		TagGUID uniqueidentifier
	)
	DECLARE @TagID varchar(10)

	SET @TagIDs = LTRIM(RTRIM(@TagIDs))+ '',''
	SET @Pos = CHARINDEX('','', @TagIDs, 1)

	IF REPLACE(@TagIDs, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @TagID = LTRIM(RTRIM(LEFT(@TagIDs, @Pos - 1)))
			IF @TagID <> ''''
			BEGIN
				INSERT INTO @TempTag(TagID, TagGUID) select TagID, guid from ContentAggregator.dbo.Tag where TagID = CAST(@TagID AS int)
			END
			SET @TagIDs = RIGHT(@TagIDs, LEN(@TagIDs) - @Pos)
			SET @Pos = CHARINDEX('','', @TagIDs, 1)

		END
	END;
	'
	
	SET @SQLString = @SQLString + '
		declare @srtb table
		(
			RowNumber int,
			SubRecordID int,
			Content nvarchar(max),
			Author nvarchar(256),
			PublishedDate datetime			
		)
		insert into @srtb (RowNumber, SubRecordID, Content, Author, PublishedDate)
		select ROW_NUMBER() OVER(ORDER BY sr.PublishedDate ASC) AS ''RowNumber'', sr.SubRecordID, sr.Content, sr.Author, sr.PublishedDate
		from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and sr.RecordID = @RecordID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate '

	--if @TagIDs is not null
	--BEGIN				
				
	--	SET @TagGroupID = -1;
	--END

	--IF @TagGroupID <> -1 
	--BEGIN
	--	SET @SQLString = @SQLString + '					
	--		inner join ContentCrawler.dbo.BriefContentTag bct WITH(NOLOCK) on sr.SubRecordID = bct.RecordID and bct.IsSubRecord = 1 and bct.IsDeleted = 0
	--		inner join ContentAggregator.dbo.Tag t with(nolock) on bct.TagGUID = t.GUID and t.TagGroupID = @TagGroupID '
	--END
		
	--SET @SQLString = @SQLString + '
	--	and sr.RecordID = @RecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0) '
	--if @TagIDs is not null
	--BEGIN		
	--	SET @SQLString = @SQLString + ' 		
	--	and exists (select * from ContentCrawler.dbo.BriefContentTag bct with(nolock) inner join @TempTag tt on bct.TagGUID = tt.TagGUID where sr.SubRecordID = bct.RecordID and bct.IsSubRecord = 1 and bct.IsDeleted = 0
	--	) '		
				
	--	SET @TagGroupID = -1;
	--END

	--IF @TagGroupID = -1 and @TagIDs is null
	--BEGIN
	--	SET @SQLString = @SQLString + '		
	--	and exists (select * from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) where rbc.RecordID = sr.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0 ' + CASE WHEN @Emotion <> -1 THEN ' and rbc.EmotionID = @Emotion' ELSE '' END + ') '
	--END
	IF @Emotion <> -1
	BEGIN
		SET @SQLString = @SQLString + '		
		and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK) 
						where bc.SubRecordID = sr.SubRecordID and bc.IsDeleted = 0 ' + CASE WHEN @Emotion <> -1 THEN ' and bc.Sentiment = @Emotion' ELSE '' END + ') '
	END

	SET @SQLString = @SQLString + '	
				
		select sr.SubRecordID, sr.Content, sr.Author, sr.PublishedDate		
		from @srtb sr
		where RowNumber > @FromRecord and RowNumber <= @ToRecord
		order by RowNumber asc;
		select count(*) Total from @srtb ';
		
	SET @ParmDefinition = '
				@KeywordGUID uniqueidentifier,
				@RecordID int,
				@TagGroupID int,	
				@TagIDs varchar(1024),
				@Emotion int,				
				@StartDate datetime,
				@EndDate datetime,
				@FromRecord int,
				@ToRecord int';
	
	print @SQLString;
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
						@KeywordGUID,
					  	@RecordID,
						@TagGroupID,	
						@TagIDs,
						@Emotion,
						@StartDate,
						@EndDate,						
						@FromRecord,
						@ToRecord;
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBTagGroupCount]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDBTagGroupCount]
	@KeywordGUID uniqueidentifier,
	@Sentiment int,
	@StartDate datetime,
	@EndDate datetime
WITH RECOMPILE
AS
/*
* Description: 
* Sample:
EXEC GetDBTagGroupCount 
	@KeywordGUID = 'F1692832-C5B3-453B-91C6-E2A34E406205',
	@Sentiment = 1,
	@StartDate = '2013-04-08 0:01:0',
	@EndDate = '2013-04-09 0:56:00'
*/
BEGIN		
	
	declare @StartInsertedDate datetime = DATEADD(DD,0,CONVERT(datetime,CONVERT(VARCHAR(10), @StartDate, 111)+' 00:00:00'));

	select top 6 (
	select cast(
	case 
		when tg.parentId = 0 then tg.Name 
		else ((select tg1.Name from ContentAggregator.dbo.TagGroup tg1 where tg1.TagGroupID = tg.ParentID) + '/' + tg.Name)
	end AS nvarchar)) as Name, count(distinct bc.BriefContentID) Total
	from ContentCrawler.dbo.BriefContentTag bct with(NOLOCK)
	inner join ContentCrawler.dbo.BriefContent bc with(NOLOCK) on bct.BriefContentID = bc.BriefContentID
	inner join ContentCrawler.dbo.SubRecord sr with(NOLOCK) on bct.SubRecordID = sr.SubRecordID
	inner join ContentAggregator.dbo.TagGroup tg with(NOLOCK) on tg.GUID = bct.TagGroupGUID
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID) 
			and sr.KeywordGUID = @KeywordGUID
			and sr.PublishedDate between @StartInsertedDate and @EndDate
			and bc.InsertedDate between @StartDate and @EndDate
			and sr.IsReviewed = 1 and sr.IsDeleted = 0 
			and bct.IsDeleted = 0 and bc.IsDeleted = 0 and tg.IsDeleted = 0
			and bc.Sentiment = @Sentiment
	group by tg.Name,tg.parentId	
		
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBTopTopics]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBTopTopics]
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime
WITH recompile
AS
BEGIN
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	);	
	
	select top 20 r.RecordID, r.Title, r.URL, r.PublishedDate, s.URLName SiteURL
		,count(*) SubRecords
	from ContentCrawler.dbo.Record r
	inner join ContentCrawler.dbo.SubRecord sr with(NOLOCK) on r.RecordID = sr.RecordID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate
	inner join ContentAggregator.dbo.Site s with(NOLOCK) on r.SiteGUID = s.GUID
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](r.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	and [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	and r.IsReviewed = 1 and r.IsDeleted = 0
	group by r.RecordID, r.Title, r.URL, r.PublishedDate, s.URLName
	having count(*) > 0
	order by SubRecords desc
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBTotalSitesByTime]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBTotalSitesByTime]
	@KeywordID int,
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON		
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from WareHouse.dbo.DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from WareHouse.dbo.DimTime where [DATE] = @EndDate)

	SELECT dt.DimTimeID, dt.Date, COUNT(distinct fks.SiteID) as 'Site', 0 as 'LifetimeSite'
	FROM WareHouse.dbo.DimTime dt 
	left join WareHouse.dbo.FactKeywordSite fks on fks.KeywordID = @KeywordID and dt.DimTimeID = fks.DimTimeID
	where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
	group by dt.DimTimeID, dt.Date		
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBTotalVoicesByTime]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDBTotalVoicesByTime]
	@KeywordID int,
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
						
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from WareHouse.dbo.DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from WareHouse.dbo.DimTime where [DATE] = @EndDate)	
				
	SELECT dt.DimTimeID, dt.Date, ISNULL(SUM(fka.Total), 0) as 'Voice', 0 as 'LifetimeVoice'
	FROM WareHouse.dbo.DimTime dt 
	left join WareHouse.dbo.FactKeywordAuthor fka on fka.KeywordID = @KeywordID and fka.DimTimeID = dt.DimTimeID
	where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
	group by dt.DimTimeID, dt.Date	
END

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboBrand]
		@pkc1 int
as
begin  
	delete [dbo].[Brand]
where [BrandID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboBrandKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboBrandKeyword]
		@pkc1 int
as
begin  
	delete [dbo].[BrandKeyword]
where [BrandKeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboBrandUser]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboBrandUser]
		@pkc1 int
as
begin  
	delete [dbo].[BrandUser]
where [BrandUserID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboChannel]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboChannel]
		@pkc1 int
as
begin  
	delete [dbo].[Channel]
where [ChannelID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboCheckSiteData]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboCheckSiteData]
		@pkc1 int
as
begin  
	delete [dbo].[CheckSiteData]
where [CheckSiteDataId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboContacts]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboContacts]
		@pkc1 int
as
begin  
	delete [dbo].[Contacts]
where [ContactId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboCustomer]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboCustomer]
		@pkc1 int
as
begin  
	delete [dbo].[Customer]
where [CustomerID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboCustomerBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboCustomerBrand]
		@pkc1 int,
		@pkc2 int
as
begin  
	delete [dbo].[CustomerBrand]
where [BrandID] = @pkc1
  and [CustomerID] = @pkc2
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboDailyReport]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboDailyReport]
		@pkc1 int
as
begin  
	delete [dbo].[DailyReport]
where [DailyReportId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboEmotionGroups]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboEmotionGroups]
		@pkc1 int
as
begin  
	delete [dbo].[EmotionGroups]
where [EmotionGroupID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboEmotionKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboEmotionKeyword]
		@pkc1 int
as
begin  
	delete [dbo].[EmotionKeyword]
where [EmotionKeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboEmotions]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboEmotions]
		@pkc1 int
as
begin  
	delete [dbo].[Emotions]
where [EmotionID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboFanPage]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboFanPage]
		@pkc1 int
as
begin  
	delete [dbo].[FanPage]
where [Id] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboFanPageKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboFanPageKeyword]
		@pkc1 int
as
begin  
	delete [dbo].[FanPageKeyword]
where [Id] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboFBPublishPostType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboFBPublishPostType]
		@pkc1 int
as
begin  
	delete [dbo].[FBPublishPostType]
where [FBPPTypeId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboFBPublistPost]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboFBPublistPost]
		@pkc1 int
as
begin  
	delete [dbo].[FBPublistPost]
where [FBPublishPostId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboKeyword]
		@pkc1 int
as
begin  
	delete [dbo].[Keyword]
where [KeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboProfile]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboProfile]
		@pkc1 int
as
begin  
	delete [dbo].[Profile]
where [ProfileID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboProjectBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboProjectBrand]
		@pkc1 int
as
begin  
	delete [dbo].[ProjectBrand]
where [ProjectBrandID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboProjects]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboProjects]
		@pkc1 int
as
begin  
	delete [dbo].[Projects]
where [ProjectId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboProjectType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboProjectType]
		@pkc1 int
as
begin  
	delete [dbo].[ProjectType]
where [ProjectTypeId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboProjectUser]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboProjectUser]
		@pkc1 int
as
begin  
	delete [dbo].[ProjectUser]
where [ProjectUserID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboSite]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboSite]
		@pkc1 int
as
begin  
	delete [dbo].[Site]
where [SiteID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboSiteCategory]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboSiteCategory]
		@pkc1 int
as
begin  
	delete [dbo].[SiteCategory]
where [SiteCategoryID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboSiteType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboSiteType]
		@pkc1 int
as
begin  
	delete [dbo].[SiteType]
where [SiteTypeID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboSubKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboSubKeyword]
		@pkc1 int
as
begin  
	delete [dbo].[SubKeyword]
where [SubKeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dbosysdiagrams]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dbosysdiagrams]
		@pkc1 int
as
begin  
	delete [dbo].[sysdiagrams]
where [diagram_id] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboTag]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboTag]
		@pkc1 int
as
begin  
	delete [dbo].[Tag]
where [TagID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboTagGroup]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboTagGroup]
		@pkc1 int
as
begin  
	delete [dbo].[TagGroup]
where [TagGroupID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboTagGroupKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboTagGroupKeyword]
		@pkc1 int
as
begin  
	delete [dbo].[TagGroupKeyword]
where [TagGroupKeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboTargetFilter]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboTargetFilter]
		@pkc1 int
as
begin  
	delete [dbo].[TargetFilter]
where [TargetFilterID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboTargetFilterAttribute]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboTargetFilterAttribute]
		@pkc1 int
as
begin  
	delete [dbo].[TargetFilterAttribute]
where [TargetFilterAttributeID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboType]
		@pkc1 int
as
begin  
	delete [dbo].[Type]
where [TypeID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboUserDetail]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboUserDetail]
		@pkc1 int
as
begin  
	delete [dbo].[UserDetail]
where [UserDetailID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSdel_dboWord]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSdel_dboWord]
		@pkc1 int
as
begin  
	delete [dbo].[Word]
where [WordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboBrand]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(512),
    @c4 nvarchar(1024),
    @c5 int,
    @c6 datetime,
    @c7 datetime,
    @c8 bit,
    @c9 int
as
begin  
	insert into [dbo].[Brand](
		[BrandID],
		[GUID],
		[Name],
		[Description],
		[CustomerID],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted],
		[BehaviorGroupID]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboBrandKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboBrandKeyword]
    @c1 int,
    @c2 int,
    @c3 int,
    @c4 int,
    @c5 datetime,
    @c6 datetime,
    @c7 bit
as
begin  
	insert into [dbo].[BrandKeyword](
		[BrandKeywordID],
		[BrandID],
		[KeywordID],
		[Type],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboBrandUser]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboBrandUser]
    @c1 int,
    @c2 int,
    @c3 int,
    @c4 datetime,
    @c5 datetime,
    @c6 bit
as
begin  
	insert into [dbo].[BrandUser](
		[BrandUserID],
		[BrandID],
		[UserDetailID],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboChannel]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboChannel]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 int,
    @c4 nvarchar(1024),
    @c5 nvarchar(1024),
    @c6 datetime,
    @c7 datetime,
    @c8 bit
as
begin  
	insert into [dbo].[Channel](
		[ChannelID],
		[GUID],
		[ParentID],
		[Name],
		[Description],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboCheckSiteData]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboCheckSiteData]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 datetime,
    @c4 int,
    @c5 int,
    @c6 bit,
    @c7 bit,
    @c8 nvarchar(500),
    @c9 int,
    @c10 int
as
begin  
	insert into [dbo].[CheckSiteData](
		[CheckSiteDataId],
		[SiteGuid],
		[CheckDate],
		[RecordNum],
		[SubRecordNum],
		[Status],
		[IsActive],
		[Description],
		[CmsRecordNum],
		[CmsSubRecordNum]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9,
    @c10	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboContacts]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboContacts]
    @c1 int,
    @c2 int,
    @c3 nvarchar(200),
    @c4 nvarchar(500),
    @c5 nvarchar(50),
    @c6 nvarchar(50),
    @c7 nvarchar(100),
    @c8 nvarchar(50),
    @c9 datetime,
    @c10 datetime,
    @c11 nvarchar(50),
    @c12 nvarchar(500),
    @c13 bit
as
begin  
	insert into [dbo].[Contacts](
		[ContactId],
		[CustomerId],
		[Name],
		[Address],
		[PhoneNumber],
		[CellPhone],
		[Email],
		[Fax],
		[InsertedDate],
		[UpdatedDate],
		[UserUpdate],
		[Descriptions],
		[IsDelete]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9,
    @c10,
    @c11,
    @c12,
    @c13	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboCustomer]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboCustomer]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(512),
    @c4 nvarchar(1024),
    @c5 datetime,
    @c6 datetime,
    @c7 bit,
    @c8 varchar(64)
as
begin  
	insert into [dbo].[Customer](
		[CustomerID],
		[GUID],
		[Name],
		[Description],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted],
		[Code]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboCustomerBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboCustomerBrand]
    @c1 int,
    @c2 int,
    @c3 int,
    @c4 datetime,
    @c5 datetime,
    @c6 bit
as
begin  
	insert into [dbo].[CustomerBrand](
		[CustomerBrandID],
		[BrandID],
		[CustomerID],
		[InsertedDate],
		[UpdatedDate],
		[IsActive]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboDailyReport]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboDailyReport]
    @c1 int,
    @c2 datetime,
    @c3 datetime,
    @c4 nvarchar(100),
    @c5 bit,
    @c6 uniqueidentifier,
    @c7 nvarchar(1024)
as
begin  
	insert into [dbo].[DailyReport](
		[DailyReportId],
		[StartTime],
		[SendTime],
		[UserName],
		[Status],
		[KeywordGUID],
		[Description]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboEmotionGroups]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboEmotionGroups]
    @c1 int,
    @c2 nvarchar(100),
    @c3 int,
    @c4 datetime,
    @c5 datetime,
    @c6 bit,
    @c7 nvarchar(500)
as
begin  
	insert into [dbo].[EmotionGroups](
		[EmotionGroupID],
		[GroupName],
		[Type],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted],
		[Descriptions]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboEmotionKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboEmotionKeyword]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(256),
    @c4 nvarchar(256),
    @c5 int,
    @c6 int,
    @c7 datetime,
    @c8 datetime,
    @c9 bit
as
begin  
	insert into [dbo].[EmotionKeyword](
		[EmotionKeywordID],
		[GUID],
		[Word],
		[WordWithoutAccent],
		[Type],
		[EmotionID],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboEmotions]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboEmotions]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 int,
    @c4 int,
    @c5 nvarchar(256),
    @c6 nvarchar(1024),
    @c7 datetime,
    @c8 datetime,
    @c9 bit
as
begin  
	insert into [dbo].[Emotions](
		[EmotionID],
		[GUID],
		[ParentId],
		[GroupId],
		[Name],
		[Description],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboFanPage]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboFanPage]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 uniqueidentifier,
    @c4 datetime,
    @c5 datetime,
    @c6 nvarchar(512),
    @c7 nvarchar(512),
    @c8 datetime
as
begin  
	insert into [dbo].[FanPage](
		[Id],
		[GUID],
		[SiteGUID],
		[InsertedDate],
		[UpdatedDate],
		[PageId],
		[Name],
		[LatestUpdatedDate]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboFanPageKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboFanPageKeyword]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 int,
    @c4 int,
    @c5 datetime,
    @c6 datetime,
    @c7 bit
as
begin  
	insert into [dbo].[FanPageKeyword](
		[Id],
		[GUID],
		[KeywordID],
		[FanPageID],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboFBPublishPostType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboFBPublishPostType]
    @c1 int,
    @c2 varchar(50),
    @c3 varchar(1024),
    @c4 varchar(250),
    @c5 varchar(250),
    @c6 nvarchar(2048)
as
begin  
	insert into [dbo].[FBPublishPostType](
		[FBPPTypeId],
		[TypeName],
		[Param],
		[AccessToken],
		[AppId],
		[Examble]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboFBPublistPost]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboFBPublistPost]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(500),
    @c4 int,
    @c5 nvarchar(100),
    @c6 int,
    @c7 datetime,
    @c8 datetime,
    @c9 nvarchar(50),
    @c10 bit,
    @c11 nvarchar(50),
    @c12 nvarchar(500)
as
begin  
	insert into [dbo].[FBPublistPost](
		[FBPublishPostId],
		[SIteGUID],
		[Name],
		[Type],
		[PageId],
		[KeywordId],
		[InsertedDate],
		[UpdatedDate],
		[UpdateBy],
		[IsActive],
		[Status],
		[Description]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9,
    @c10,
    @c11,
    @c12	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboKeyword]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 datetime,
    @c4 datetime,
    @c5 nvarchar(512),
    @c6 nvarchar(512),
    @c7 bit,
    @c8 datetime,
    @c9 datetime,
    @c10 bit,
    @c11 bit
as
begin  
	insert into [dbo].[Keyword](
		[KeywordID],
		[GUID],
		[InsertedDate],
		[UpdatedDate],
		[Word],
		[WordWithoutAccent],
		[IsActive],
		[StartDate],
		[EndDate],
		[IsDeleted],
		[IsBrand]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9,
    @c10,
    @c11	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboProfile]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboProfile]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(1024),
    @c4 varchar(1024),
    @c5 varchar(1024),
    @c6 nvarchar(1024),
    @c7 varchar(1024),
    @c8 varchar(1024),
    @c9 nvarchar(1024),
    @c10 varchar(1024),
    @c11 varchar(1024),
    @c12 nvarchar(1024),
    @c13 varchar(1024),
    @c14 varchar(1024),
    @c15 int,
    @c16 datetime,
    @c17 datetime
as
begin  
	insert into [dbo].[Profile](
		[ProfileID],
		[GUID],
		[Level1Name],
		[Level1Phone],
		[Level1Email],
		[Level2Name],
		[Level2Phone],
		[Level2Email],
		[Level3Name],
		[Level3Phone],
		[Level3Email],
		[AccountManagerName],
		[AccountManagerPhone],
		[AccountManagerEmail],
		[BrandID],
		[InsertedDate],
		[UpdatedDate]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9,
    @c10,
    @c11,
    @c12,
    @c13,
    @c14,
    @c15,
    @c16,
    @c17	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboProjectBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboProjectBrand]
    @c1 int,
    @c2 int,
    @c3 nvarchar(500),
    @c4 datetime,
    @c5 datetime,
    @c6 nvarchar(50),
    @c7 bit,
    @c8 int
as
begin  
	insert into [dbo].[ProjectBrand](
		[ProjectBrandID],
		[ProjectID],
		[Description],
		[InsertedDate],
		[UpdatedDate],
		[UserName],
		[IsDelete],
		[BrandID]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboProjects]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboProjects]
    @c1 int,
    @c2 nvarchar(500),
    @c3 int,
    @c4 int,
    @c5 int,
    @c6 bit,
    @c7 bit,
    @c8 datetime,
    @c9 datetime,
    @c10 datetime,
    @c11 datetime,
    @c12 uniqueidentifier,
    @c13 nchar(1000),
    @c14 uniqueidentifier
as
begin  
	insert into [dbo].[Projects](
		[ProjectId],
		[ProjectName],
		[TypeId],
		[CustomerId],
		[MainContractId],
		[IsActive],
		[IsDeleted],
		[StartDate],
		[EndDate],
		[InsertedDate],
		[UpdatedDate],
		[UserUpdate],
		[Description],
		[Leader]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9,
    @c10,
    @c11,
    @c12,
    @c13,
    @c14	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboProjectType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboProjectType]
    @c1 int,
    @c2 nvarchar(500),
    @c3 bit,
    @c4 datetime,
    @c5 datetime,
    @c6 uniqueidentifier,
    @c7 nvarchar(1000)
as
begin  
	insert into [dbo].[ProjectType](
		[ProjectTypeId],
		[TypeName],
		[IsDeleted],
		[InsertedDate],
		[UpdatedDate],
		[UserUpdate],
		[Descriptions]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboProjectUser]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboProjectUser]
    @c1 int,
    @c2 int,
    @c3 int,
    @c4 bit,
    @c5 datetime,
    @c6 datetime,
    @c7 bit
as
begin  
	insert into [dbo].[ProjectUser](
		[ProjectUserID],
		[ProjectID],
		[UserID],
		[IsDeleted],
		[InsertedDate],
		[UpdatedDate],
		[IsLeader]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboSite]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboSite]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 datetime,
    @c4 datetime,
    @c5 bit,
    @c6 int,
    @c7 int,
    @c8 varchar(1024),
    @c9 varchar(1024),
    @c10 nvarchar(1024),
    @c11 nvarchar(1024),
    @c12 bit,
    @c13 int
as
begin  
	insert into [dbo].[Site](
		[SiteID],
		[GUID],
		[InsertedDate],
		[UpdatedDate],
		[IsActive],
		[SiteTypeID],
		[SiteCategoryID],
		[URL],
		[URLName],
		[Name],
		[Description],
		[IsDeleted],
		[Duration]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9,
    @c10,
    @c11,
    @c12,
    @c13	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboSiteCategory]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboSiteCategory]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(512),
    @c4 nvarchar(1024),
    @c5 datetime,
    @c6 datetime
as
begin  
	insert into [dbo].[SiteCategory](
		[SiteCategoryID],
		[GUID],
		[Name],
		[Description],
		[InsertedDate],
		[UpdatedDate]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboSiteType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboSiteType]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 datetime,
    @c4 datetime,
    @c5 nvarchar(1024),
    @c6 nvarchar(1024)
as
begin  
	insert into [dbo].[SiteType](
		[SiteTypeID],
		[GUID],
		[InsertedDate],
		[UpdatedDate],
		[Name],
		[Description]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboSubKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboSubKeyword]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 int,
    @c4 nvarchar(512),
    @c5 nvarchar(512),
    @c6 datetime,
    @c7 datetime,
    @c8 bit
as
begin  
	insert into [dbo].[SubKeyword](
		[SubKeywordID],
		[GUID],
		[KeywordID],
		[Word],
		[WordWithoutAccent],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dbosysdiagrams]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dbosysdiagrams]
    @c1 nvarchar(128),
    @c2 int,
    @c3 int,
    @c4 int,
    @c5 varbinary(max)
as
begin  
	insert into [dbo].[sysdiagrams](
		[name],
		[principal_id],
		[diagram_id],
		[version],
		[definition]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboTag]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboTag]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(256),
    @c4 nvarchar(256),
    @c5 nvarchar(1024),
    @c6 datetime,
    @c7 datetime,
    @c8 int,
    @c9 bit
as
begin  
	insert into [dbo].[Tag](
		[TagID],
		[GUID],
		[Word],
		[WordWithoutAccent],
		[Description],
		[InsertedDate],
		[UpdatedDate],
		[TagGroupID],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboTagGroup]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboTagGroup]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(256),
    @c4 nvarchar(1024),
    @c5 int,
    @c6 datetime,
    @c7 datetime,
    @c8 bit,
    @c9 int
as
begin  
	insert into [dbo].[TagGroup](
		[TagGroupID],
		[GUID],
		[Name],
		[Description],
		[Type],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted],
		[ParentID]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboTagGroupKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboTagGroupKeyword]
    @c1 int,
    @c2 int,
    @c3 int,
    @c4 datetime,
    @c5 datetime,
    @c6 bit
as
begin  
	insert into [dbo].[TagGroupKeyword](
		[TagGroupKeywordID],
		[KeywordID],
		[TagGroupID],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboTargetFilter]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboTargetFilter]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(256),
    @c4 nvarchar(512),
    @c5 datetime,
    @c6 datetime,
    @c7 bit
as
begin  
	insert into [dbo].[TargetFilter](
		[TargetFilterID],
		[GUID],
		[Name],
		[Description],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboTargetFilterAttribute]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboTargetFilterAttribute]
    @c1 int,
    @c2 int,
    @c3 int,
    @c4 int,
    @c5 datetime,
    @c6 datetime
as
begin  
	insert into [dbo].[TargetFilterAttribute](
		[TargetFilterAttributeID],
		[TargetFilterID],
		[SiteID],
		[ChannelID],
		[InsertedDate],
		[UpdatedDate]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboType]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(256),
    @c4 nvarchar(512),
    @c5 int,
    @c6 datetime,
    @c7 datetime
as
begin  
	insert into [dbo].[Type](
		[TypeID],
		[GUID],
		[Name],
		[Description],
		[ParentID],
		[InsertedDate],
		[UpdatedDate]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboUserDetail]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboUserDetail]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 nvarchar(128),
    @c4 int,
    @c5 nvarchar(128),
    @c6 nvarchar(128),
    @c7 datetime,
    @c8 datetime,
    @c9 bit
as
begin  
	insert into [dbo].[UserDetail](
		[UserDetailID],
		[GUID],
		[UserName],
		[CustomerID],
		[FullName],
		[Email],
		[InsertedDate],
		[UpdatedDate],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8,
    @c9	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboWord]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboWord]
    @c1 int,
    @c2 uniqueidentifier,
    @c3 datetime,
    @c4 datetime,
    @c5 nvarchar(512),
    @c6 nvarchar(512),
    @c7 int,
    @c8 bit
as
begin  
	insert into [dbo].[Word](
		[WordID],
		[GUID],
		[InsertedDate],
		[UpdatedDate],
		[WordWithAccent],
		[WordWithoutAccent],
		[KeywordID],
		[IsDeleted]
	) values (
    @c1,
    @c2,
    @c3,
    @c4,
    @c5,
    @c6,
    @c7,
    @c8	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboBrand]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(512) = NULL,
		@c4 nvarchar(1024) = NULL,
		@c5 int = NULL,
		@c6 datetime = NULL,
		@c7 datetime = NULL,
		@c8 bit = NULL,
		@c9 int = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[Brand] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Description] end,
		[CustomerID] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [CustomerID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [IsDeleted] end,
		[BehaviorGroupID] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [BehaviorGroupID] end
where [BrandID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboBrandKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboBrandKeyword]
		@c1 int = NULL,
		@c2 int = NULL,
		@c3 int = NULL,
		@c4 int = NULL,
		@c5 datetime = NULL,
		@c6 datetime = NULL,
		@c7 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[BrandKeyword] set
		[BrandID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [BrandID] end,
		[KeywordID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [KeywordID] end,
		[Type] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Type] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsDeleted] end
where [BrandKeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboBrandUser]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboBrandUser]
		@c1 int = NULL,
		@c2 int = NULL,
		@c3 int = NULL,
		@c4 datetime = NULL,
		@c5 datetime = NULL,
		@c6 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[BrandUser] set
		[BrandID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [BrandID] end,
		[UserDetailID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [UserDetailID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [IsDeleted] end
where [BrandUserID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboChannel]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboChannel]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 int = NULL,
		@c4 nvarchar(1024) = NULL,
		@c5 nvarchar(1024) = NULL,
		@c6 datetime = NULL,
		@c7 datetime = NULL,
		@c8 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
if (substring(@bitmap,1,1) & 1 = 1)
begin 
update [dbo].[Channel] set
		[ChannelID] = case substring(@bitmap,1,1) & 1 when 1 then @c1 else [ChannelID] end,
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[ParentID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [ParentID] end,
		[Name] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Description] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [IsDeleted] end
where [ChannelID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  
else
begin 
update [dbo].[Channel] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[ParentID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [ParentID] end,
		[Name] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Description] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [IsDeleted] end
where [ChannelID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboCheckSiteData]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboCheckSiteData]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 datetime = NULL,
		@c4 int = NULL,
		@c5 int = NULL,
		@c6 bit = NULL,
		@c7 bit = NULL,
		@c8 nvarchar(500) = NULL,
		@c9 int = NULL,
		@c10 int = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[CheckSiteData] set
		[SiteGuid] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [SiteGuid] end,
		[CheckDate] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [CheckDate] end,
		[RecordNum] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [RecordNum] end,
		[SubRecordNum] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [SubRecordNum] end,
		[Status] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [Status] end,
		[IsActive] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsActive] end,
		[Description] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [Description] end,
		[CmsRecordNum] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [CmsRecordNum] end,
		[CmsSubRecordNum] = case substring(@bitmap,2,1) & 2 when 2 then @c10 else [CmsSubRecordNum] end
where [CheckSiteDataId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboContacts]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboContacts]
		@c1 int = NULL,
		@c2 int = NULL,
		@c3 nvarchar(200) = NULL,
		@c4 nvarchar(500) = NULL,
		@c5 nvarchar(50) = NULL,
		@c6 nvarchar(50) = NULL,
		@c7 nvarchar(100) = NULL,
		@c8 nvarchar(50) = NULL,
		@c9 datetime = NULL,
		@c10 datetime = NULL,
		@c11 nvarchar(50) = NULL,
		@c12 nvarchar(500) = NULL,
		@c13 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[Contacts] set
		[CustomerId] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [CustomerId] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Address] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Address] end,
		[PhoneNumber] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [PhoneNumber] end,
		[CellPhone] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [CellPhone] end,
		[Email] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [Email] end,
		[Fax] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [Fax] end,
		[InsertedDate] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,2,1) & 2 when 2 then @c10 else [UpdatedDate] end,
		[UserUpdate] = case substring(@bitmap,2,1) & 4 when 4 then @c11 else [UserUpdate] end,
		[Descriptions] = case substring(@bitmap,2,1) & 8 when 8 then @c12 else [Descriptions] end,
		[IsDelete] = case substring(@bitmap,2,1) & 16 when 16 then @c13 else [IsDelete] end
where [ContactId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboCustomer]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboCustomer]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(512) = NULL,
		@c4 nvarchar(1024) = NULL,
		@c5 datetime = NULL,
		@c6 datetime = NULL,
		@c7 bit = NULL,
		@c8 varchar(64) = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[Customer] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Description] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsDeleted] end,
		[Code] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [Code] end
where [CustomerID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboCustomerBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboCustomerBrand]
		@c1 int = NULL,
		@c2 int = NULL,
		@c3 int = NULL,
		@c4 datetime = NULL,
		@c5 datetime = NULL,
		@c6 bit = NULL,
		@pkc1 int = NULL,
		@pkc2 int = NULL,
		@bitmap binary(1)
as
begin  
if (substring(@bitmap,1,1) & 2 = 2) or
 (substring(@bitmap,1,1) & 4 = 4)
begin 
update [dbo].[CustomerBrand] set
		[BrandID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [BrandID] end,
		[CustomerID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [CustomerID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [UpdatedDate] end,
		[IsActive] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [IsActive] end
where [BrandID] = @pkc1
  and [CustomerID] = @pkc2
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  
else
begin 
update [dbo].[CustomerBrand] set
		[InsertedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [UpdatedDate] end,
		[IsActive] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [IsActive] end
where [BrandID] = @pkc1
  and [CustomerID] = @pkc2
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboDailyReport]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboDailyReport]
		@c1 int = NULL,
		@c2 datetime = NULL,
		@c3 datetime = NULL,
		@c4 nvarchar(100) = NULL,
		@c5 bit = NULL,
		@c6 uniqueidentifier = NULL,
		@c7 nvarchar(1024) = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[DailyReport] set
		[StartTime] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [StartTime] end,
		[SendTime] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [SendTime] end,
		[UserName] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [UserName] end,
		[Status] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Status] end,
		[KeywordGUID] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [KeywordGUID] end,
		[Description] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [Description] end
where [DailyReportId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboEmotionGroups]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboEmotionGroups]
		@c1 int = NULL,
		@c2 nvarchar(100) = NULL,
		@c3 int = NULL,
		@c4 datetime = NULL,
		@c5 datetime = NULL,
		@c6 bit = NULL,
		@c7 nvarchar(500) = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[EmotionGroups] set
		[GroupName] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GroupName] end,
		[Type] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Type] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [IsDeleted] end,
		[Descriptions] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [Descriptions] end
where [EmotionGroupID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboEmotionKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboEmotionKeyword]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(256) = NULL,
		@c4 nvarchar(256) = NULL,
		@c5 int = NULL,
		@c6 int = NULL,
		@c7 datetime = NULL,
		@c8 datetime = NULL,
		@c9 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[EmotionKeyword] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Word] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Word] end,
		[WordWithoutAccent] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [WordWithoutAccent] end,
		[Type] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Type] end,
		[EmotionID] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [EmotionID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [IsDeleted] end
where [EmotionKeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboEmotions]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboEmotions]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 int = NULL,
		@c4 int = NULL,
		@c5 nvarchar(256) = NULL,
		@c6 nvarchar(1024) = NULL,
		@c7 datetime = NULL,
		@c8 datetime = NULL,
		@c9 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[Emotions] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[ParentId] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [ParentId] end,
		[GroupId] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [GroupId] end,
		[Name] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [Description] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [IsDeleted] end
where [EmotionID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboFanPage]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboFanPage]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 uniqueidentifier = NULL,
		@c4 datetime = NULL,
		@c5 datetime = NULL,
		@c6 nvarchar(512) = NULL,
		@c7 nvarchar(512) = NULL,
		@c8 datetime = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[FanPage] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[SiteGUID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [SiteGUID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [UpdatedDate] end,
		[PageId] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [PageId] end,
		[Name] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [Name] end,
		[LatestUpdatedDate] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [LatestUpdatedDate] end
where [Id] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboFanPageKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboFanPageKeyword]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 int = NULL,
		@c4 int = NULL,
		@c5 datetime = NULL,
		@c6 datetime = NULL,
		@c7 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[FanPageKeyword] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[KeywordID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [KeywordID] end,
		[FanPageID] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [FanPageID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsDeleted] end
where [Id] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboFBPublishPostType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboFBPublishPostType]
		@c1 int = NULL,
		@c2 varchar(50) = NULL,
		@c3 varchar(1024) = NULL,
		@c4 varchar(250) = NULL,
		@c5 varchar(250) = NULL,
		@c6 nvarchar(2048) = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[FBPublishPostType] set
		[TypeName] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [TypeName] end,
		[Param] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Param] end,
		[AccessToken] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [AccessToken] end,
		[AppId] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [AppId] end,
		[Examble] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [Examble] end
where [FBPPTypeId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboFBPublistPost]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboFBPublistPost]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(500) = NULL,
		@c4 int = NULL,
		@c5 nvarchar(100) = NULL,
		@c6 int = NULL,
		@c7 datetime = NULL,
		@c8 datetime = NULL,
		@c9 nvarchar(50) = NULL,
		@c10 bit = NULL,
		@c11 nvarchar(50) = NULL,
		@c12 nvarchar(500) = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[FBPublistPost] set
		[SIteGUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [SIteGUID] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Type] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Type] end,
		[PageId] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [PageId] end,
		[KeywordId] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [KeywordId] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [UpdatedDate] end,
		[UpdateBy] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [UpdateBy] end,
		[IsActive] = case substring(@bitmap,2,1) & 2 when 2 then @c10 else [IsActive] end,
		[Status] = case substring(@bitmap,2,1) & 4 when 4 then @c11 else [Status] end,
		[Description] = case substring(@bitmap,2,1) & 8 when 8 then @c12 else [Description] end
where [FBPublishPostId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboKeyword]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 datetime = NULL,
		@c4 datetime = NULL,
		@c5 nvarchar(512) = NULL,
		@c6 nvarchar(512) = NULL,
		@c7 bit = NULL,
		@c8 datetime = NULL,
		@c9 datetime = NULL,
		@c10 bit = NULL,
		@c11 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[Keyword] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [UpdatedDate] end,
		[Word] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Word] end,
		[WordWithoutAccent] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [WordWithoutAccent] end,
		[IsActive] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsActive] end,
		[StartDate] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [StartDate] end,
		[EndDate] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [EndDate] end,
		[IsDeleted] = case substring(@bitmap,2,1) & 2 when 2 then @c10 else [IsDeleted] end,
		[IsBrand] = case substring(@bitmap,2,1) & 4 when 4 then @c11 else [IsBrand] end
where [KeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboProfile]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboProfile]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(1024) = NULL,
		@c4 varchar(1024) = NULL,
		@c5 varchar(1024) = NULL,
		@c6 nvarchar(1024) = NULL,
		@c7 varchar(1024) = NULL,
		@c8 varchar(1024) = NULL,
		@c9 nvarchar(1024) = NULL,
		@c10 varchar(1024) = NULL,
		@c11 varchar(1024) = NULL,
		@c12 nvarchar(1024) = NULL,
		@c13 varchar(1024) = NULL,
		@c14 varchar(1024) = NULL,
		@c15 int = NULL,
		@c16 datetime = NULL,
		@c17 datetime = NULL,
		@pkc1 int = NULL,
		@bitmap binary(3)
as
begin  
update [dbo].[Profile] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Level1Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Level1Name] end,
		[Level1Phone] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Level1Phone] end,
		[Level1Email] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Level1Email] end,
		[Level2Name] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [Level2Name] end,
		[Level2Phone] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [Level2Phone] end,
		[Level2Email] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [Level2Email] end,
		[Level3Name] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [Level3Name] end,
		[Level3Phone] = case substring(@bitmap,2,1) & 2 when 2 then @c10 else [Level3Phone] end,
		[Level3Email] = case substring(@bitmap,2,1) & 4 when 4 then @c11 else [Level3Email] end,
		[AccountManagerName] = case substring(@bitmap,2,1) & 8 when 8 then @c12 else [AccountManagerName] end,
		[AccountManagerPhone] = case substring(@bitmap,2,1) & 16 when 16 then @c13 else [AccountManagerPhone] end,
		[AccountManagerEmail] = case substring(@bitmap,2,1) & 32 when 32 then @c14 else [AccountManagerEmail] end,
		[BrandID] = case substring(@bitmap,2,1) & 64 when 64 then @c15 else [BrandID] end,
		[InsertedDate] = case substring(@bitmap,2,1) & 128 when 128 then @c16 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,3,1) & 1 when 1 then @c17 else [UpdatedDate] end
where [ProfileID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboProjectBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboProjectBrand]
		@c1 int = NULL,
		@c2 int = NULL,
		@c3 nvarchar(500) = NULL,
		@c4 datetime = NULL,
		@c5 datetime = NULL,
		@c6 nvarchar(50) = NULL,
		@c7 bit = NULL,
		@c8 int = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[ProjectBrand] set
		[ProjectID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [ProjectID] end,
		[Description] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Description] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [UpdatedDate] end,
		[UserName] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UserName] end,
		[IsDelete] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsDelete] end,
		[BrandID] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [BrandID] end
where [ProjectBrandID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboProjects]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboProjects]
		@c1 int = NULL,
		@c2 nvarchar(500) = NULL,
		@c3 int = NULL,
		@c4 int = NULL,
		@c5 int = NULL,
		@c6 bit = NULL,
		@c7 bit = NULL,
		@c8 datetime = NULL,
		@c9 datetime = NULL,
		@c10 datetime = NULL,
		@c11 datetime = NULL,
		@c12 uniqueidentifier = NULL,
		@c13 nchar(1000) = NULL,
		@c14 uniqueidentifier = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[Projects] set
		[ProjectName] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [ProjectName] end,
		[TypeId] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [TypeId] end,
		[CustomerId] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [CustomerId] end,
		[MainContractId] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [MainContractId] end,
		[IsActive] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [IsActive] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsDeleted] end,
		[StartDate] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [StartDate] end,
		[EndDate] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [EndDate] end,
		[InsertedDate] = case substring(@bitmap,2,1) & 2 when 2 then @c10 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,2,1) & 4 when 4 then @c11 else [UpdatedDate] end,
		[UserUpdate] = case substring(@bitmap,2,1) & 8 when 8 then @c12 else [UserUpdate] end,
		[Description] = case substring(@bitmap,2,1) & 16 when 16 then @c13 else [Description] end,
		[Leader] = case substring(@bitmap,2,1) & 32 when 32 then @c14 else [Leader] end
where [ProjectId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboProjectType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboProjectType]
		@c1 int = NULL,
		@c2 nvarchar(500) = NULL,
		@c3 bit = NULL,
		@c4 datetime = NULL,
		@c5 datetime = NULL,
		@c6 uniqueidentifier = NULL,
		@c7 nvarchar(1000) = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[ProjectType] set
		[TypeName] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [TypeName] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [IsDeleted] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [UpdatedDate] end,
		[UserUpdate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UserUpdate] end,
		[Descriptions] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [Descriptions] end
where [ProjectTypeId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboProjectUser]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboProjectUser]
		@c1 int = NULL,
		@c2 int = NULL,
		@c3 int = NULL,
		@c4 bit = NULL,
		@c5 datetime = NULL,
		@c6 datetime = NULL,
		@c7 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[ProjectUser] set
		[ProjectID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [ProjectID] end,
		[UserID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [UserID] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [IsDeleted] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UpdatedDate] end,
		[IsLeader] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsLeader] end
where [ProjectUserID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboSite]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboSite]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 datetime = NULL,
		@c4 datetime = NULL,
		@c5 bit = NULL,
		@c6 int = NULL,
		@c7 int = NULL,
		@c8 varchar(1024) = NULL,
		@c9 varchar(1024) = NULL,
		@c10 nvarchar(1024) = NULL,
		@c11 nvarchar(1024) = NULL,
		@c12 bit = NULL,
		@c13 int = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[Site] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [UpdatedDate] end,
		[IsActive] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [IsActive] end,
		[SiteTypeID] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [SiteTypeID] end,
		[SiteCategoryID] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [SiteCategoryID] end,
		[URL] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [URL] end,
		[URLName] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [URLName] end,
		[Name] = case substring(@bitmap,2,1) & 2 when 2 then @c10 else [Name] end,
		[Description] = case substring(@bitmap,2,1) & 4 when 4 then @c11 else [Description] end,
		[IsDeleted] = case substring(@bitmap,2,1) & 8 when 8 then @c12 else [IsDeleted] end,
		[Duration] = case substring(@bitmap,2,1) & 16 when 16 then @c13 else [Duration] end
where [SiteID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboSiteCategory]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboSiteCategory]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(512) = NULL,
		@c4 nvarchar(1024) = NULL,
		@c5 datetime = NULL,
		@c6 datetime = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[SiteCategory] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Description] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UpdatedDate] end
where [SiteCategoryID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboSiteType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboSiteType]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 datetime = NULL,
		@c4 datetime = NULL,
		@c5 nvarchar(1024) = NULL,
		@c6 nvarchar(1024) = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[SiteType] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [UpdatedDate] end,
		[Name] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [Description] end
where [SiteTypeID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboSubKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboSubKeyword]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 int = NULL,
		@c4 nvarchar(512) = NULL,
		@c5 nvarchar(512) = NULL,
		@c6 datetime = NULL,
		@c7 datetime = NULL,
		@c8 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[SubKeyword] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[KeywordID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [KeywordID] end,
		[Word] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Word] end,
		[WordWithoutAccent] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [WordWithoutAccent] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [IsDeleted] end
where [SubKeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dbosysdiagrams]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dbosysdiagrams]
		@c1 nvarchar(128) = NULL,
		@c2 int = NULL,
		@c3 int = NULL,
		@c4 int = NULL,
		@c5 varbinary(max) = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[sysdiagrams] set
		[name] = case substring(@bitmap,1,1) & 1 when 1 then @c1 else [name] end,
		[principal_id] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [principal_id] end,
		[version] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [version] end,
		[definition] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [definition] end
where [diagram_id] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboTag]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboTag]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(256) = NULL,
		@c4 nvarchar(256) = NULL,
		@c5 nvarchar(1024) = NULL,
		@c6 datetime = NULL,
		@c7 datetime = NULL,
		@c8 int = NULL,
		@c9 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[Tag] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Word] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Word] end,
		[WordWithoutAccent] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [WordWithoutAccent] end,
		[Description] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Description] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [UpdatedDate] end,
		[TagGroupID] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [TagGroupID] end,
		[IsDeleted] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [IsDeleted] end
where [TagID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboTagGroup]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboTagGroup]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(256) = NULL,
		@c4 nvarchar(1024) = NULL,
		@c5 int = NULL,
		@c6 datetime = NULL,
		@c7 datetime = NULL,
		@c8 bit = NULL,
		@c9 int = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[TagGroup] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Description] end,
		[Type] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [Type] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [IsDeleted] end,
		[ParentID] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [ParentID] end
where [TagGroupID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboTagGroupKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboTagGroupKeyword]
		@c1 int = NULL,
		@c2 int = NULL,
		@c3 int = NULL,
		@c4 datetime = NULL,
		@c5 datetime = NULL,
		@c6 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[TagGroupKeyword] set
		[KeywordID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [KeywordID] end,
		[TagGroupID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [TagGroupID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [IsDeleted] end
where [TagGroupKeywordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboTargetFilter]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboTargetFilter]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(256) = NULL,
		@c4 nvarchar(512) = NULL,
		@c5 datetime = NULL,
		@c6 datetime = NULL,
		@c7 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[TargetFilter] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Description] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [IsDeleted] end
where [TargetFilterID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboTargetFilterAttribute]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboTargetFilterAttribute]
		@c1 int = NULL,
		@c2 int = NULL,
		@c3 int = NULL,
		@c4 int = NULL,
		@c5 datetime = NULL,
		@c6 datetime = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[TargetFilterAttribute] set
		[TargetFilterID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [TargetFilterID] end,
		[SiteID] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [SiteID] end,
		[ChannelID] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [ChannelID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [UpdatedDate] end
where [TargetFilterAttributeID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboType]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(256) = NULL,
		@c4 nvarchar(512) = NULL,
		@c5 int = NULL,
		@c6 datetime = NULL,
		@c7 datetime = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
if (substring(@bitmap,1,1) & 1 = 1)
begin 
update [dbo].[Type] set
		[TypeID] = case substring(@bitmap,1,1) & 1 when 1 then @c1 else [TypeID] end,
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Description] end,
		[ParentID] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [ParentID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [UpdatedDate] end
where [TypeID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end  
else
begin 
update [dbo].[Type] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[Name] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [Name] end,
		[Description] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [Description] end,
		[ParentID] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [ParentID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [UpdatedDate] end
where [TypeID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboUserDetail]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboUserDetail]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 nvarchar(128) = NULL,
		@c4 int = NULL,
		@c5 nvarchar(128) = NULL,
		@c6 nvarchar(128) = NULL,
		@c7 datetime = NULL,
		@c8 datetime = NULL,
		@c9 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(2)
as
begin  
update [dbo].[UserDetail] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[UserName] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [UserName] end,
		[CustomerID] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [CustomerID] end,
		[FullName] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [FullName] end,
		[Email] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [Email] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [UpdatedDate] end,
		[IsDeleted] = case substring(@bitmap,2,1) & 1 when 1 then @c9 else [IsDeleted] end
where [UserDetailID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboWord]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboWord]
		@c1 int = NULL,
		@c2 uniqueidentifier = NULL,
		@c3 datetime = NULL,
		@c4 datetime = NULL,
		@c5 nvarchar(512) = NULL,
		@c6 nvarchar(512) = NULL,
		@c7 int = NULL,
		@c8 bit = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[Word] set
		[GUID] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [GUID] end,
		[InsertedDate] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [InsertedDate] end,
		[UpdatedDate] = case substring(@bitmap,1,1) & 8 when 8 then @c4 else [UpdatedDate] end,
		[WordWithAccent] = case substring(@bitmap,1,1) & 16 when 16 then @c5 else [WordWithAccent] end,
		[WordWithoutAccent] = case substring(@bitmap,1,1) & 32 when 32 then @c6 else [WordWithoutAccent] end,
		[KeywordID] = case substring(@bitmap,1,1) & 64 when 64 then @c7 else [KeywordID] end,
		[IsDeleted] = case substring(@bitmap,1,1) & 128 when 128 then @c8 else [IsDeleted] end
where [WordID] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  StoredProcedure [dbo].[sp_who3]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_who3] 

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
    SPID                = er.session_id
    ,BlkBy              = er.blocking_session_id      
    ,ElapsedMS          = er.total_elapsed_time
    ,CPU                = er.cpu_time
    ,IOReads            = er.logical_reads + er.reads
    ,IOWrites           = er.writes     
    ,Executions         = ec.execution_count  
    ,CommandType        = er.command         
    ,ObjectName         = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)  
    ,SQLStatement       =
        SUBSTRING
        (
            qt.text,
            er.statement_start_offset/2,
            (CASE WHEN er.statement_end_offset = -1
                THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
                ELSE er.statement_end_offset
                END - er.statement_start_offset)/2
        )        
    ,ClientAddress      = con.client_net_address
	,Host               = ses.host_name
	,STATUS             = ses.STATUS
    ,[Login]            = ses.login_name    
    ,DBName             = DB_Name(er.database_id)
    ,LastWaitType       = er.last_wait_type
    ,StartTime          = er.start_time
    ,Protocol           = con.net_transport
    ,transaction_isolation =
        CASE ses.transaction_isolation_level
            WHEN 0 THEN 'Unspecified'
            WHEN 1 THEN 'Read Uncommitted'
            WHEN 2 THEN 'Read Committed'
            WHEN 3 THEN 'Repeatable'
            WHEN 4 THEN 'Serializable'
            WHEN 5 THEN 'Snapshot'
        END
    ,ConnectionWrites   = con.num_writes
    ,ConnectionReads    = con.num_reads    
    ,Authentication     = con.auth_scheme
FROM sys.dm_exec_requests er
LEFT JOIN sys.dm_exec_sessions ses
ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con
ON con.session_id = ses.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY 
(
    SELECT execution_count = MAX(cp.usecounts)
    FROM sys.dm_exec_cached_plans cp
    WHERE cp.plan_handle = er.plan_handle
) ec
ORDER BY
    er.blocking_session_id DESC,
    er.logical_reads + er.reads DESC,
    er.session_id
 
END

GO
/****** Object:  Table [dbo].[Brand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Brand](
	[BrandID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[CustomerID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[BehaviorGroupID] [int] NULL,
 CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BrandKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BrandKeyword](
	[BrandKeywordID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BrandID] [int] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[Type] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_BrandKeyword] PRIMARY KEY CLUSTERED 
(
	[BrandKeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BrandUser]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BrandUser](
	[BrandUserID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BrandID] [int] NOT NULL,
	[UserDetailID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_BrandUser] PRIMARY KEY CLUSTERED 
(
	[BrandUserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Channel]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Channel](
	[ChannelID] [int] NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[ParentID] [int] NULL,
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_Channel] PRIMARY KEY CLUSTERED 
(
	[ChannelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CheckSiteData]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CheckSiteData](
	[CheckSiteDataId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[SiteGuid] [uniqueidentifier] NOT NULL,
	[CheckDate] [datetime] NOT NULL,
	[RecordNum] [int] NOT NULL,
	[SubRecordNum] [int] NOT NULL,
	[Status] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](500) NULL,
	[CmsRecordNum] [int] NULL,
	[CmsSubRecordNum] [int] NULL,
 CONSTRAINT [PK_CheckSiteData] PRIMARY KEY CLUSTERED 
(
	[CheckSiteDataId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Contacts]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Contacts](
	[ContactId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[CustomerId] [int] NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Address] [nvarchar](500) NOT NULL,
	[PhoneNumber] [nvarchar](50) NOT NULL,
	[CellPhone] [nvarchar](50) NOT NULL,
	[Email] [nvarchar](100) NOT NULL,
	[Fax] [nvarchar](50) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[UserUpdate] [nvarchar](50) NOT NULL,
	[Descriptions] [nvarchar](500) NULL,
	[IsDelete] [bit] NOT NULL,
 CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED 
(
	[ContactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Customer]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Customer](
	[CustomerID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[Code] [varchar](64) NOT NULL,
 CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CustomerBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerBrand](
	[CustomerBrandID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BrandID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_CustomerBrand] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC,
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DailyReport]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DailyReport](
	[DailyReportId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[SendTime] [datetime] NOT NULL,
	[UserName] [nvarchar](100) NOT NULL,
	[Status] [bit] NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[Description] [nvarchar](1024) NULL,
 CONSTRAINT [PK_DailyReport] PRIMARY KEY CLUSTERED 
(
	[DailyReportId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EmotionGroups]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmotionGroups](
	[EmotionGroupID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GroupName] [nvarchar](100) NOT NULL,
	[Type] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[Descriptions] [nvarchar](500) NULL,
 CONSTRAINT [PK_EmotionGroups] PRIMARY KEY CLUSTERED 
(
	[EmotionGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EmotionKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmotionKeyword](
	[EmotionKeywordID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Word] [nvarchar](256) NOT NULL,
	[WordWithoutAccent] [nvarchar](256) NULL,
	[Type] [int] NOT NULL,
	[EmotionID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_EmotionKeyword] PRIMARY KEY CLUSTERED 
(
	[EmotionKeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Emotions]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Emotions](
	[EmotionID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[ParentId] [int] NULL,
	[GroupId] [int] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_Emotions] PRIMARY KEY CLUSTERED 
(
	[EmotionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FanPage]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FanPage](
	[Id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[PageId] [nvarchar](512) NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[LatestUpdatedDate] [datetime] NULL,
 CONSTRAINT [PK_FanPage] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FanPageKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FanPageKeyword](
	[Id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[FanPageID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_FanPageKeyword] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FBPublishPostType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FBPublishPostType](
	[FBPPTypeId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TypeName] [varchar](50) NOT NULL,
	[Param] [varchar](1024) NOT NULL,
	[AccessToken] [varchar](250) NOT NULL,
	[AppId] [varchar](250) NOT NULL,
	[Examble] [nvarchar](2048) NULL,
 CONSTRAINT [PK_FBPublishPostType] PRIMARY KEY CLUSTERED 
(
	[FBPPTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FBPublistPost]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FBPublistPost](
	[FBPublishPostId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[SIteGUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](500) NOT NULL,
	[Type] [int] NOT NULL,
	[PageId] [nvarchar](100) NOT NULL,
	[KeywordId] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[UpdateBy] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Status] [nvarchar](50) NULL,
	[Description] [nvarchar](500) NULL,
 CONSTRAINT [PK_FBPublistPost] PRIMARY KEY CLUSTERED 
(
	[FBPublishPostId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Keyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Keyword](
	[KeywordID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Word] [nvarchar](512) NOT NULL,
	[WordWithoutAccent] [nvarchar](512) NULL,
	[IsActive] [bit] NOT NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[IsDeleted] [bit] NOT NULL,
	[IsBrand] [bit] NOT NULL,
 CONSTRAINT [PK_Keyword] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Profile]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Profile](
	[ProfileID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Level1Name] [nvarchar](1024) NULL,
	[Level1Phone] [varchar](1024) NULL,
	[Level1Email] [varchar](1024) NULL,
	[Level2Name] [nvarchar](1024) NULL,
	[Level2Phone] [varchar](1024) NULL,
	[Level2Email] [varchar](1024) NULL,
	[Level3Name] [nvarchar](1024) NULL,
	[Level3Phone] [varchar](1024) NULL,
	[Level3Email] [varchar](1024) NULL,
	[AccountManagerName] [nvarchar](1024) NULL,
	[AccountManagerPhone] [varchar](1024) NULL,
	[AccountManagerEmail] [varchar](1024) NULL,
	[BrandID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Profile] PRIMARY KEY CLUSTERED 
(
	[ProfileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProjectBrand]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProjectBrand](
	[ProjectBrandID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ProjectID] [int] NOT NULL,
	[Description] [nvarchar](500) NULL,
	[InsertedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
	[UserName] [nvarchar](50) NULL,
	[IsDelete] [bit] NOT NULL,
	[BrandID] [int] NOT NULL,
 CONSTRAINT [PK_ProjectBrand] PRIMARY KEY CLUSTERED 
(
	[ProjectBrandID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Projects]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Projects](
	[ProjectId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ProjectName] [nvarchar](500) NOT NULL,
	[TypeId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[MainContractId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[UserUpdate] [uniqueidentifier] NOT NULL,
	[Description] [nchar](1000) NULL,
	[Leader] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED 
(
	[ProjectId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ProjectType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProjectType](
	[ProjectTypeId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TypeName] [nvarchar](500) NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[UserUpdate] [uniqueidentifier] NOT NULL,
	[Descriptions] [nvarchar](1000) NULL,
 CONSTRAINT [PK_ProjectType] PRIMARY KEY CLUSTERED 
(
	[ProjectTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ProjectUser]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProjectUser](
	[ProjectUserID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ProjectID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsLeader] [bit] NULL,
 CONSTRAINT [PK_ProjectUserID] PRIMARY KEY CLUSTERED 
(
	[ProjectUserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Site]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Site](
	[SiteID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[SiteTypeID] [int] NOT NULL,
	[SiteCategoryID] [int] NOT NULL,
	[URL] [varchar](1024) NOT NULL,
	[URLName] [varchar](1024) NOT NULL,
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[Duration] [int] NULL,
 CONSTRAINT [PK_SITEID] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SiteCategory]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SiteCategory](
	[SiteCategoryID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SiteCategory] PRIMARY KEY CLUSTERED 
(
	[SiteCategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SiteType]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SiteType](
	[SiteTypeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL,
 CONSTRAINT [PK_SiteType] PRIMARY KEY CLUSTERED 
(
	[SiteTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SubKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SubKeyword](
	[SubKeywordID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[Word] [nvarchar](512) NOT NULL,
	[WordWithoutAccent] [nvarchar](512) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_SubKeyword] PRIMARY KEY CLUSTERED 
(
	[SubKeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[sysdiagrams]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[sysdiagrams](
	[name] [sysname] NOT NULL,
	[principal_id] [int] NOT NULL,
	[diagram_id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[version] [int] NULL,
	[definition] [varbinary](max) NULL,
 CONSTRAINT [PK__sysdiagr__C2B05B61607251E5] PRIMARY KEY CLUSTERED 
(
	[diagram_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UK_principal_name] UNIQUE NONCLUSTERED 
(
	[principal_id] ASC,
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Tag]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tag](
	[TagID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Word] [nvarchar](256) NOT NULL,
	[WordWithoutAccent] [nvarchar](256) NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[TagGroupID] [int] NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_Tag] PRIMARY KEY CLUSTERED 
(
	[TagID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TagGroup]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TagGroup](
	[TagGroupID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[Type] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ParentID] [int] NULL,
 CONSTRAINT [PK_TagGroup] PRIMARY KEY CLUSTERED 
(
	[TagGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TagGroupKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TagGroupKeyword](
	[TagGroupKeywordID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[KeywordID] [int] NOT NULL,
	[TagGroupID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_TagKeywordKeyword] PRIMARY KEY CLUSTERED 
(
	[TagGroupKeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TargetFilter]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TargetFilter](
	[TargetFilterID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](512) NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_TargetFilter] PRIMARY KEY CLUSTERED 
(
	[TargetFilterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TargetFilterAttribute]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TargetFilterAttribute](
	[TargetFilterAttributeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TargetFilterID] [int] NOT NULL,
	[SiteID] [int] NOT NULL,
	[ChannelID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TargetFilterAttribute] PRIMARY KEY CLUSTERED 
(
	[TargetFilterAttributeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Type]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Type](
	[TypeID] [int] NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](512) NOT NULL,
	[ParentID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Type] PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserDetail]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserDetail](
	[UserDetailID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[UserName] [nvarchar](128) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[FullName] [nvarchar](128) NOT NULL,
	[Email] [nvarchar](128) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_UserDetail] PRIMARY KEY CLUSTERED 
(
	[UserDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Word]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Word](
	[WordID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[WordWithAccent] [nvarchar](512) NOT NULL,
	[WordWithoutAccent] [nvarchar](512) NULL,
	[KeywordID] [int] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_Word] PRIMARY KEY CLUSTERED 
(
	[WordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[ServerRunningKeyword]    Script Date: 6/26/2013 8:55:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[ServerRunningKeyword]
AS

	SELECT '221.132.37.22' as 'Svr',kw.WordWithoutAccent ,kci.KeywordID, kci.IsRunning, kci.UpdatedDate
	FROM   [221.132.37.22].[DataCopyLog].[dbo].[KeywordCopyInfo] kci with(nolock)
			join ContentAggregator.dbo.Keyword kw with(nolock) on kw.KeywordID=kci.KeywordID	
	where	kw.Isactive=1
	UNION ALL
	SELECT '221.132.37.45' as 'Svr',kw.WordWithoutAccent ,kci.KeywordID, kci.IsRunning, kci.UpdatedDate
	FROM   [221.132.37.45].[DataCopyLog].[dbo].[KeywordCopyInfo] kci with(nolock)
			join ContentAggregator.dbo.Keyword kw with(nolock) on kw.KeywordID=kci.KeywordID
	where	kw.Isactive=1
	UNION ALL
	SELECT '221.132.37.70' as 'Svr',kw.WordWithoutAccent ,kci.KeywordID, kci.IsRunning, kci.UpdatedDate
	FROM   [221.132.37.70].[DataCopyLog].[dbo].[KeywordCopyInfo] kci with(nolock)
			join ContentAggregator.dbo.Keyword kw with(nolock) on kw.KeywordID=kci.KeywordID
	where	kw.Isactive=1


GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Brand"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 217
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ServerRunningKeyword'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ServerRunningKeyword'
GO
USE [master]
GO
ALTER DATABASE [ContentAgg_ReplSub] SET  READ_WRITE 
GO
