if OBJECT_ID ( 'GetCMSRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetCMSRecords
GO
/*
* Description: get a list of records with emotions
* Params	
	SubKeywordID: -1: all
	TagGroupID: -1, (int)
	TagIDs: null, a string of tags
	UserID: -1 
	Emotion: null(-1), 1-Positive, 2-Negative, 3-Neutral
	Tagged: tagged, untagged	
	Sorting: InsertedDate, PublishedDate, UpdatedDate
	Reviewed: null, reviewed, unreviewed
	Deleted: null, deleted, irrelevant,
	Approved: null, approved, unapproved
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetCMSRecords 
	@KeywordID = 1,
	@SubKeywordID = -1,
	@SiteIDs = null,
	@TagGroupID = -1,	
	@TagIDs = null,	
	@Reviewed = null,
	@RecordUserID = 19,
	@UserID = -1,
	@StartDate = '2012-01-05 00:00:00',
	@EndDate = '2013-01-12 23:59:59',
	@Emotion = -1,
	@Deleted = null,
	@Approved = null,
	@Sorting = 'PublishedDate',
	@FromRecord = 0,
	@ToRecord = 50
*/
SET ANSI_NULLS ON
GO
CREATE PROCEDURE GetCMSRecords
	@KeywordID int,
	@SubKeywordID int,
	@SiteIDs varchar(1024),	
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
WITH RECOMPILE
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	);
				
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
		select rd.RecordID, rd.Title, s.URL as ''SiteURL'', s.SiteTypeID Type, rd.URL, rd.PublishedDate as ''PublishedDate'', rd.Score
		from ContentCrawler.dbo.Record rd WITH(NOLOCK) '			
			
	IF @SiteIDs is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
		inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		left join Site s with(nolock) on s.GUID = rd.SiteGUID '
	END;			

	--Where clause
	SET @SQLString = @SQLString + ' 
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](rd.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate '
		
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
	ELSE
	BEGIN
		SET @SQLString = @SQLString + ' 
		and rd.IsDeleted = 0 and (rd.Irrelevant = 0 or rd.Irrelevant is null)'
	END

	IF @Reviewed = 'reviewed'
	BEGIN		
		SET @SQLString = @SQLString + ' 
		and rd.IsReviewed = 1'	
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN		
		SET @SQLString = @SQLString + ' 		
		and rd.IsReviewed = 0'	
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
		inner join ContentCrawler.dbo.BriefContentTag bct on bc.BriefContentID = bct.BriefContentID and bct.IsDeleted = 0
		inner join @TempTag tt on bct.TagGUID = tt.TagGUID 
		where bc.RecordID = rd.RecordID and bc.IsDeleted = 0 ' + (case when @UserID <> -1 then 'and bct.UserID = @UserID' else '' end) + ' )'
		
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
				@SiteIDs varchar(1024),
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


if OBJECT_ID ( 'GetCMSSubRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetCMSSubRecords
GO
/*
* Description: get a list of records with emotions
* Params
	Emotion: -1(null), 1-Positive, 2-Negative, 3-Neutral
	SubKeywordID: -1: all
	TagGroupID: filter records that tagged by tag in this tag group
	Owner: none: records that have not tagged sentiment. auto: service. manual: 
	Tagged: tagged, untagged
	Bookmarked: followed, unfollowed
	Sorting: InsertedDate, PublishedDate, UpdatedDate
	Reviewed: reviewed, reviewedinrange, unreviewed, unreviewedinrange, all, allinrange
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetCMSSubRecords 
	@RecordID = 70066,	
	@KeywordGUID = '5517425F-C2E7-44C0-B28A-9BBAA7917AE4',
	@TagGroupID = -1,	
	@TagIDs = null,
	@Reviewed = 'all',	
	@UserID = -1,
	@StartDate = '2/10/2012',
	@EndDate = '10/12/2013',
	@Emotion = -1,
	@Deleted = null,
	@Approved = null,
	@Words = null,
	@FromRecord = 0,
	@ToRecord = 100,
	@Pre = null,
	@Post = null
*/
SET ANSI_NULLS ON
GO
CREATE PROCEDURE GetCMSSubRecords
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
	@Words nvarchar(512),   
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
		select tb.SubRecordID, tb.Content, tb.Author, tb.PublishedDate, tb.IsApproved, tb.IsDelete, tb.Irrelevant, tb.SentimentID
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

		select distinct tb.SubRecordID, tb.Content, tb.Author, tb.PublishedDate, tb.IsApproved, tb.IsDelete, tb.Irrelevant, tb.SentimentID
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

if OBJECT_ID ( 'GetCMSRecordCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetCMSRecordCount
GO
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
	@StartDate = '1/1/2012',
	@EndDate = '11/20/2013',
	@Emotion = -1,
	@Deleted = null,
	@Approved = null
*/
CREATE PROCEDURE GetCMSRecordCount
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
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	);	
	
	DECLARE @Pos int		
	-- create temp site id
	DECLARE @TempSite table
	(
		SiteID int,
		SiteGUID uniqueidentifier,
		URL varchar(1024)
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
				INSERT INTO @TempSite (SiteID, SiteGUID, URL) select SiteID, GUID, URL from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @SiteIDs = RIGHT(@SiteIDs, LEN(@SiteIDs) - @Pos)
			SET @Pos = CHARINDEX('','', @SiteIDs, 1)
		END
	END;	

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
		select count(distinct rd.RecordID) RecordCount, count(distinct sr.SubRecordID) SubRecordCount
		from ContentCrawler.dbo.Record rd WITH(NOLOCK)
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on sr.RecordID = rd.RecordID'
				
			
	IF @SiteIDs is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
			left join Site s with(nolock) on s.GUID = rd.SiteGUID '
	END;		

	SET @SQLString = @SQLString + ' 
		where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](rd.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
		and rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate '
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
	
	IF @Reviewed = 'reviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 
		and rd.IsReviewed = 1'	
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 		
		and rd.IsReviewed = 0'	
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
		inner join ContentCrawler.dbo.BriefContentTag bct on bc.BriefContentID = bct.BriefContentID and bct.IsDeleted = 0
		inner join @TempTag tt on bct.TagGUID = tt.TagGUID 
		where bc.RecordID = rd.RecordID and bc.IsDeleted = 0 ' + (case when @UserID <> -1 then 'and bct.UserID = @UserID' else '' end) + ' )'
		
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

if OBJECT_ID ( 'GetCMSSubRecordCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetCMSSubRecordCount
GO
/*
* Description: get reviewed, and total subrecords of record
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetCMSSubRecordCount
	@KeywordGUID = '6F2A0198-08C0-490B-84D8-E0631187F9A7',
	@RecordID = 849
*/
SET ANSI_NULLS ON
GO
CREATE PROCEDURE GetCMSSubRecordCount
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
		and sr.RecordID = @LocRecordID and sr.IsDeleted = 0 and sr.IsReviewed = 1) Reviewed, 
	(select count(sr1.SubRecordID) from ContentCrawler.dbo.SubRecord sr1 
	where [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](sr1.KeywordGUID) = [ContentCrawler].$partition.[KeywordGUIDPartitionFunction](@KeywordGUID)
	and sr1.RecordID = @LocRecordID and sr1.IsDeleted = 0 and (sr1.Irrelevant is null or sr1.Irrelevant = 0) ) Total
			
END
GO


if OBJECT_ID ( 'GetCMSSubRecordCountInRange', 'P' ) IS NOT NULL
	DROP PROCEDURE GetCMSSubRecordCountInRange
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
	@RecordID = 849,
	@StartDate = '2/10/2012',
	@EndDate = '2/12/2013'
*/
CREATE PROCEDURE GetCMSSubRecordCountInRange
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
