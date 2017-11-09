
if OBJECT_ID ( 'GetEmotionsReport', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionsReport
GO
/*
* Description: 
* History
-------------------------------------------------------------
2/1/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionsReport 
	@KeywordID = 27,
	@TagIDs = null,
    @LabelIDs = null,
    @SiteIDs = '67',   
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2012'
*/
CREATE PROCEDURE GetEmotionsReport
    @KeywordID int,
    @TagIDs varchar(512),        
    @LabelIDs varchar(512),
    @SiteIDs varchar(512),        
    @StartDate datetime,
    @EndDate date
AS
BEGIN	
	SET NOCOUNT ON
	
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	set @SQLString = '
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = Convert(date, @StartDate))
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = convert(date,@EndDate))
	
	DECLARE @Pos int;
	-- create temp site table	
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
	
	
	SET @SQLString = @SQLString + ' 
	select	ISNULL(SUM(CASE WHEN fre.Acceptance = 1 THEN 1 ELSE 0 END), 0) Acceptance, 
			ISNULL(SUM(CASE WHEN fre.Fear = 1 THEN 1 ELSE 0 END), 0) Fear,
			ISNULL(SUM(CASE WHEN fre.Supprise = 1 THEN 1 ELSE 0 END), 0) Supprise,
			ISNULL(SUM(CASE WHEN fre.Sadness = 1 THEN 1 ELSE 0 END), 0) Sadness,
			ISNULL(SUM(CASE WHEN fre.Disgust = 1 THEN 1 ELSE 0 END), 0) Disgust,
			ISNULL(SUM(CASE WHEN fre.Anger = 1 THEN 1 ELSE 0 END), 0) Anger,
			ISNULL(SUM(CASE WHEN fre.Anticipation = 1 THEN 1 ELSE 0 END), 0) Anticipation,
			ISNULL(SUM(CASE WHEN fre.Joy = 1 THEN 1 ELSE 0 END), 0) Joy, 
			ISNULL(SUM(CASE WHEN fre.Acceptance = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AcceptanceImpressionRate,
			ISNULL(SUM(CASE WHEN fre.Fear = 1 THEN fre.ImpressionRate ELSE 0 END), 0) FearImpressionRate,
			ISNULL(SUM(CASE WHEN fre.Supprise = 1 THEN fre.ImpressionRate ELSE 0 END), 0) SuppriseImpressionRate,
			ISNULL(SUM(CASE WHEN fre.Sadness = 1 THEN fre.ImpressionRate ELSE 0 END), 0) SadnessImpressionRate,
			ISNULL(SUM(CASE WHEN fre.Disgust = 1 THEN fre.ImpressionRate ELSE 0 END), 0) DisgustImpressionRate,
			ISNULL(SUM(CASE WHEN fre.Anger = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AngerImpressionRate,
			ISNULL(SUM(CASE WHEN fre.Anticipation = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AnticipationImpressionRate,
			ISNULL(SUM(CASE WHEN fre.Joy = 1 THEN fre.ImpressionRate ELSE 0 END), 0) JoyImpressionRate
	from ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK)
	inner join ContentCrawler.dbo.Record r WITH(NOLOCK) on fre.RecordID = r.RecordID and r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate '
	
	IF @SiteIDs is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join @TempSite ts on r.SiteGUID = ts.SiteGUID
		'
	END
	IF @TagIDs is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on r.RecordID = frt.RecordID 
		inner join @TempTag tt on frt.TagGUID = tt.TagGUID
		'
	END
	IF @LabelIDs is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordLabel frl WITH(NOLOCK) on r.RecordID = frt.RecordID and frl.LabelGUID in (
			select t.GUID from ContentAggregator.dbo.Label l			
			inner join @TempLabel tl on l.LabelID = tl.LabelID )
		'
	END
	
	SET @ParmDefinition = '
			@KeywordID int,
			@TagIDs varchar(512),        
			@LabelIDs varchar(512),
			@SiteIDs varchar(512),        
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@KeywordID,
							@TagIDs,
							@LabelIDs,
							@SiteIDs,
							@StartDate ,
							@EndDate ;	
		
END
GO

if OBJECT_ID ( 'GetEmotionLatestRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionLatestRecords
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
EXEC [GetEmotionLatestRecords] 
	@KeywordID = 27,
	@RecordID = 1,
	@StartDate = '3/23/2012',
	@EndDate = '3/30/2012'
*/
CREATE PROCEDURE [dbo].[GetEmotionLatestRecords]
	@KeywordID int,
	@RecordID int,
	@StartDate datetime,
	@EndDate datetime
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
			select r.RecordID, r.Title, r.Content, r.Author, r.URL, s.URL as ''SiteURL'', r.PublishedDate, r.IsFollowed, fre.Score, 
				(CASE WHEN fre.Acceptance = 1 THEN ''Acceptance'' ELSE '''' END) 
				+ (CASE WHEN fre.Fear = 1 THEN '';Fear'' ELSE '''' END) 
				+ (CASE WHEN fre.Supprise = 1 THEN '';Supprise'' ELSE '''' END)
				+ (CASE WHEN fre.Sadness = 1 THEN '';Sadness'' ELSE '''' END)
				+ (CASE WHEN fre.Disgust = 1 THEN '';Disgust'' ELSE '''' END)
				+ (CASE WHEN fre.Anger = 1 THEN '';Anger'' ELSE '''' END)
				+ (CASE WHEN fre.Anticipation = 1 THEN '';Anticipation'' ELSE '''' END)
				+ (CASE WHEN fre.Joy = 1 THEN '';Joy'' ELSE '''' END) Emotion,
				0 as TotalRecord,
				(select COUNT(1) from ContentCrawler.dbo.SubRecord sr where r.RecordID = sr.RecordID ) SubRecords
			from ContentCrawler.dbo.Record r
			inner join ContentCrawler.dbo.FactRecordEmotion fre on r.RecordID = fre.RecordID and (fre.Acceptance = 1 or fre.Fear = 1 or fre.Supprise = 1 or fre.Sadness = 1 or fre.Disgust = 1 or fre.Anger = 1 or fre.Anticipation = 1 or fre.Joy = 1)
			inner join ContentAggregator.dbo.Site s on r.SiteGUID = s.GUID
			where r.RecordID > @RecordID and (r.IsDeleted is null or r.IsDeleted = 0) and r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate'
	print @Sqlstring
	SET @ParmDefinition = '
				@KeywordID int,
				@RecordID int,
				@StartDate datetime,
				@EndDate datetime';

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@RecordID,
						@StartDate,
						@EndDate;			
END
GO

if OBJECT_ID ( 'GetEmotionRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionRecords
GO
/*
* Description: get latest records for emotion boomerang
* Params
	@KeywordID: 
	@SiteIDs: a string of site id, delimited by comma
	@TagIDs:
	@LabelIDs:
	@Emotion:
	@Filter: isfollowed
    @StartDate:
    @EndDate:
    @Sorting: PublishedDate, Comment, Score
    @FromRecord int,
    @ToRecord int
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
8/14/2011	|	Vu Do	|	Add Owner column
-------------------------------------------------------------
* Sample:
EXEC GetEmotionRecords 
	@KeywordID = 27,
	@SiteIDs = null,
	@TagIDs = null,
	@LabelIDs = null,
	@Emotion = null,	
	@Filter = null,	
	@StartDate = '4/11/2011',
	@EndDate = '11/20/2012',	
	@Sorting = 'Score',
	@SortOrder = 'DESC',
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE [dbo].[GetEmotionRecords]
	@KeywordID int,
	@SiteIDs varchar(512),
	@TagIDs varchar(1024),
	@LabelIDs varchar(512),
	@Emotion varchar(32),	
	@Filter varchar(128),			
    @StartDate datetime,
    @EndDate datetime,    
    @Sorting varchar(128),
	@SortOrder varchar(5),
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

	declare @SortingString nvarchar(256)
	IF(@Sorting = 'Score')
	BEGIN
		set @SortingString = 'fre.Score ' + @SortOrder
	END
	ELSE IF (@Sorting = 'Comment')
	BEGIN
		SET @SortingString = 'COUNT(sr.SubRecordID) ' + @SortOrder
	END
	ELSE
	BEGIN
		set @SortingString = 'r.PublishedDate ' + @SortOrder
	END

	SET @SQLString = @SQLString + ' with records as(
			select ROW_NUMBER() OVER(ORDER BY ' + @SortingString + ') AS ''RowNumber'', r.RecordID, r.Title, r.Content, r.Author, r.URL, s.URL as ''SiteURL'', r.PublishedDate, r.IsFollowed
				
			from ContentCrawler.dbo.Record r WITH(NOLOCK) '									
	IF @Sorting = 'Comment'
	BEGIN
		SET @SQLString = @SQLString + '
		left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on r.RecordID = sr.RecordID
		'
	END

	IF @Emotion is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on r.RecordID = fre.RecordID and fre.' + @Emotion + ' = 1 '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on r.RecordID = fre.RecordID and 
		(r.IsFollowed = 1 or fre.Acceptance = 1 or fre.Fear = 1 or fre.Supprise = 1 or fre.Sadness = 1 or fre.Disgust = 1 or fre.Anger = 1 or fre.Anticipation = 1 or fre.Joy = 1
		or exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = r.RecordID))'
	END
	SET @SQLString = @SQLString + '
		inner join ContentAggregator.dbo.Site s WITH(NOLOCK) on r.SiteGUID = s.GUID
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
		inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on r.RecordID = frt.RecordID 
		inner join @TempTag tt on frt.TagGUID = tt.TagGUID
		'
	END
	IF @LabelIDs is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordLabel frl WITH(NOLOCK) on r.RecordID = frt.RecordID and frl.LabelGUID in (
			select t.GUID from ContentAggregator.dbo.Label l WITH(NOLOCK)
			inner join @TempLabel tl on l.LabelID = tl.LabelID )
		'
	END
	--where clause
	SET @SQLString = @SQLString + '
		where (r.IsDeleted = 0 or r.IsDeleted is null) and r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate'
	IF @Filter = 'Followed'
	BEGIN
		SET @SQLString = @SQLString + ' and r.IsFollowed = 1'
	END
	ELSE IF @Filter = 'Unfollowed'
	BEGIN
		SET @SQLString = @SQLString + ' and ( r.IsFollowed is null or r.IsFollowed = 0)'
	END
	IF @Sorting = 'Comment'
	BEGIN
		SET @SQLString = @SQLString + '
		group by r.RecordID, r.Title, r.Content, r.Author, r.URL, s.URL, r.PublishedDate, r.IsFollowed
		'
	END
	SET @SQLString = @SQLString + '	
	)		
	select records.RecordID, records.Title, records.URL, ISNULL(records.SiteURL,'''') SiteURL, records.PublishedDate, ISNULL(records.IsFollowed, 0) IsFollowed, fre.Score
	,(CASE WHEN fre.Acceptance = 1 THEN ''Acceptance'' ELSE '''' END) 
		+ (CASE WHEN fre.Fear = 1 THEN '';Fear'' ELSE '''' END) 
		+ (CASE WHEN fre.Supprise = 1 THEN '';Supprise'' ELSE '''' END)
		+ (CASE WHEN fre.Sadness = 1 THEN '';Sadness'' ELSE '''' END)
		+ (CASE WHEN fre.Disgust = 1 THEN '';Disgust'' ELSE '''' END)
		+ (CASE WHEN fre.Anger = 1 THEN '';Anger'' ELSE '''' END)
		+ (CASE WHEN fre.Anticipation = 1 THEN '';Anticipation'' ELSE '''' END)
		+ (CASE WHEN fre.Joy = 1 THEN '';Joy'' ELSE '''' END) Emotion
	,(select COUNT(*) from records) as ''TotalRecord'', (select COUNT(1) from ContentCrawler.dbo.SubRecord sr where records.RecordID = sr.RecordID ) SubRecords
	from records
	inner join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on records.RecordID = fre.RecordID
	where RowNumber > @FromRecord and RowNumber <= @ToRecord
	order by RowNumber';	
	
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

if OBJECT_ID ( 'GetEmotionLiveMonitoringRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionLiveMonitoringRecords
GO
/*
* Description: get latest records for emotion boomerang
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
EXEC GetEmotionRecords 
	@KeywordID = 27,
	@SiteIDs = null,
	@TagIDs = null,
	@LabelIDs = null,
	@Emotion = null,	
	@Filter = null,	
	@StartDate = '4/11/2011',
	@EndDate = '11/20/2012',	
	@Sorting = null,
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE [dbo].[GetEmotionLiveMonitoringRecords]
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
			select ROW_NUMBER() OVER(ORDER BY r.PublishedDate DESC) AS ''RowNumber'', r.RecordID, r.Title, r.Content, r.Author, r.URL, s.URL as ''SiteURL'', r.PublishedDate, r.IsFollowed, fre.Score,
				(CASE WHEN fre.Acceptance = 1 THEN ''Acceptance'' ELSE '''' END) 
				+ (CASE WHEN fre.Fear = 1 THEN '';Fear'' ELSE '''' END) 
				+ (CASE WHEN fre.Supprise = 1 THEN '';Supprise'' ELSE '''' END)
				+ (CASE WHEN fre.Sadness = 1 THEN '';Sadness'' ELSE '''' END)
				+ (CASE WHEN fre.Disgust = 1 THEN '';Disgust'' ELSE '''' END)
				+ (CASE WHEN fre.Anger = 1 THEN '';Anger'' ELSE '''' END)
				+ (CASE WHEN fre.Anticipation = 1 THEN '';Anticipation'' ELSE '''' END)
				+ (CASE WHEN fre.Joy = 1 THEN '';Joy'' ELSE '''' END) Emotion
			from ContentCrawler.dbo.Record r WITH(NOLOCK) '									
	
	IF @Emotion is not null
	BEGIN
		SET @SQLString = @SQLString + '
		left join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on r.RecordID = fre.RecordID and fre.' + @Emotion + ' = 1 '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		left join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on r.RecordID = fre.RecordID '
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
		inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on r.RecordID = frt.RecordID 
		inner join @TempTag tt on frt.TagGUID = tt.TagGUID
		'
	END
	IF @LabelIDs is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecordLabel frl WITH(NOLOCK) on r.RecordID = frt.RecordID and frl.LabelGUID in (
			select t.GUID from ContentAggregator.dbo.Label l WITH(NOLOCK)			
			inner join @TempLabel tl on l.LabelID = tl.LabelID )
		'
	END
	--where clause
	SET @SQLString = @SQLString + '
		where (r.IsDeleted = 0 or r.IsDeleted is null) and r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate'
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
	select RecordID, Title, URL, ISNULL(SiteURL,'''') SiteURL, PublishedDate, ISNULL(IsFollowed, 0) IsFollowed, Score, Emotion, (select COUNT(*) from records) as ''TotalRecord'', (select COUNT(1) from ContentCrawler.dbo.SubRecord sr where records.RecordID = sr.RecordID ) SubRecords
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


if OBJECT_ID ( 'GetEmotionRecordContent', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionRecordContent
GO
/*
* Description: get a record content
* Params
	
* History
-------------------------------------------------------------
4/12/2011	|	Vu Do	|	Add
10/09/2011	|	Vu Do	|	Add IsFollowed column
-------------------------------------------------------------
* Sample:
EXEC GetEmotionRecordContent 
	@RecordID = 92357,
	@Words = null
*/
CREATE PROCEDURE GetEmotionRecordContent
	@RecordID int  ,	
	@Words nvarchar(512)
AS
BEGIN			
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	DECLARE @SQLStringTemp nvarchar(1024);
	
	--full text search keyword
	SET @SQLStringTemp = ''
	IF @Words is not null
	BEGIN
		SET @SQLStringTemp = 'and contains(sr.Content, ''' + @Words + ''')'
	END
		
	SET @SQLString = '
	select rd.URL, rd.Content, rd.Author, ISNULL(s.URL,'''') SiteURL, rd.PublishedDate, rd.IsFollowed, rd.Irrelevant,
		(SELECT COUNT(*) from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) where sr.RecordID = @RecordID and (sr.IsDeleted is null or sr.IsDeleted = 0) ' + @SQLStringTemp + ') NumOfSubRecords,
		ISNULL((select distinct word + '';'' as [data()] from ContentAggregator.dbo.Tag t WITH(NOLOCK) inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on (frt.RecordID = rd.RecordID and frt.IsSubRecord = 0 and frt.IsDeleted = 0) and frt.TagGUID = t.GUID  for xml path('''')),'''') as Tags
	from ContentCrawler.dbo.Record rd WITH(NOLOCK)
	left join Site s on s.GUID = rd.SiteGUID
	where rd.RecordID = @RecordID'

	SET @ParmDefinition = '
				@RecordID int';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID;		
END
GO

if OBJECT_ID ( 'GetEmotionSubRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionSubRecords
GO
/*
* Description: Get sub records from for backend, with emotion
* History
-------------------------------------------------------------
2/1/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionSubRecords
	@RecordID = 92357,	
	@Words = null,
	@StartDate = null,
	@EndDate = null,	
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE GetEmotionSubRecords
	@RecordID int,	
	@Words nvarchar(512),
	@StartDate datetime,
    @EndDate datetime,      
    @FromRecord int,
    @ToRecord int
AS
BEGIN					
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	DECLARE @SQLStringTemp nvarchar(1024);
	
	--full text search keyword
	SET @SQLStringTemp = ''
	IF @StartDate is not null
	BEGIN
		SET @SQLStringTemp = @SQLStringTemp + ' and sr.PublishedDate >= @StartDate'
	END
	IF @EndDate is not null
	BEGIN
		SET @SQLStringTemp = @SQLStringTemp + ' and sr.PublishedDate <= @EndDate'
	END
	IF @Words is not null
	BEGIN
		SET @SQLStringTemp = @SQLStringTemp + ' and contains(sr.Content, ''' + @Words + ''')'
	END
	
	SET @SQLString = '
			with subrecords as(
				select ROW_NUMBER() OVER(ORDER BY sr.PublishedDate ASC) AS ''RowNumber'', sr.SubRecordID, sr.SubRecordGUID, sr.Content, sr.Author, sr.PublishedDate, sr.URL, sr.Irrelevant
				,(CASE WHEN fre.Acceptance = 1 THEN ''Acceptance'' ELSE '''' END) 
				+ (CASE WHEN fre.Fear = 1 THEN '';Fear'' ELSE '''' END) 
				+ (CASE WHEN fre.Supprise = 1 THEN '';Supprise'' ELSE '''' END)
				+ (CASE WHEN fre.Sadness = 1 THEN '';Sadness'' ELSE '''' END)
				+ (CASE WHEN fre.Disgust = 1 THEN '';Disgust'' ELSE '''' END)
				+ (CASE WHEN fre.Anger = 1 THEN '';Anger'' ELSE '''' END)
				+ (CASE WHEN fre.Anticipation = 1 THEN '';Anticipation'' ELSE '''' END)
				+ (CASE WHEN fre.Joy = 1 THEN '';Joy'' ELSE '''' END) Emotion				
				from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
				left join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on sr.SubRecordID = fre.RecordID and fre.IsSubRecord = 1 and fre.IsDeleted = 0 '
		
	SET @SQLString = @SQLString + ' 
				where sr.RecordID = @RecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) ' + @SQLStringTemp
	SET @SQLString = @SQLString + ')
			select SubRecordID, SubRecordGUID, Content, Author, PublishedDate, URL, Irrelevant, Emotion, (select COUNT(*) from subrecords) as ''TotalRecord'', 
					ISNULL((select distinct word + '';'' as [data()] from ContentAggregator.dbo.Tag t WITH(NOLOCK) inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on (frt.RecordID = subrecords.SubRecordID and frt.IsSubRecord = 1 and frt.IsDeleted = 0) and frt.TagGUID = t.GUID  for xml path('''')),'''') as Tags
			from subrecords
			where RowNumber > @FromRecord and RowNumber <= @ToRecord'	
	
	print @sqlstring
	SET @ParmDefinition = '
				@RecordID int,
				@StartDate datetime,
				@EndDate datetime,				        
				@FromRecord int,
				@ToRecord int';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID,
					  	@StartDate,
					  	@EndDate,
					  	@FromRecord,
					  	@ToRecord;
					  					  		
END
GO

if OBJECT_ID ( 'GetRecordLabels', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordLabels
GO
/*
* Description: get labels of record. it is similar to tag
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetRecordLabels 
	@RecordID = 1
*/
CREATE PROCEDURE GetRecordLabels
	@RecordID int	
AS
BEGIN		
	select l.LabelID, l.Word, l.WordWithoutAccent
	from Label l
	inner join ContentCrawler.dbo.FactRecordLabel frl WITH(NOLOCK) on l.GUID = frl.LabelGUID
	where frl.RecordID = @RecordID
END
GO

if OBJECT_ID ( 'GetEmotionPost', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionPost
GO
/*
* Description: count the number of posts that have emotion
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionPost 
	@KeywordID = 19,
	@StartDate = '2/1/2011',
	@EndDate = '2/20/2012'
*/
CREATE PROCEDURE GetEmotionPost
	@KeywordID int,
	@StartDate datetime,
	@EndDate datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	declare @StartTimeID int
	declare @EndTimeID int
	set @StartTimeID = (select DimTimeID from ContentAggregator.dbo.DimTime where [DATE] = CONVERT(date,@StartDate))
	set @EndTimeID = (select DimTimeID from ContentAggregator.dbo.DimTime where [DATE] = CONVERT(date, @EndDate))
	
	select	leftside.Date, 
			ISNULL(rightside.Acceptance, 0) Acceptance,
			ISNULL(rightside.Fear, 0) Fear,
			ISNULL(rightside.Supprise, 0) Supprise,
			ISNULL(rightside.Sadness, 0) Sadness,
			ISNULL(rightside.Disgust, 0) Disgust,
			ISNULL(rightside.Anger, 0) Anger,
			ISNULL(rightside.Anticipation, 0) Anticipation,
			ISNULL(rightside.Joy, 0) Joy
	from
		(select dt.Date
		from ContentAggregator.dbo.DimTime dt WITH(NOLOCK)
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
		) leftside
	left join (select CONVERT(date, r.PublishedDate) PublishedDate, 
			ISNULL(SUM(CASE WHEN fre.Acceptance = 1 THEN 1 ELSE 0 END), 0) Acceptance, 
			ISNULL(SUM(CASE WHEN fre.Fear = 1 THEN 1 ELSE 0 END), 0) Fear,
			ISNULL(SUM(CASE WHEN fre.Supprise = 1 THEN 1 ELSE 0 END), 0) Supprise,
			ISNULL(SUM(CASE WHEN fre.Sadness = 1 THEN 1 ELSE 0 END), 0) Sadness,
			ISNULL(SUM(CASE WHEN fre.Disgust = 1 THEN 1 ELSE 0 END), 0) Disgust,
			ISNULL(SUM(CASE WHEN fre.Anger = 1 THEN 1 ELSE 0 END), 0) Anger,
			ISNULL(SUM(CASE WHEN fre.Anticipation = 1 THEN 1 ELSE 0 END), 0) Anticipation,
			ISNULL(SUM(CASE WHEN fre.Joy = 1 THEN 1 ELSE 0 END), 0) Joy
		from ContentCrawler.dbo.Record r WITH(NOLOCK)
		inner join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on r.RecordID = fre.RecordID	
		where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate
		group by CONVERT(date, r.PublishedDate)
	) rightside on leftside.Date = rightside.PublishedDate
	order by leftside.Date
END
GO


if OBJECT_ID ( 'GetEmotionImpressionRate', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionImpressionRate
GO
/*
* Description: get sum of impression rate by emotion
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionImpressionRate 
	@KeywordID = 27,
	@StartDate = '2/1/2012',
	@EndDate = '2/20/2012'
*/
CREATE PROCEDURE GetEmotionImpressionRate
	@KeywordID int,
	@StartDate datetime,
	@EndDate datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	declare @StartTimeID int
	declare @EndTimeID int
	set @StartTimeID = (select DimTimeID from ContentAggregator.dbo.DimTime where [DATE] = CONVERT(date	, @StartDate))
	set @EndTimeID = (select DimTimeID from ContentAggregator.dbo.DimTime where [DATE] = CONVERT(date, @EndDate))
	
	select	leftside.Date,
			ISNULL(rightside.Acceptance, 0) Acceptance,
			ISNULL(rightside.Fear, 0) Fear,
			ISNULL(rightside.Supprise, 0) Supprise,
			ISNULL(rightside.Sadness, 0) Sadness,
			ISNULL(rightside.Disgust, 0) Disgust,
			ISNULL(rightside.Anger, 0) Anger,
			ISNULL(rightside.Anticipation, 0) Anticipation,
			ISNULL(rightside.Joy, 0) Joy
	from 
		(select dt.Date
		from ContentAggregator.dbo.DimTime dt WITH(NOLOCK)
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
		) leftside
	left join (select CONVERT(date, r.PublishedDate) PublishedDate, 
			SUM(ISNULL(fre.Acceptance,0) * ISNULL(fre.Score,0)) Acceptance,
			SUM(ISNULL(fre.Fear,0) * ISNULL(fre.Score,0)) Fear, 
			SUM(ISNULL(fre.Supprise,0) * ISNULL(fre.Score,0)) Supprise,
			SUM(ISNULL(fre.Sadness,0) * ISNULL(fre.Score,0)) Sadness,
			SUM(ISNULL(fre.Disgust,0) * ISNULL(fre.Score,0)) Disgust,		
			SUM(ISNULL(fre.Anger,0) * ISNULL(fre.Score,0)) Anger,
			SUM(ISNULL(fre.Anticipation,0) * ISNULL(fre.Score,0)) Anticipation,
			SUM(ISNULL(fre.Joy,0) * ISNULL(fre.Score,0)) Joy
		from ContentCrawler.dbo.Record r WITH(NOLOCK)
		inner join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on r.RecordID = fre.RecordID
		
		where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate
		group by CONVERT(date, r.PublishedDate)
	) rightside on leftside.Date = rightside.PublishedDate
	order by leftside.Date
	
END
GO


if OBJECT_ID ( 'GetEmotionSiteType', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionSiteType
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionSiteType 
	@KeywordID = 27,
	@StartDate = '2/1/2012',
	@EndDate = '2/20/2012'
*/
CREATE PROCEDURE GetEmotionSiteType
	@KeywordID int,
	@StartDate datetime,
	@EndDate datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	declare @StartTimeID int
	declare @EndTimeID int
	set @StartTimeID = (select DimTimeID from ContentAggregator.dbo.DimTime where [DATE] = CONVERT(date,@StartDate))
	set @EndTimeID = (select DimTimeID from ContentAggregator.dbo.DimTime where [DATE] = CONVERT(date,@EndDate))
	
	select	leftside.Date, leftside.Name,
			ISNULL(rightside.Acceptance, 0) Acceptance,
			ISNULL(rightside.Fear, 0) Fear,
			ISNULL(rightside.Supprise, 0) Supprise,
			ISNULL(rightside.Sadness, 0) Sadness,
			ISNULL(rightside.Disgust, 0) Disgust,
			ISNULL(rightside.Anger, 0) Anger,
			ISNULL(rightside.Anticipation, 0) Anticipation,
			ISNULL(rightside.Joy, 0) Joy,
			ISNULL(rightside.AcceptanceImpressionRate, 0) AcceptanceImpressionRate,
			ISNULL(rightside.FearImpressionRate, 0) FearImpressionRate,
			ISNULL(rightside.SuppriseImpressionRate, 0) SuppriseImpressionRate,
			ISNULL(rightside.SadnessImpressionRate, 0) SadnessImpressionRate,
			ISNULL(rightside.DisgustImpressionRate, 0) DisgustImpressionRate,
			ISNULL(rightside.AngerImpressionRate, 0) AngerImpressionRate,
			ISNULL(rightside.AnticipationImpressionRate, 0) AnticipationImpressionRate,
			ISNULL(rightside.JoyImpressionRate, 0) JoyImpressionRate
	from (select dt.Date, st.Name
			from ContentAggregator.dbo.DimTime dt WITH(NOLOCK), ContentAggregator.dbo.SiteType st
			where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
		) leftside
	left join (select	CONVERT(date, r.PublishedDate) PublishedDate, st.Name,
				ISNULL(SUM(CASE WHEN fre.Acceptance = 1 THEN 1 ELSE 0 END), 0) Acceptance, 
				ISNULL(SUM(CASE WHEN fre.Fear = 1 THEN 1 ELSE 0 END), 0) Fear,
				ISNULL(SUM(CASE WHEN fre.Supprise = 1 THEN 1 ELSE 0 END), 0) Supprise,
				ISNULL(SUM(CASE WHEN fre.Sadness = 1 THEN 1 ELSE 0 END), 0) Sadness,
				ISNULL(SUM(CASE WHEN fre.Disgust = 1 THEN 1 ELSE 0 END), 0) Disgust,
				ISNULL(SUM(CASE WHEN fre.Anger = 1 THEN 1 ELSE 0 END), 0) Anger,
				ISNULL(SUM(CASE WHEN fre.Anticipation = 1 THEN 1 ELSE 0 END), 0) Anticipation,
				ISNULL(SUM(CASE WHEN fre.Joy = 1 THEN 1 ELSE 0 END), 0) Joy, 
				ISNULL(SUM(CASE WHEN fre.Acceptance = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AcceptanceImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Fear = 1 THEN fre.ImpressionRate ELSE 0 END), 0) FearImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Supprise = 1 THEN fre.ImpressionRate ELSE 0 END), 0) SuppriseImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Sadness = 1 THEN fre.ImpressionRate ELSE 0 END), 0) SadnessImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Disgust = 1 THEN fre.ImpressionRate ELSE 0 END), 0) DisgustImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Anger = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AngerImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Anticipation = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AnticipationImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Joy = 1 THEN fre.ImpressionRate ELSE 0 END), 0) JoyImpressionRate
		from ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK)
		inner join ContentCrawler.dbo.Record r WITH(NOLOCK) on fre.RecordID = r.RecordID --and r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate
		inner join ContentAggregator.dbo.Site s WITH(NOLOCK) on r.SiteGUID = s.GUID
		inner join ContentAggregator.dbo.SiteType st on s.Type = st.SiteTypeID
		group by CONVERT(date, r.PublishedDate), st.Name
	) rightside on leftside.Date = rightside.PublishedDate and leftside.Name = rightside.Name
	order by leftside.Date
END
GO


if OBJECT_ID ( 'GetEmotionCategory', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionCategory
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionCategory 
	@KeywordID = 27,
	@StartDate = '1/1/2012',
	@EndDate = '3/1/2012'
*/
CREATE PROCEDURE GetEmotionCategory
	@KeywordID int,
	@StartDate datetime,
	@EndDate datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	declare @StartTimeID int
	declare @EndTimeID int
	set @StartTimeID = (select DimTimeID from ContentAggregator.dbo.DimTime where [DATE] = convert(date,@StartDate))
	set @EndTimeID = (select DimTimeID from ContentAggregator.dbo.DimTime where [DATE] = convert(date,@EndDate))
	
	declare @tempTag table
	(
		TagID int,
		Name nvarchar(256)		
	);
	
	insert into @tempTag
	select distinct t.TagID, t.Word from ContentAggregator.dbo.Tag t WITH(NOLOCK)
	inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on t.GUID = frt.TagGUID and frt.IsDeleted = 0
	inner join ContentCrawler.dbo.Record r WITH(NOLOCK) on frt.RecordID = r.RecordID and r.KeywordGUID = @KeywordGUID
	
	select	leftside.Date, leftside.Name,
			ISNULL(rightside.Acceptance, 0) Acceptance,
			ISNULL(rightside.Fear, 0) Fear,
			ISNULL(rightside.Supprise, 0) Supprise,
			ISNULL(rightside.Sadness, 0) Sadness,
			ISNULL(rightside.Disgust, 0) Disgust,
			ISNULL(rightside.Anger, 0) Anger,
			ISNULL(rightside.Anticipation, 0) Anticipation,
			ISNULL(rightside.Joy, 0) Joy,
			ISNULL(rightside.AcceptanceImpressionRate, 0) AcceptanceImpressionRate,
			ISNULL(rightside.FearImpressionRate, 0) FearImpressionRate,
			ISNULL(rightside.SuppriseImpressionRate, 0) SuppriseImpressionRate,
			ISNULL(rightside.SadnessImpressionRate, 0) SadnessImpressionRate,
			ISNULL(rightside.DisgustImpressionRate, 0) DisgustImpressionRate,
			ISNULL(rightside.AngerImpressionRate, 0) AngerImpressionRate,
			ISNULL(rightside.AnticipationImpressionRate, 0) AnticipationImpressionRate,
			ISNULL(rightside.JoyImpressionRate, 0) JoyImpressionRate
	from (select dt.Date, tt.Name
			from ContentAggregator.dbo.DimTime dt WITH(NOLOCK), @tempTag tt 
			where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
		) leftside
	left join (select	CONVERT(date, r.PublishedDate) PublishedDate, t.Word Name,
				ISNULL(SUM(CASE WHEN fre.Acceptance = 1 THEN 1 ELSE 0 END), 0) Acceptance, 
				ISNULL(SUM(CASE WHEN fre.Fear = 1 THEN 1 ELSE 0 END), 0) Fear,
				ISNULL(SUM(CASE WHEN fre.Supprise = 1 THEN 1 ELSE 0 END), 0) Supprise,
				ISNULL(SUM(CASE WHEN fre.Sadness = 1 THEN 1 ELSE 0 END), 0) Sadness,
				ISNULL(SUM(CASE WHEN fre.Disgust = 1 THEN 1 ELSE 0 END), 0) Disgust,
				ISNULL(SUM(CASE WHEN fre.Anger = 1 THEN 1 ELSE 0 END), 0) Anger,
				ISNULL(SUM(CASE WHEN fre.Anticipation = 1 THEN 1 ELSE 0 END), 0) Anticipation,
				ISNULL(SUM(CASE WHEN fre.Joy = 1 THEN 1 ELSE 0 END), 0) Joy, 
				ISNULL(SUM(CASE WHEN fre.Acceptance = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AcceptanceImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Fear = 1 THEN fre.ImpressionRate ELSE 0 END), 0) FearImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Supprise = 1 THEN fre.ImpressionRate ELSE 0 END), 0) SuppriseImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Sadness = 1 THEN fre.ImpressionRate ELSE 0 END), 0) SadnessImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Disgust = 1 THEN fre.ImpressionRate ELSE 0 END), 0) DisgustImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Anger = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AngerImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Anticipation = 1 THEN fre.ImpressionRate ELSE 0 END), 0) AnticipationImpressionRate,
				ISNULL(SUM(CASE WHEN fre.Joy = 1 THEN fre.ImpressionRate ELSE 0 END), 0) JoyImpressionRate
		from ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK)
		inner join ContentCrawler.dbo.Record r WITH(NOLOCK) on fre.RecordID = r.RecordID and r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate
		inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on r.RecordID = frt.RecordID and frt.IsDeleted = 0
		inner join ContentAggregator.dbo.Tag t WITH(NOLOCK) on frt.TagGUID = t.GUID						
		group by CONVERT(date, r.PublishedDate), t.Word
	) rightside on leftside.Date = rightside.PublishedDate and leftside.Name = rightside.Name
	order by leftside.Date, leftside.Name
END
GO

if OBJECT_ID ( 'GetEmotionTopSources', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionTopSources
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionTopSources 
	@KeywordID = 27,
	@Date = '1/1/2010'	
*/
CREATE PROCEDURE GetEmotionTopSources
	@KeywordID int,
	@Date datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	
	select top 10 s.Name,s.URLName, s.URL, COUNT(1) as NoOfPosts
	from ContentCrawler.dbo.Record r WITH(NOLOCK)
	inner join ContentAggregator.dbo.Site s WITH(NOLOCK) on s.GUID = r.SiteGUID	
	where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @Date and GETDATE() and (r.IsDeleted is null or r.IsDeleted = 0)
	group by s.Name, s.URLName, s.URL
	order by NoOfPosts desc		
END
GO


if OBJECT_ID ( 'GetEmotionTopTopics', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionTopTopics
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionTopTopics 
	@KeywordID = 18,
	@Date = '2012-03-21 23:29:55'	
*/
CREATE PROCEDURE GetEmotionTopTopics
	@KeywordID int,
	@Date datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
	
	select top 10 r.RecordID, r.Title, r.URL, r.PublishedDate, COUNT(sr.SubRecordID) as NoOfComments, COUNT(distinct sr.Author) NoOfAuthors
	from ContentCrawler.dbo.Record r WITH(NOLOCK)
	left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on r.RecordID = sr.RecordID	
	where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @Date and GETDATE() and (r.IsDeleted is null or r.IsDeleted = 0)
	group by r.RecordID, r.Title, r.URL, r.PublishedDate
	order by NoOfComments desc, PublishedDate desc		
END
GO

if OBJECT_ID ( 'GetEmotionBuzzTrend', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionBuzzTrend
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionBuzzTrend 
	@KeywordID = 21,
	@Date = '3/18/2012 21:00:00'	
*/
CREATE PROCEDURE GetEmotionBuzzTrend
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
		select [Hour], SUM(Buzz) Buzz
		from (select DATEPART(hour, r.PublishedDate) 'Hour', COUNT(1) as Buzz
			from ContentCrawler.dbo.Record r WITH(NOLOCK)				
			where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @Date and GETDATE() and (r.IsDeleted is null or r.IsDeleted = 0)
			group by DATEPART(Hour, r.PublishedDate)
			union
			select DATEPART(hour, sr.PublishedDate) 'Hour', COUNT(1) as Buzz
			from ContentCrawler.dbo.Record r WITH(NOLOCK)		
			inner join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on r.RecordID = sr.RecordID and (sr.IsDeleted is null or sr.IsDeleted = 0 ) and (r.IsDeleted is null or r.IsDeleted = 0)
			where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @Date and GETDATE()
			group by DATEPART(Hour, sr.PublishedDate)) t
		group by [Hour]
	) rightside on leftside.Hour = rightside.Hour
	
END
GO


if OBJECT_ID ( 'GetEmotionRelatedMentions', 'P' ) IS NOT NULL
	DROP PROCEDURE GetEmotionRelatedMentions
GO
/*
* Description: 
* History
-------------------------------------------------------------
1/31/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetEmotionRelatedMentions 
	@KeywordID = 43,
	@Date = '2012-03-22 03:29:55'	
*/
CREATE PROCEDURE GetEmotionRelatedMentions
	@KeywordID int,
	@Date datetime
AS
BEGIN		
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	)
		
	select COUNT(distinct r.RecordID) + COUNT(distinct sr.SubRecordID) as Buzz
	from ContentCrawler.dbo.Record r WITH(NOLOCK)
	left join ContentCrawler.dbo.SubRecord sr WITH(NOLOCK) on r.RecordID = sr.RecordID
	where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @Date and GETDATE() and (r.IsDeleted is null or r.IsDeleted = 0)
END
GO
