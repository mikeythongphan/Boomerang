/*
Store procedures for emotion dashboard report
*/

USE [ContentAggregator]
GO


if OBJECT_ID ( 'GetDBBuzzByDate', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBBuzzByDate
GO
/*
* Description: Get total reviewed records/comment date
* Params
	SiteType: -1: all
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBBuzzByDate 
	@KeywordID = 1,
	@StartDate = '1/1/2013',
	@EndDate = '8/31/2013',
	@SiteType = -1
*/
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

if OBJECT_ID ( 'GetDBSiteTypeCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBSiteTypeCount
GO
/*
* Description: Get total reviewed records/comment by site types
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBSiteTypeCount 
	@KeywordID = 1,
	@StartDate = '1/1/2013',
	@EndDate = '1/30/2013'
*/
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

if OBJECT_ID ( 'GetDBSiteCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBSiteCount
GO
/*
* Description: Get total reviewed records by site
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBSiteCount 
	@KeywordID = 1,
	@StartDate = '1/1/2013',
	@EndDate = '1/30/2013'
*/
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


if OBJECT_ID ( 'GetDBSiteTypeAuthorCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBSiteTypeAuthorCount
GO
/*
* Description: Get total author of reviewed records/comments by site types
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBSiteTypeAuthorCount 
	@KeywordID = 1,
	@StartDate = '1/1/2013',
	@EndDate = '1/30/2013'
*/
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

if OBJECT_ID ( 'GetDBAuthorCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBAuthorCount
GO
/*
* Description: Get authors and their comment count
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBAuthorCount 
	@KeywordID = 1,
	@StartDate = '1/1/2013',
	@EndDate = '1/30/2013'
*/
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


if OBJECT_ID ( 'GetDBTopTopics', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBTopTopics
GO
/*
* Description: 
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBTopTopics 
	@KeywordID = 1,
	@StartDate = '1/1/2013',
	@EndDate = '2/28/2013'
*/
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


if OBJECT_ID ( 'GetDBRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBRecords
GO

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
WITH RECOMPILE
AS
/*
* Description: get records for context records
* Params
* Sample:
EXEC GetDBRecords 
	@KeywordID = 1,
	@SiteIDs = null,
	@Emotion = 1,
	@TagGroupID = 1,
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
			inner join ContentCrawler.dbo.BriefContentTag bct on bct.BriefContentID = bc.BriefContentID and bct.TagGroupGUID = @TagGroupGUID '
		END
		ELSE
		BEGIN
			SET @SQLWhere = @SQLWhere + '
			inner join ContentCrawler.dbo.BriefContent bc with(NOLOCK) on sr.SubRecordID = bc.SubRecordID and bc.IsDeleted = 0
			inner join ContentCrawler.dbo.BriefContentTag bct on bct.BriefContentID = bc.BriefContentID and bct.TagGroupGUID = @TagGroupGUID '
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

if OBJECT_ID ( 'GetDBSubRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBSubRecords
GO
/*
* Description: get records for context records
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBSubRecords 
	@KeywordGUID = '6F2A0198-08C0-490B-84D8-E0631187F9A7',
	@RecordID = 44,	
	@TagGroupID = -1,	
	@TagIDs = null,
    @Emotion = -1,
	@StartDate = '1/1/2013',
	@EndDate = '1/30/2013',
	@FromRecord = 0,
	@ToRecord = 1000
*/
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
		and exists (select * from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK) where bc.SubRecordID = sr.SubRecordID and bc.IsDeleted = 0 ' + CASE WHEN @Emotion <> -1 THEN ' and bc.Sentiment = @Emotion' ELSE '' END + ') '
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

if OBJECT_ID ( 'GetDBEmotionCounts', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBEmotionCounts
GO
/*
* Description: count sentiments for a topic
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBEmotionCounts
	@KeywordGUID = '6F2A0198-08C0-490B-84D8-E0631187F9A7',
	@RecordID = 44,	
	@TagGroupID = -1,	
	@TagIDs = null,
    @Emotion = -1,
	@StartDate = '1/1/2013',
	@EndDate = '1/30/2013 23:00:00'	
*/
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
	from ContentCrawler.dbo.BriefContent bc with(NOLOCK)
	inner join ContentCrawler.dbo.SubRecord sr with(NOLOCK) on bc.SubRecordID = sr.SubRecordID and bc.IsDeleted = 0 
	and sr.RecordID = @RecordID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate	
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	group by bc.Sentiment				
END
GO


if OBJECT_ID ( 'GetDBTotalSitesByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBTotalSitesByTime
GO
/*
* Description:
* Params	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBTotalSitesByTime 
	@KeywordID = 1,
	@StartDate = '1/1/2013',
	@EndDate = '1/30/2013'
*/
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

if OBJECT_ID ( 'GetDBTotalVoicesByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBTotalVoicesByTime
GO
/*
* Description:
* Params	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBTotalVoicesByTime 
	@KeywordID = 1,
	@StartDate = '1/1/2013',
	@EndDate = '1/30/2013 23:59:59'
*/
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


if OBJECT_ID ( 'GetDBEmotions', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBEmotions
GO
/*
* Description: Get total reviewed records/comment by emotion
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetDBEmotions 
	@KeywordID = 1,
	@StartDate = '1/27/2013 10:15:00',
	@EndDate = '1/28/2013 23:00:00'
*/
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

/*Live monitoring*/

if OBJECT_ID ( 'GetDBLiveMonitoringLatestRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBLiveMonitoringLatestRecords
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


if OBJECT_ID ( 'GetDBLiveMonitoringRelatedMentions', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBLiveMonitoringRelatedMentions
GO
/*
* Description: 
* History
* Sample:
EXEC GetDBLiveMonitoringRelatedMentions 
	@KeywordID = 1,
	@Date = '2013-01-19 21:56:00'	
*/
CREATE PROCEDURE GetDBLiveMonitoringRelatedMentions
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


if OBJECT_ID ( 'GetDBLiveMonitoringBuzzTrend', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBLiveMonitoringBuzzTrend
GO
/*
* Description: 
* History
* Sample:
EXEC GetDBLiveMonitoringBuzzTrend 
	@KeywordID = 1,
	@Date = '1/19/2013 21:00:00'	
*/
CREATE PROCEDURE GetDBLiveMonitoringBuzzTrend
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


if OBJECT_ID ( 'GetDBLiveMonitoringTopSources', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBLiveMonitoringTopSources
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
CREATE PROCEDURE GetDBLiveMonitoringTopSources
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


if OBJECT_ID ( 'GetDBLiveMonitoringTopTopics', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBLiveMonitoringTopTopics
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
CREATE PROCEDURE GetDBLiveMonitoringTopTopics
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

/* 24h Report */
if OBJECT_ID ( 'GetDBLatestBriefContents', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBLatestBriefContents
GO
CREATE PROCEDURE GetDBLatestBriefContents
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
	select top 10 bc.BriefContentID, bc.Content, sr.PublishedDate, sr.Author, sr.URL, s.URLName
	from ContentCrawler.dbo.BriefContent bc WITH(NOLOCK)
	inner join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on bc.SubRecordID = sr.SubRecordID
	inner join ContentAggregator.dbo.Site s on sr.SiteGUID = s.GUID
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID) 
	and sr.KeywordGUID = @KeywordGUID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate
	and bc.Sentiment = @Sentiment and bc.IsDeleted = 0
	order by bc.BriefContentID desc				
END
GO

if OBJECT_ID ( 'GetDBTagGroupCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBTagGroupCount
GO
CREATE PROCEDURE GetDBTagGroupCount
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
	@KeywordGUID = '6F2A0198-08C0-490B-84D8-E0631187F9A7',
	@Sentiment = 3,
	@StartDate = '2013-01-17 23:29:55',
	@EndDate = '2013-01-30 23:29:55'
*/
BEGIN		
	select top 5 tg.Name, count(*) Total
	from ContentCrawler.dbo.BriefContentTag bct with(NOLOCK)
	inner join ContentCrawler.dbo.BriefContent bc with(NOLOCK) on bct.BriefContentID = bc.BriefContentID
	inner join ContentCrawler.dbo.SubRecord sr with(NOLOCK) on bct.SubRecordID = sr.SubRecordID
	inner join ContentAggregator.dbo.TagGroup tg with(NOLOCK) on tg.GUID = bct.TagGroupGUID
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID) 
	and sr.KeywordGUID = @KeywordGUID and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate
	and bc.Sentiment = @Sentiment
	group by tg.Name			
END
GO


if OBJECT_ID ( 'GetDBFactCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBFactCount
GO
CREATE PROCEDURE GetDBFactCount
	@KeywordGUID uniqueidentifier,	
	@StartDate datetime,
	@EndDate datetime
WITH RECOMPILE
AS
/*
* Description: 
* Sample:
EXEC GetDBFactCount 
	@KeywordGUID = '6F2A0198-08C0-490B-84D8-E0631187F9A7',	
	@StartDate = '2013-01-29 9:29:55',
	@EndDate = '2013-01-30 23:29:55'
*/
BEGIN		
	select t.Name, count(*) Total
	from ContentCrawler.dbo.SubRecord sr with(NOLOCK)
	inner join ContentCrawler.dbo.BriefContent bc on sr.SubRecordID = bc.SubRecordID
	inner join Type t on t.TypeID = bc.Sentiment
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate
	group by t.Name
	union
	select 'Site' 'Name', count(distinct sr.SiteGUID) Total
	from ContentCrawler.dbo.SubRecord sr with(NOLOCK)	
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate
	union
	select 'Voice' 'Name', count(distinct sr.Author) Total
	from ContentCrawler.dbo.SubRecord sr with(NOLOCK)	
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	and sr.IsReviewed = 1 and sr.IsDeleted = 0 and sr.PublishedDate between @StartDate and @EndDate
		
END
GO


if OBJECT_ID ( 'GetDBConversationExport', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDBConversationExport
GO

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
	@TagGroupID = 201,
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
