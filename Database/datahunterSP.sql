use DataHunter
GO

if OBJECT_ID ( 'GetRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecords
GO
/*
* Description: get records for data hunter page
* Params
	Filter: null, tagged, untagged
	Sort: PublishedDate, NoOfSubRecords
* History
-------------------------------------------------------------
9/5/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetRecords 
	@Keyword = null,
	@Site = null,
	@Channel = null,
	@Tag = null,
	@Filter = null,
	@Sort = 'NoOfSubRecords',
	@StartDate = '1/11/2011',
	@EndDate = '11/20/2011',
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE GetRecords
	@Keyword nvarchar(1024),
	@Site varchar(1024),
	@Channel varchar(1024),
	@Tag varchar(1024),
	@Sort varchar(128),
	@Filter varchar(128),
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
	DECLARE @Pos int
	-- create temp site id
	DECLARE @TempSite table
	(
		SiteID int,
		SiteGUID uniqueidentifier,
		URL varchar(1024)
	)
	DECLARE @SiteID varchar(10)

	SET @Site = LTRIM(RTRIM(@Site))+ '',''
	SET @Pos = CHARINDEX('','', @Site, 1)

	IF REPLACE(@Site, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @SiteID = LTRIM(RTRIM(LEFT(@Site, @Pos - 1)))
			IF @SiteID <> ''''
			BEGIN
				INSERT INTO @TempSite (SiteID, SiteGUID, URL) select SiteID, GUID, URL from [221.132.37.57].ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	-- create temp site id
	DECLARE @TempChannel table
	(
		ChannelID int,
		ChannelGUID uniqueidentifier		
	)
	DECLARE @ChannelID varchar(10)

	SET @Channel = LTRIM(RTRIM(@Channel))+ '',''
	SET @Pos = CHARINDEX('','', @Channel, 1)

	IF REPLACE(@Channel, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @ChannelID = LTRIM(RTRIM(LEFT(@Channel, @Pos - 1)))
			IF @ChannelID <> ''''
			BEGIN
				INSERT INTO @TempChannel (ChannelID, ChannelGUID) select ChannelID, GUID from [221.132.37.57].ContentAggregator.dbo.Channel where ChannelID = CAST(@ChannelID AS int)				
			END
			SET @Channel = RIGHT(@Channel, LEN(@Channel) - @Pos)
			SET @Pos = CHARINDEX('','', @Channel, 1)

		END
	END;
	-- create temp tag id
	DECLARE @TempTag table
	(
		TagID int,
		TagGUID uniqueidentifier
	)
	DECLARE @TagID varchar(10)

	SET @Tag = LTRIM(RTRIM(@Tag))+ '',''
	SET @Pos = CHARINDEX('','', @Tag, 1)

	IF REPLACE(@Tag, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @TagID = LTRIM(RTRIM(LEFT(@Tag, @Pos - 1)))
			IF @TagID <> ''''
			BEGIN				
				INSERT INTO @TempTag (TagID, TagGUID) select TagID, GUID from [221.132.37.57].ContentAggregator.dbo.Tag where TagID = CAST(@TagID AS int)
			END
			SET @Tag = RIGHT(@Tag, LEN(@Tag) - @Pos)
			SET @Pos = CHARINDEX('','', @Tag, 1)

		END
	END;	
		
	'
	IF @Sort = 'PublishedDate' OR @Sort is null
	BEGIN
		SET @SQLString = @SQLString + ' with records as(
				select ROW_NUMBER() OVER(ORDER BY rd.PublishedDate DESC) AS ''RowNumber'', rd.RecordID, rd.RecordGUID, rd.Title, rd.URL, s.URL as ''SiteURL'', Convert(date, rd.PublishedDate) as ''PublishedDate'', COUNT(frtcount.FactRecordTagID) NoOfTags
				from DataHunter.dbo.Record rd '		
		IF @Channel is NOT NULL
		BEGIN
			SET @SQLString = @SQLString + '
				inner join @TempChannel tc on tc.ChannelGUID = rd.ChannelGUID '
		END	
		IF @Tag is NOT NULL
		BEGIN
			SET @SQLString = @SQLString + '
				inner join (select distinct frtag.RecordID from DataHunter.dbo.FactRecordTag frtag inner join @TempTag tt on frtag.TagGUID = tt.TagGUID) frt on rd.RecordID = frt.RecordID '
		END;
			
		IF @Site is NOT NULL
		BEGIN
			SET @SQLString = @SQLString + '
				inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
		END
		ELSE
		BEGIN
				SET @SQLString = @SQLString + '
				left join [221.132.37.57].ContentAggregator.dbo.Site s on s.GUID = rd.SiteGUID '
		END;
		
			
				
		SET @SQLString = @SQLString + '
		       left join DataHunter.dbo.FactRecordTag frtcount on rd.RecordID = frtcount.RecordID and frtcount.IsDeleted = 0
		'		
		
		SET @SQLString = @SQLString + '
			where (rd.IsDeleted = 0 or rd.IsDeleted is null )	
						and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate '
		IF @Keyword is not null
		BEGIN
			SET @SQLString = @SQLString + ' and (contains(rd.Title, @Keyword) or contains(rd.Content, @Keyword) or rd.RecordID in (select distinct sr.RecordID from SubRecord sr where contains(sr.Content, @Keyword)))'	
		END
	    SET @SQLString = @SQLString +  '
	        group by rd.RecordID, rd.RecordGUID, rd.Title, rd.URL, s.URL, rd.PublishedDate
	    '
	END
	ELSE IF @Sort = 'NoOfSubRecords'		
	BEGIN
		SET @SQLString = @SQLString + ' with records as(
			select ROW_NUMBER() OVER(ORDER BY leftside.NoOfSubRecords DESC) AS RowNumber, leftside.RecordID, leftside.RecordGUID, leftside.Title, leftside.URL, leftside.SiteURL, leftside.PublishedDate, leftside.NoOfSubRecords, COUNT(frtcount.FactRecordTagID) NoOfTags
			from
                (select rd.RecordID, rd.RecordGUID, rd.Title, rd.URL, s.URL as SiteURL, Convert(date, rd.PublishedDate) as PublishedDate, count(sr.SubRecordID) NoOfSubRecords 
                from DataHunter.dbo.Record rd WITH(NOLOCK)			
				inner join DataHunter.dbo.SubRecord sr WITH(NOLOCK) on rd.RecordID = sr.RecordID '
		IF @Channel is NOT NULL
		BEGIN
			SET @SQLString = @SQLString + '
				inner join @TempChannel tc on tc.ChannelGUID = rd.ChannelGUID '
		END	
		IF @Tag is NOT NULL
		BEGIN
			SET @SQLString = @SQLString + '
				inner join (select distinct frtag.RecordID from DataHunter.dbo.FactRecordTag frtag WITH(NOLOCK) inner join @TempTag tt on frtag.TagGUID = tt.TagGUID) frt on rd.RecordID = frt.RecordID '
		END;
			
		IF @Site is NOT NULL
		BEGIN
			SET @SQLString = @SQLString + '
				inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
		END
		ELSE
		BEGIN
			SET @SQLString = @SQLString + '
				left join [221.132.37.57].ContentAggregator.dbo.Site s on s.GUID = rd.SiteGUID '
		END;

		SET @SQLString = @SQLString + 'where ('
		IF @Keyword is not null
		BEGIN
			SET @SQLString = @SQLString + '(contains(rd.Title, @Keyword) or contains(rd.Content, @Keyword) or rd.RecordID in (select distinct sr.RecordID from SubRecord sr where contains(sr.Content, @Keyword))) and '	
		END				
		SET @SQLString = @SQLString + '	rd.IsDeleted = 0 or rd.IsDeleted is null ) and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate 
			    group by rd.RecordID, rd.RecordGUID, rd.Title, rd.URL, s.URL, rd.PublishedDate ) leftside'
		SET @SQLString = @SQLString + '
	    left join DataHunter.dbo.FactRecordTag frtcount WITH(NOLOCK) on leftside.RecordID = frtcount.RecordID and frtcount.IsDeleted = 0
        group by leftside.RecordID, leftside.RecordGUID, leftside.Title, leftside.URL, leftside.SiteURL, leftside.PublishedDate, leftside.NoOfSubRecords '
	
	END
	
	IF @Filter = 'Tagged'
	BEGIN
	    SET @SQLString = @SQLString + '
	    having COUNT(frtcount.FactRecordTagID) > 0
	    '
	END
	ELSE IF @Filter = 'UnTagged'
	BEGIN
	SET @SQLString = @SQLString + '
	    having COUNT(frtcount.FactRecordTagID) = 0
	    '
	END
	
	SET @SQLString = @SQLString + '	
	)		
	select RecordID, RecordGUID, Title, URL, ISNULL(SiteURL, '''') SiteURL, PublishedDate, (select COUNT(*) from records) as ''TotalRecord'', NoOfTags
	from records
	where RowNumber > @FromRecord and RowNumber <= @ToRecord';
	
	print @SQLString
	SET @ParmDefinition = '
				@Keyword nvarchar(1024),
				@Site varchar(1024),
				@Channel varchar(1024),
				@Tag varchar(1024),
				@StartDate datetime,
				@EndDate datetime,
				@FromRecord int,
				@ToRecord int';

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
						@Keyword,
						@Site,
						@Channel,
						@Tag,
						@StartDate,
						@EndDate,
						@FromRecord,
						@ToRecord;			
END
GO

if OBJECT_ID ( 'GetRecord', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecord
GO
/*
* Description: get a record
* History
-------------------------------------------------------------
9/05/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetRecord 
	@RecordID = 1
*/
CREATE PROCEDURE GetRecord
	@RecordID int
AS
BEGIN			
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '
	select rd.URL, rd.Content, rd.Author, s.URL as ''SiteURL'', Convert(date, rd.PublishedDate) as ''PublishedDate'',
		(SELECT COUNT(*) from DataHunter.dbo.SubRecord sr WITH(NOLOCK) where sr.RecordID = @RecordID and (sr.IsDeleted is null or sr.IsDeleted = 0)) ''NumOfSubRecords''	
	from DataHunter.dbo.Record rd WITH(NOLOCK)
	inner join [221.132.37.57].ContentAggregator.dbo.Site s WITH(NOLOCK) on s.GUID = rd.SiteGUID
	where rd.RecordID = @RecordID'

	SET @ParmDefinition = '
				@RecordID int ';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID;		
END
GO



if OBJECT_ID ( 'GetSubRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSubRecords
GO
/*
* Description: Get sub records
* History
-------------------------------------------------------------
9/5/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSubRecords 
	@RecordID = 62611,
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE GetSubRecords
	@RecordID int,     
    @FromRecord int,
    @ToRecord int
AS
BEGIN					
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	SET @SQLString = '
		with subrecords as(
			select ROW_NUMBER() OVER(ORDER BY sr.PublishedDate ASC) AS ''RowNumber'', sr.SubRecordID, sr.Content, sr.Author, sr.PublishedDate, sr.URL
			from DataHunter.dbo.SubRecord sr WITH(NOLOCK) 			
			where sr.RecordID = @RecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) 	
			)
		select SubRecordID, Content, Author, PublishedDate, URL, (select COUNT(*) from subrecords) as ''TotalRecord''
		from subrecords
		where RowNumber > @FromRecord and RowNumber <= @ToRecord'
	
	SET @ParmDefinition = '
				@RecordID int,    
				@FromRecord int,
				@ToRecord int';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID,
					  	@FromRecord,
					  	@ToRecord;	
END
GO


if OBJECT_ID ( 'GetRecordTags', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordTags
GO
/*
* Description: get tags of record. Tags is marked automatically or manually
* History
-------------------------------------------------------------
9/05/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetRecordTags 
	@RecordID = 1,
	@IsSubRecord = 0
*/
CREATE PROCEDURE GetRecordTags
	@RecordID int,
	@IsSubRecord bit	
AS
BEGIN		
	select t.TagID, t.Word, t.WordWithoutAccent, t.TagGroupID
	from [221.132.37.57].ContentAggregator.dbo.Tag  t, DataHunter.dbo.FactRecordTag frt WITH(NOLOCK)
	where t.GUID = frt.TagGUID and frt.RecordID = @RecordID and frt.IsSubRecord = @IsSubRecord and frt.IsDeleted = 0
END
GO

--store procedures for data hunter statistics reports

if OBJECT_ID ( 'GetRecordsByDate', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordsByDate
GO
/*
* Description: 
* History
-------------------------------------------------------------
11/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetRecordsByDate 
	@StartDate = '11/27/2011',
	@EndDate = '11/27/2011'
*/
CREATE PROCEDURE GetRecordsByDate
	@StartDate date,
	@EndDate date	
AS
BEGIN		
	declare @sdid int
	set @sdid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)

	select leftside.Date, leftside.Name, leftside.URL, ISNULL(rightside.NoOfRecords, 0) NoOfRecords, rightside.NoOfSubRecords, rightside.NoOfTaggedRecords
	from
		(select dt.Date, s.Name, s.GUID, s.URL
			from [221.132.37.57].ContentAggregator.dbo.DimTime dt, [221.132.37.57].ContentAggregator.dbo.Site s
			where dt.DimTimeID >= @sdid and dt.DimTimeID <= @edid ) leftside
		left join (select r.SiteGUID, CONVERT(date,r.PublishedDate) PublishedDate, COUNT(distinct(r.recordid)) NoOfRecords, COUNT(distinct(sr.SubRecordID)) NoOfSubRecords, COUNT(distinct(frt.FactRecordTagID)) NoOfTaggedRecords
		from DataHunter.dbo.Record r
		left join DataHunter.dbo.SubRecord sr on r.RecordID = sr.RecordID
		left join DataHunter.dbo.FactRecordTag frt on r.RecordID = frt.RecordID or sr.SubRecordID = frt.RecordID
		group by r.SiteGUID, CONVERT(date,r.PublishedDate)) rightside
	on leftside.Date = rightside.PublishedDate and leftside.GUID = rightside.SiteGUID
	where NoOfRecords > 0
	order by leftside.Date desc, NoOfRecords desc
END
GO


if OBJECT_ID ( 'GetRecordCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordCount
GO
/*
* Description: 
* History
-------------------------------------------------------------
11/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetRecordCount 
	@StartDate = '11/29/2011',
	@EndDate = '11/29/2011 23:00:00'
*/
CREATE PROCEDURE GetRecordCount
	@StartDate datetime,
	@EndDate datetime	
AS
BEGIN		
	declare @sdid int
	set @sdid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)

	select s.URLName, COUNT(distinct(r.recordid)) NoOfRecords, COUNT(distinct(sr.SubRecordID)) NoOfSubRecords, COUNT(distinct(frt.FactRecordTagID)) NoOfTaggedRecords
	from DataHunter.dbo.Record r
	left join DataHunter.dbo.SubRecord sr on r.RecordID = sr.RecordID
	left join DataHunter.dbo.FactRecordTag frt on r.RecordID = frt.RecordID or sr.SubRecordID = frt.RecordID
	left join [221.132.37.57].ContentAggregator.dbo.Site s on r.SiteGUID = s.GUID
	where r.PublishedDate >= @StartDate and r.PublishedDate <= @EndDate
	group by s.URLName	
	having COUNT(distinct(r.recordid)) > 0
	order by NoOfRecords desc
END
GO


if OBJECT_ID ( 'GetPopularTags', 'P' ) IS NOT NULL
	DROP PROCEDURE GetPopularTags
GO
/*
* Description: 
* History
-------------------------------------------------------------
11/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetPopularTags 
	@StartDate = '10/2/2011',
	@EndDate = '12/20/2011 23:00:00'
*/
CREATE PROCEDURE GetPopularTags
	@StartDate datetime,
	@EndDate datetime	
AS
BEGIN		
	declare @sdid int
	set @sdid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
	
	select t.TagID, t.Word, COUNT(*) Total
	from DataHunter.dbo.FactRecordTag frt
	left join [221.132.37.57].ContentAggregator.dbo.Tag t on frt.TagGUID = t.GUID
	where frt.UpdatedDate >= @StartDate and frt.UpdatedDate <= @EndDate and frt.IsDeleted = 0
	group by t.TagID, t.Word
	order by Total desc
END
GO


if OBJECT_ID ( 'GetTagWebsiteTopicCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTagWebsiteTopicCount
GO
/*
* Description: 
* History
-------------------------------------------------------------
11/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTagWebsiteTopicCount 
	@StartDate = '11/2/2011',
	@EndDate = '11/29/2011 23:00:00'
*/
CREATE PROCEDURE GetTagWebsiteTopicCount
	@StartDate datetime,
	@EndDate datetime	
AS
BEGIN		
	declare @sdid int
	set @sdid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
	
	select datatable.CategoryName, datatable.TagWord, COUNT(distinct datatable.siteguid) as Websites, count(datatable.RecordID) Topics
	--	(select top 1 url from Record
			--where (select count(*)
			--		from SubRecord where SubRecord.RecordID = record.RecordID) = max(datatable.Comments)) as url,
	--	max(datatable.Comments)
	from (
			select c.CategoryID, c.Name as CategoryName, t.TagID, t.Word as TagWord, record.RecordID, record.URL,Record.SiteGUID
					--(select count(*)
					--from SubRecord where SubRecord.RecordID = record.RecordID) as Comments
			from Record inner join FactRecordTag on record.RecordID = FactRecordTag.RecordID
				inner join [221.132.37.57].ContentAggregator.dbo.Tag t on FactRecordTag.TagGUID = t.GUID
				inner join [221.132.37.57].ContentAggregator.dbo.CategoryTag ct on ct.TagID = t.TagID
				inner join [221.132.37.57].ContentAggregator.dbo.Category c on c.CategoryID = ct.CategoryID
			where Record.RecordID in (select RecordID from SubRecord where PublishedDate between @StartDate and @EndDate)
			--order by c.CategoryID, Comments desc
			) datatable
	group by datatable.CategoryName, datatable.tagWord
	
END
GO


if OBJECT_ID ( 'GetCategoryWebsiteTopicCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetCategoryWebsiteTopicCount
GO
/*
* Description: 
* History
-------------------------------------------------------------
11/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetCategoryWebsiteTopicCount 
	@StartDate = '11/2/2011',
	@EndDate = '11/29/2011 23:00:00'
*/
CREATE PROCEDURE GetCategoryWebsiteTopicCount
	@StartDate datetime,
	@EndDate datetime	
AS
BEGIN		
	declare @sdid int
	set @sdid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
	
	select datatable.CategoryName, count(distinct datatable.tagid) Tags, COUNT(distinct datatable.siteguid) as Websites, count(datatable.RecordID) Topics
	--	(select top 1 url from Record
			--where (select count(*)
			--		from SubRecord where SubRecord.RecordID = record.RecordID) = max(datatable.Comments)) as url,
	--	max(datatable.Comments)
	from (
			select c.CategoryID, c.Name as CategoryName, t.TagID, t.Word as TagWord, record.RecordID, record.URL,Record.SiteGUID
					--(select count(*)
					--from SubRecord where SubRecord.RecordID = record.RecordID) as Comments
			from Record				
				inner join FactRecordTag on record.RecordID = FactRecordTag.RecordID
				inner join [221.132.37.57].ContentAggregator.dbo.Tag t on FactRecordTag.TagGUID = t.GUID
				inner join [221.132.37.57].ContentAggregator.dbo.CategoryTag ct on ct.TagID = t.TagID
				inner join [221.132.37.57].ContentAggregator.dbo.Category c on c.CategoryID = ct.CategoryID
			where Record.RecordID in (select RecordID from SubRecord where PublishedDate between @StartDate and @EndDate)
			--order by c.CategoryID, Comments desc
			) datatable
	group by datatable.CategoryName	
END
GO


if OBJECT_ID ( 'GetSSMReport', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSSMReport
GO
/*
* Description: 
* History
-------------------------------------------------------------
11/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSSMReport 
	@StartDate = '11/2/2011',
	@EndDate = '11/29/2011 23:00:00'
*/
CREATE PROCEDURE GetSSMReport
	@StartDate datetime,
	@EndDate datetime	
AS
BEGIN		
	declare @sdid int
	set @sdid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from [221.132.37.57].ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
	
	select datatable.CategoryName, count(distinct datatable.tagid) Tags, COUNT(distinct datatable.siteguid) as Websites, count(datatable.RecordID) Topics
	--	(select top 1 url from Record
			--where (select count(*)
			--		from SubRecord where SubRecord.RecordID = record.RecordID) = max(datatable.Comments)) as url,
	--	max(datatable.Comments)
	from (
			select c.CategoryID, c.Name as CategoryName, t.TagID, t.Word as TagWord, record.RecordID, record.URL,Record.SiteGUID
					--(select count(*)
					--from SubRecord where SubRecord.RecordID = record.RecordID) as Comments
			from Record
				inner join [221.132.37.57].ContentAggregator.dbo.Site s on record.SiteGUID = s.GUID
				inner join [221.132.37.57].ContentAggregator.dbo.TargetFilterAttribute tfa on s.SiteID = tfa.SiteID and tfa.TargetFilterID = 1
				inner join FactRecordTag on record.RecordID = FactRecordTag.RecordID
				inner join [221.132.37.57].ContentAggregator.dbo.Tag t on FactRecordTag.TagGUID = t.GUID
				inner join [221.132.37.57].ContentAggregator.dbo.CategoryTag ct on ct.TagID = t.TagID
				inner join [221.132.37.57].ContentAggregator.dbo.Category c on c.CategoryID = ct.CategoryID
			where Record.RecordID in (select RecordID from SubRecord where PublishedDate between @StartDate and @EndDate)
			--order by c.CategoryID, Comments desc
			) datatable
	group by datatable.CategoryName
	
	select datatable.CategoryName, datatable.TagWord, COUNT(distinct datatable.siteguid) as Websites, count(datatable.RecordID) Topics
	--	(select top 1 url from Record
			--where (select count(*)
			--		from SubRecord where SubRecord.RecordID = record.RecordID) = max(datatable.Comments)) as url,
	--	max(datatable.Comments)
	from (
			select c.CategoryID, c.Name as CategoryName, t.TagID, t.Word as TagWord, record.RecordID, record.URL,Record.SiteGUID
					--(select count(*)
					--from SubRecord where SubRecord.RecordID = record.RecordID) as Comments
			from Record 
				inner join [221.132.37.57].ContentAggregator.dbo.Site s on record.SiteGUID = s.GUID
				inner join [221.132.37.57].ContentAggregator.dbo.TargetFilterAttribute tfa on s.SiteID = tfa.SiteID and tfa.TargetFilterID = 1
				inner join FactRecordTag on record.RecordID = FactRecordTag.RecordID
				inner join [221.132.37.57].ContentAggregator.dbo.Tag t on FactRecordTag.TagGUID = t.GUID
				inner join [221.132.37.57].ContentAggregator.dbo.CategoryTag ct on ct.TagID = t.TagID
				inner join [221.132.37.57].ContentAggregator.dbo.Category c on c.CategoryID = ct.CategoryID
			where Record.RecordID in (select RecordID from SubRecord where PublishedDate between @StartDate and @EndDate)
			--order by c.CategoryID, Comments desc
			) datatable
	group by datatable.CategoryName, datatable.tagWord
END
GO
