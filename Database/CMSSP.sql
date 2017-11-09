if OBJECT_ID ( 'GetCMSRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetCMSRecords
GO
/*
* Description: get a list of records with emotions
* Params
	Emotion: 8 emotions
	SubKeywordID: -1: all
	TagGroupID: filter records that tagged by tag in this tag group
	Tags: a string of tags
	UserID: -1 
	Emotion: null,...
	Tagged: tagged, untagged
	Bookmarked: followed, unfollowed
	Sorting: InsertedDate, PublishedDate, UpdatedDate
	Reviewed: null, reviewed, unreviewed
	Deleted: null, deleted, irrelevant,
	Approved: null, approved, unapproved
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetCMSRecords 
	@KeywordID = 72,
	@SubKeywordID = -1,
	@SiteIDs = null,
	@TagGroupID = -1,	
	@TagIDs = null,
	@Bookmarked = null,	
	@Reviewed = null,	
	@UserID = -1,
	@StartDate = '1/1/2012',
	@EndDate = '9/2/2012',
	@Emotion = null,
	@Deleted = null,
	@Approved = null,
	@Sorting = 'PublishedDate',
	@FromRecord = 0,
	@ToRecord = 500
*/
SET ANSI_NULLS ON
GO
CREATE PROCEDURE GetCMSRecords
	@KeywordID int,
	@SubKeywordID int,
	@SiteIDs varchar(1024),	
	@TagGroupID int,	
	@TagIDs varchar(1024),
	@Bookmarked varchar(128),
	@Reviewed varchar(128),	
	@UserID int,
    @StartDate datetime,
    @EndDate datetime,
    @Emotion varchar(32),
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
	declare @SubKeywordGUID uniqueidentifier;
	
	IF @SubKeywordID <> -1
	BEGIN
		set @SubKeywordGUID = (select GUID from ContentAggregator.dbo.SubKeyword where SubKeywordID = @SubKeywordID	);
	END	
	
	DECLARE @Pos int		
	-- create temp site id
	DECLARE @TempSite table
	(
		SiteID int,
		SiteGUID uniqueidentifier,
		URL varchar(1024),
		Type int
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
				INSERT INTO @TempSite (SiteID, SiteGUID, URL, Type) select SiteID, GUID, URL, Type from Site where SiteID = CAST(@SiteID AS int)				
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
	
	SET @SQLString = @SQLString + ' with records as(
		select ROW_NUMBER() OVER(ORDER BY rd.' + @Sorting + ' ASC) AS ''RowNumber'', rd.RecordID, rd.Title, s.URL as ''SiteURL'', s.Type, rd.URL, rd.PublishedDate as ''PublishedDate'', fre.Score
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
			
	
	IF @Emotion is not null
	BEGIN
		SET @SQLString = @SQLString + '			
			inner join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on rd.RecordID = fre.RecordID and fre.IsDeleted = 0 and fre.' + @Emotion + ' = 1 '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		left join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on rd.RecordID = fre.RecordID and fre.IsDeleted = 0'
	END

	SET @SQLString = @SQLString + ' 
		where rd.KeywordGUID = @KeywordGUID			
		and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate '
		
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
		and (rd.IsDeleted = 0 or rd.IsDeleted is null) 
		and (rd.Irrelevant = 0 or rd.Irrelevant is null)'
	END

	IF @SubKeywordID <> -1
	BEGIN
		SET @SQLString = @SQLString + ' and rd.SubKeywordGUID = @SubKeywordGUID'
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + ' and rd.SubKeywordGUID is null'
	END
	
	IF @Bookmarked = 'followed'
	BEGIN
		SET @SQLString = @SQLString + ' and rd.IsFollowed = 1'
	END
	ELSE IF @Bookmarked = 'unfollowed'
	BEGIN
		SET @SQLString = @SQLString + ' and ( rd.IsFollowed is null or rd.IsFollowed = 0)'
	END	
	
	IF @Approved = 'approved'
	BEGIN
		
		IF @TagIDs is null and @UserID = -1 and @Reviewed is null
		BEGIN
			SET @SQLString = @SQLString + ' 
			and exists (select * from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) where rd.RecordID = sr.RecordID and sr.IsApproved = 1)'
		END
	END

	if @TagIDs is not null
	BEGIN		
		SET @SQLString = @SQLString + ' 
		and exists (select * from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) 
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on rbc.RecordID = sr.SubRecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0) 
		inner join ContentCrawler.dbo.BriefContentTag bct on rbc.RecordBriefContentID = bct.RecordBriefContentID and bct.IsDeleted = 0
		inner join @TempTag tt on bct.TagGUID = tt.TagGUID 
		where (rbc.RecordID = rd.RecordID or sr.RecordID = rd.RecordID) and rbc.IsDeleted = 0 ' + (case when @UserID <> -1 then 'and bct.UserID = @UserID' else '' end) + ' )'
		
		SET @Reviewed = null;
		SET @UserID = -1;
		SET @TagGroupID = -1;
	END
	
	IF @UserID <> -1
	BEGIN
		SET @Reviewed = null; --if user is selected, it mean reviewed records
		SET @SQLString = @SQLString + '
		and exists (select * from ContentCrawler.dbo.RecordBriefContent bct WITH(NOLOCK) 
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on bct.RecordID = sr.SubRecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0) and bct.IsSubRecord = 1
		where (bct.RecordID = rd.RecordID or sr.RecordID = rd.RecordID) and bct.UserID = @UserID and bct.IsDeleted = 0 ' + (case when @Approved is not null then 'and sr.IsApproved = 1' else '' end) + ' )'
	END
	
	IF @Reviewed = 'reviewed'
	BEGIN		
		SET @SQLString = @SQLString + ' 
		and exists (select * from ContentCrawler.dbo.RecordBriefContent bct WITH(NOLOCK) 
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on bct.RecordID = sr.SubRecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0) and bct.IsSubRecord = 1
		where (bct.RecordID = rd.RecordID or sr.RecordID = rd.RecordID) and bct.IsDeleted = 0 )'	
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN		
		SET @SQLString = @SQLString + ' 		
		and not exists (select * from ContentCrawler.dbo.RecordBriefContent bct WITH(NOLOCK) 
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on bct.RecordID = sr.SubRecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0) and bct.IsSubRecord = 1
		where (bct.RecordID = rd.RecordID or sr.RecordID = rd.RecordID) and bct.IsDeleted = 0 )'	
	END	
	IF @TagGroupID <> -1 --all
	BEGIN		
		SET @SQLString = @SQLString + '
			and rd.RecordID in (select distinct sr.RecordID from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)			
			inner join ContentCrawler.dbo.BriefContentTag bct WITH(NOLOCK) on sr.SubRecordID = bct.RecordID and bct.IsSubRecord = 1 and bct.IsDeleted = 0
			inner join ContentAggregator.dbo.Tag t with(nolock) on bct.TagGUID = t.GUID and t.TagGroupID = @TagGroupID) '
	END;			
		
	SET @SQLString = @SQLString + '	
	)		
	select RecordID, Title, ISNULL(SiteURL,'''') SiteURL, ISNULL(Type, 1) Type, URL, PublishedDate, Score	
	from records
	where RowNumber > @FromRecord and RowNumber <= @ToRecord
	order by RowNumber asc';	
	
	SET @ParmDefinition = '
				@KeywordID int,
				@SiteIDs varchar(1024),
				@TagGroupID int,
				@TagIDs varchar(1024),
				@SubKeywordID int,										
				@UserID int,				
				@StartDate datetime,
				@EndDate datetime,
				@Emotion varchar(32),
				@FromRecord int,
				@ToRecord int';
	
	print @SQLString;
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@SiteIDs,
						@TagGroupID,
						@TagIDs,
					  	@SubKeywordID,									
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
	Emotion: 8 emotions
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
	@RecordID = 92856,	
	@TagGroupID = -1,	
	@TagIDs = null,
	@Reviewed = 'unapproved',	
	@UserID = -1,
	@StartDate = '2/10/2012',
	@EndDate = '10/12/2012',
	@Emotion = null,
	@Deleted = null,
	@Approved = null,
	@Words = '"tieng"',
	@FromRecord = 0,
	@ToRecord = 100,
	@Pre = null,
	@Post = null
*/
SET ANSI_NULLS ON
GO
CREATE PROCEDURE GetCMSSubRecords
	@RecordID int,	
	@TagGroupID int,		
	@TagIDs varchar(1024),
	@Reviewed varchar(128),	
	@UserID int,
    @StartDate datetime,
    @EndDate datetime,
    @Emotion varchar(32),
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
		set @SQLUserID = 'and rbc.UserID = ' + CONVERT(varchar(5), @UserID)
	END
				
	SET @SQLString = '
		declare @srtb table
		(
			RowNumber int,
			SubRecordID int,
			Content nvarchar(max),
			Author nvarchar(256),
			PublishedDate datetime,
			IsApproved bit
		)

		insert into @srtb (RowNumber, SubRecordID, Content, Author, PublishedDate, IsApproved)
		select ROW_NUMBER() OVER(ORDER BY sr.PublishedDate ASC) , sr.SubRecordID, sr.Content, sr.Author, sr.PublishedDate, sr.IsApproved
		from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
		where sr.RecordID = @RecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0)'
	if @Pre is null or @Post is null
	BEGIN
		IF @Reviewed = 'reviewed'
		BEGIN		
			SET @SQLString = @SQLString + ' 
			and exists (select * from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) where rbc.RecordID = sr.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0 ' + @SQLUserID + ');'	
		END	
		ELSE IF @Reviewed = 'reviewedinrange'
		BEGIN		
			SET @SQLString = @SQLString + ' 
			and sr.PublishedDate between @StartDate and @EndDate
			and exists (select * from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) where rbc.RecordID = sr.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0 ' + @SQLUserID + ');'	
		END	
		ELSE IF @Reviewed = 'unreviewed'
		BEGIN		
			SET @SQLString = @SQLString + ' 
			and not exists (select * from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) where rbc.RecordID = sr.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0 );'	
		END	
		ELSE IF @Reviewed = 'unreviewedinrange'
		BEGIN					
			SET @SQLString = @SQLString + ' 
			and sr.PublishedDate between @StartDate and @EndDate
			and not exists (select * from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) where rbc.RecordID = sr.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0 );'	
		END	
		ELSE IF @Reviewed = 'allinrange'
		BEGIN					
			SET @SQLString = @SQLString + ' 
			and sr.PublishedDate between @StartDate and @EndDate'
		END	
		ELSE IF @Reviewed = 'approved'
		BEGIN					
			SET @SQLString = @SQLString + ' 
			and sr.IsApproved = 1
			and exists (select * from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) where rbc.RecordID = sr.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0 ' + @SQLUserID + ');'	
			
		END
		ELSE IF @Reviewed = 'unapproved'
		BEGIN					
			SET @SQLString = @SQLString + ' 
			and sr.IsApproved = 0
			and exists (select * from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) where rbc.RecordID = sr.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0 ' + @SQLUserID + ');'
		END
		
		SET @SQLString = @SQLString + ' 
		select tb.SubRecordID, tb.Content, tb.Author, tb.PublishedDate, tb.IsApproved
			,(select count(1) from ContentCrawler.dbo.RecordBriefContent rbc where rbc.RecordID = tb.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0) BriefContents
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
			inner join ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) on rbc.RecordID = tb.SubRecordID and rbc.IsDeleted = 0 ' + @SQLUserID + '
			union all
			select RowNumber
			from @srtb tb
			inner join ContentCrawler.dbo.SubRecord sr on tb.SubRecordID = sr.SubRecordID 
			and contains(sr.Content, ''' + @Words + ''')
		) a

		select distinct tb.SubRecordID, tb.Content, tb.Author, tb.PublishedDate, tb.IsApproved
		,(select count(1) from ContentCrawler.dbo.RecordBriefContent rbc WITH(NOLOCK) where rbc.RecordID = tb.SubRecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0) BriefContents
		from @srtb tb
		inner join @bctb bctb on tb.RowNumber >= bctb.RowNumber - @Pre and tb.RowNumber <= bctb.RowNumber + @Post
		order by tb.PublishedDate asc'

	END	
	
	SET @ParmDefinition = '
				@RecordID int,				        
				@FromRecord int,
				@ToRecord int,
				@Pre int,
				@Post int,
				@StartDate datetime,
				@EndDate datetime';
	print @SQLString
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID,
					  	@FromRecord,
					  	@ToRecord,						
						@Pre,
						@Post,
						@StartDate,
						@EndDate;			
END
GO

if OBJECT_ID ( 'GetCMSRecordCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetCMSRecordCount
GO
/*
* Description: 
* Params
	Emotion: 8 emotions
	SubKeywordID: -1: all
	TagGroupID: filter records that tagged by tag in this tag group		
	Bookmarked: followed, unfollowed	
	Reviewed: null, reviewed, unreviewed
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
8/14/2011	|	Vu Do	|	Add Owner column
-------------------------------------------------------------
* Sample:
EXEC GetCMSRecordCount 
	@KeywordID = 72,
	@SubKeywordID = -1,
	@SiteIDs = null,
	@TagGroupID = -1,	
	@TagIDs = null,
	@Bookmarked = null,	
	@Reviewed = null,
	@UserID = -1,		
	@StartDate = '1/1/2012',
	@EndDate = '11/20/2012',
	@Emotion = null,
	@Deleted = null,
	@Approved = null
*/
CREATE PROCEDURE GetCMSRecordCount
	@KeywordID int,
	@SubKeywordID int,
	@SiteIDs varchar(1024),
	@TagGroupID int,
	@TagIDs varchar(1024),
	@Bookmarked varchar(128),
	@Reviewed varchar(128),	
	@UserID int,
    @StartDate datetime,
    @EndDate datetime,
    @Emotion varchar(32),
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
	declare @SubKeywordGUID uniqueidentifier;
	
	IF @SubKeywordID <> -1
	BEGIN
		set @SubKeywordGUID = (select GUID from ContentAggregator.dbo.SubKeyword where SubKeywordID = @SubKeywordID	);
	END	
	
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
			
	
	IF @Emotion is not null
	BEGIN
		SET @SQLString = @SQLString + '			
			inner join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on rd.RecordID = fre.RecordID and fre.IsDeleted = 0 and fre.' + @Emotion + ' = 1 '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		left join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on rd.RecordID = fre.RecordID and fre.IsDeleted = 0'
	END

	SET @SQLString = @SQLString + ' 
		where rd.KeywordGUID = @KeywordGUID			
		and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate '
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
		and (rd.IsDeleted = 0 or rd.IsDeleted is null) 
		and (rd.Irrelevant = 0 or rd.Irrelevant is null)'
	END
	IF @SubKeywordID <> -1
	BEGIN
		SET @SQLString = @SQLString + ' and rd.SubKeywordGUID = @SubKeywordGUID'
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + ' and rd.SubKeywordGUID is null'
	END
	
	IF @Bookmarked = 'followed'
	BEGIN
		SET @SQLString = @SQLString + ' and rd.IsFollowed = 1'
	END
	ELSE IF @Bookmarked = 'unfollowed'
	BEGIN
		SET @SQLString = @SQLString + ' and ( rd.IsFollowed is null or rd.IsFollowed = 0)'
	END	
		
	IF @UserID <> -1
	BEGIN
		SET @Reviewed = null; --if user is selected, it mean reviewed records
		SET @SQLString = @SQLString + '
		and exists (select * from ContentCrawler.dbo.RecordBriefContent bct WITH(NOLOCK) 
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on bct.RecordID = sr.SubRecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0) and bct.IsSubRecord = 1
		where (bct.RecordID = rd.RecordID or sr.RecordID = rd.RecordID) and bct.UserID = @UserID and bct.IsDeleted = 0 )'
	END

	IF @Reviewed = 'reviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 
		and exists (select * from ContentCrawler.dbo.RecordBriefContent bct WITH(NOLOCK) 
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on bct.RecordID = sr.SubRecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0) and bct.IsSubRecord = 1
		where (bct.RecordID = rd.RecordID or sr.RecordID = rd.RecordID) and bct.IsDeleted = 0 )'	
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN
		
		SET @SQLString = @SQLString + ' 		
		and not exists (select * from ContentCrawler.dbo.RecordBriefContent bct WITH(NOLOCK) 
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on bct.RecordID = sr.SubRecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and (sr.Irrelevant is NULL or sr.Irrelevant = 0) and bct.IsSubRecord = 1
		where (bct.RecordID = rd.RecordID or sr.RecordID = rd.RecordID) and bct.IsDeleted = 0 )'	
	END	
	
	IF @TagGroupID <> -1 --all
	BEGIN
		SET @SQLString = @SQLString + '
			and rd.RecordID in (select distinct sr.RecordID from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)			
			inner join ContentCrawler.dbo.BriefContentTag bct WITH(NOLOCK) on sr.SubRecordID = bct.RecordID and bct.IsSubRecord = 1 and bct.IsDeleted = 0
			inner join ContentAggregator.dbo.Tag t with(nolock) on bct.TagGUID = t.GUID and t.TagGroupID = @TagGroupID) '
	END;					
					
	SET @ParmDefinition = '
				@KeywordID int,
				@SiteIDs varchar(1024),
				@TagGroupID int,
				@SubKeywordID int,										
				@UserID int,				
				@StartDate datetime,
				@EndDate datetime,
				@Emotion varchar(32)';
	
	print @SQLString;
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@SiteIDs,
						@TagGroupID,
					  	@SubKeywordID,									
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
* Description: 
* Params
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetCMSSubRecordCount 
	@RecordID = 92856
*/
SET ANSI_NULLS ON
GO
CREATE PROCEDURE GetCMSSubRecordCount
	@RecordID int
AS
BEGIN	
	DECLARE @LocRecordID int
	SET @LocRecordID = @RecordID
	select 
	(select Count(distinct sr.SubRecordID) Reviewed
		from ContentCrawler.dbo.SubRecord sr
		inner join ContentCrawler.dbo.RecordBriefContent rbc on sr.SubRecordID = rbc.RecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0
		where sr.RecordID = @LocRecordID and (sr.IsDeleted is null or sr.IsDeleted = 0) and (sr.Irrelevant is null or sr.Irrelevant = 0)) Reviewed, 
	(select count(sr1.SubRecordID) from ContentCrawler.dbo.SubRecord sr1 where sr1.RecordID = @LocRecordID and (sr1.IsDeleted is null or sr1.IsDeleted = 0) and (sr1.Irrelevant is null or sr1.Irrelevant = 0) ) Total
			
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
	@RecordID = 92847,
	@StartDate = '2/10/2012',
	@EndDate = '2/12/2012'
*/
CREATE PROCEDURE GetCMSSubRecordCountInRange
	@RecordID int,
	@StartDate datetime,
    @EndDate datetime
AS
WITH RECOMPILE
BEGIN	
	declare @LocRecordID int; SET @LocRecordID = @RecordID;
	declare @LocStartDate datetime; set @LocStartDate = @StartDate;
	declare @LocEndDate datetime; set @LocEndDate = @EndDate
	select 
	(select Count(distinct sr.SubRecordID) from ContentCrawler.dbo.SubRecord sr 
		inner join ContentCrawler.dbo.RecordBriefContent rbc on sr.SubRecordID = rbc.RecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0
		where sr.RecordID = @LocRecordID and (sr.IsDeleted is null or sr.IsDeleted = 0) and (sr.Irrelevant is null or sr.Irrelevant = 0)) Reviewed,
	(select Count(distinct sr.SubRecordID) from ContentCrawler.dbo.SubRecord sr 
		inner join ContentCrawler.dbo.RecordBriefContent rbc on sr.SubRecordID = rbc.RecordID and rbc.IsSubRecord = 1 and rbc.IsDeleted = 0
		where sr.RecordID = @LocRecordID and sr.PublishedDate between @LocStartDate and @LocEndDate and (sr.IsDeleted is null or sr.IsDeleted = 0) and (sr.Irrelevant is null or sr.Irrelevant = 0)) ReviewedInRange,
	(select count(sr2.SubRecordID) from ContentCrawler.dbo.SubRecord sr2 where sr2.RecordID = @LocRecordID and sr2.PublishedDate between @LocStartDate and @LocEndDate and (sr2.IsDeleted is null or sr2.IsDeleted = 0) and (sr2.Irrelevant is null or sr2.Irrelevant = 0) ) TotalInRange,
	(select count(sr1.SubRecordID) from ContentCrawler.dbo.SubRecord sr1 where sr1.RecordID = @LocRecordID and (sr1.IsDeleted is null or sr1.IsDeleted = 0) and (sr1.Irrelevant is null or sr1.Irrelevant = 0) ) Total	
END
GO
