
if OBJECT_ID ( 'GetAPIRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetAPIRecords
GO
/*
* Description: get latest records for boomerang api
* Params
	@KeywordID: 
	@SiteIDs: a string of site id, delimited by comma
	@TagIDs:
	@LabelIDs:
	@Emotion:
	@Filter: isfollowed
    @StartDate:
    @EndDate:
    @Sorting:
    @FromRecord int,
    @ToRecord int
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
8/14/2011	|	Vu Do	|	Add Owner column
-------------------------------------------------------------
* Sample:
EXEC GetAPIRecords 
	@KeywordID = 19,
	@SiteIDs = null,
	@TagIDs = null,
	@LabelIDs = null,
	@Emotion = null,	
	@Filter = null,	
	@StartDate = '4/1/2012',
	@EndDate = null,	
	@Sorting = null,
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE [dbo].[GetAPIRecords]
	@KeywordID int,
	@SiteIDs varchar(512),
	@TagIDs varchar(1024),
	@LabelIDs varchar(512),
	@Emotion varchar(32),	
	@Filter varchar(128),			
    @StartDate datetime,
    @EndDate datetime,    
    @Sorting varchar(128),
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
	DECLARE @Pos int;
	-- create temp site id
	DECLARE @TempSite table
	(
		SiteID int,
		SiteGUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, SiteGUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @SiteIDs = RIGHT(@SiteIDs, LEN(@SiteIDs) - @Pos)
			SET @Pos = CHARINDEX('','', @SiteIDs, 1)

		END
	END;
	-- create temp tag table	
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
	-- create temp label table	
	DECLARE @TempLabel table
	(
		LabelID int,
		LabelGUID uniqueidentifier
	)
	DECLARE @LabelID varchar(10)

	SET @LabelIDs = LTRIM(RTRIM(@LabelIDs))+ '',''
	SET @Pos = CHARINDEX('','', @LabelIDs, 1)

	IF REPLACE(@LabelIDs, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @LabelID = LTRIM(RTRIM(LEFT(@LabelIDs, @Pos - 1)))
			IF @LabelID <> ''''
			BEGIN
				INSERT INTO @TempLabel(LabelID, LabelGUID) select LabelID, guid from ContentAggregator.dbo.Label where LabelID = CAST(@LabelID AS int)
			END
			SET @LabelIDs = RIGHT(@LabelIDs, LEN(@LabelIDs) - @Pos)
			SET @Pos = CHARINDEX('','', @LabelIDs, 1)

		END
	END;	
		
	'
	
	SET @SQLString = @SQLString + ' with records as(
			select ROW_NUMBER() OVER(ORDER BY r.PublishedDate DESC) AS ''RowNumber'', r.RecordID, r.RecordGUID, r.Title, r.Content, r.Author, r.URL, s.URL as ''SiteURL'', r.PublishedDate, r.IsFollowed, fre.Score,
				(CASE WHEN fre.Acceptance = 1 THEN ''Acceptance'' ELSE '''' END) 
				+ (CASE WHEN fre.Fear = 1 THEN '';Fear'' ELSE '''' END) 
				+ (CASE WHEN fre.Supprise = 1 THEN '';Supprise'' ELSE '''' END)
				+ (CASE WHEN fre.Sadness = 1 THEN '';Sadness'' ELSE '''' END)
				+ (CASE WHEN fre.Disgust = 1 THEN '';Disgust'' ELSE '''' END)
				+ (CASE WHEN fre.Anger = 1 THEN '';Anger'' ELSE '''' END)
				+ (CASE WHEN fre.Anticipation = 1 THEN '';Anticipation'' ELSE '''' END)
				+ (CASE WHEN fre.Joy = 1 THEN '';Joy'' ELSE '''' END) Emotion
			from ContentCrawler.dbo.Record r '									
	
	IF @Emotion is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordEmotion fre on r.RecordID = fre.RecordID and fre.' + @Emotion + ' = 1 '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordEmotion fre on r.RecordID = fre.RecordID 
		and (r.IsFollowed = 1 or fre.Acceptance = 1 or fre.Fear = 1 or fre.Supprise = 1 or fre.Sadness = 1 or fre.Disgust = 1 or fre.Anger = 1 or fre.Anticipation = 1 or fre.Joy = 1
		or exists (select * from ContentCrawler.dbo.FactRecordTag frt where frt.RecordID = r.RecordID))'
	END
	SET @SQLString = @SQLString + '
		inner join ContentAggregator.dbo.Site s on r.SiteGUID = s.GUID
		'
	IF @SiteIDs is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join @TempSite ts on r.SiteGUID = ts.SiteGUID
		'
	END
	IF @TagIDs is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordTag frt on r.RecordID = frt.RecordID 
		inner join @TempTag tt on frt.TagGUID = tt.TagGUID
		'
	END
	IF @LabelIDs is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordLabel frl on r.RecordID = frt.RecordID and frl.LabelGUID in (
			select t.GUID from ContentAggregator.dbo.Label l			
			inner join @TempLabel tl on l.LabelID = tl.LabelID )
		'
	END
	--where clause
	SET @SQLString = @SQLString + '
		where (r.IsDeleted = 0 or r.IsDeleted is null) and r.KeywordGUID = @KeywordGUID '
	IF @StartDate is not null
	BEGIN
		SET @SQLString = @SQLString + ' and r.PublishedDate >= @StartDate'
	END
	IF @EndDate is not null
	BEGIN
		SET @SQLString = @SQLString + ' and r.PublishedDate <= @EndDate'
	END
	
	IF @Filter = 'Followed'
	BEGIN
		SET @SQLString = @SQLString + ' and r.IsFollowed = 1'
	END
	ELSE IF @Filter = 'Unfollowed'
	BEGIN
		SET @SQLString = @SQLString + ' and ( r.IsFollowed is null or r.IsFollowed = 0)'
	END
	
	SET @SQLString = @SQLString + '	
	)		
	select RecordID, RecordGUID, Title, Content, Author, URL, ISNULL(SiteURL,'''') SiteURL, PublishedDate, ISNULL(IsFollowed, 0) IsFollowed, Score, Emotion, (select COUNT(*) from records) as ''TotalRecord'', (select COUNT(1) from ContentCrawler.dbo.SubRecord sr where records.RecordID = sr.RecordID ) SubRecords
	from records
	where RowNumber > @FromRecord and RowNumber <= @ToRecord';	
	
	print @Sqlstring
	SET @ParmDefinition = '
				@KeywordID int,
				@SiteIDs varchar(512),
				@TagIDs varchar(1024),
				@LabelIDs varchar(512),
				@Emotion varchar(32),							
				@StartDate datetime,
				@EndDate datetime,    
				@Sorting varchar(128),
				@FromRecord int,
				@ToRecord int';

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@SiteIDs,
						@TagIDs,
						@LabelIDs,
						@Emotion,						
						@StartDate,
						@EndDate,
						@Sorting,
						@FromRecord,
						@ToRecord;			
END
GO
