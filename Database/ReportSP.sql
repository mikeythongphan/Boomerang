USE ContentAggregator
GO

if OBJECT_ID ( 'GetKeywordSentimentByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetKeywordSentimentByTime
GO
/*
* Description: Get positive, negative, neutral by date
* History
-------------------------------------------------------------
3/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetKeywordSentimentByTime 
	@Keyword = '1,2,3',
	@Site = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetKeywordSentimentByTime
    @Keyword varchar(1024),
    @Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN	
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
		
	-- create temp site id
	DECLARE @TempSiteID table
	(
		SiteID int
	)
	DECLARE @SiteID varchar(10)

	SET @Site = LTRIM(RTRIM(@Site))+ ','
	SET @Pos = CHARINDEX(',', @Site, 1)

	IF REPLACE(@Site, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @SiteID = LTRIM(RTRIM(LEFT(@Site, @Pos - 1)))
			IF @SiteID <> ''
			BEGIN
				INSERT INTO @TempSiteID (SiteID) VALUES (CAST(@SiteID AS int))
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX(',', @Site, 1)

		END
	END
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
	
	SELECT dt.Date, f.KeywordID, k.Word , SUM(f.Total) as 'Buzz', SUM(f.Positive) as 'Positive', SUM(f.Negative) as 'Negative', SUM(f.Neutral) as 'Neutral'
	FROM FactKeywordRecord f join @TempKeywordID tk on f.KeywordID = tk.KeywordID join @TempSiteID ts on f.SiteID = ts.SiteID,
		Keyword k, DimTime dt	
	where k.KeywordID = f.KeywordID and f.DimTimeID = dt.DimTimeID and dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
	group by dt.Date, f.KeywordID, k.Word
	order by dt.Date, k.Word
END
GO


if OBJECT_ID ( 'GetSentimentOfKeywords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSentimentOfKeywords
GO
/*
* Description: Get positive, negative, neutral by keyword, site within a period of time
* History
-------------------------------------------------------------
3/28/2011	|	Vu Do	|	Add
9/24/2011	|	Vu		|	Add site parameter
-------------------------------------------------------------
* Sample:
EXEC GetSentimentOfKeywords 
	@Keyword = '1,2,3',
	@Site = '15, 2',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetSentimentOfKeywords
    @Keyword varchar(1024),
    @Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN	
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	SET @SQLString = '
	SET NOCOUNT ON	
	-- create temp keyword	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END		
	
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
		
	SELECT fkr.KeywordID, kw.Word, SUM(fkr.Total) Total, SUM(fkr.VeryPositive) VeryPositive, SUM(fkr.Positive) Positive, SUM(fkr.Neutral) Neutral, SUM(fkr.Negative) Negative, SUM(fkr.VeryNegative) VeryNegative
	FROM FactKeywordRecord fkr join @TempKeyword tkw on fkr.KeywordID = tkw.KeywordID
	left join Keyword kw on fkr.KeywordID = kw.KeywordID '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
		inner join @TempSite ts on fkr.SiteID = ts.SiteID	
		'
	END;
	
	SET @SQLString = @SQLString + '	
	where fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID
	group by fkr.KeywordID, kw.Word			
	order by kw.Word '
	
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;	
END
GO

if OBJECT_ID ( 'GetSentimentOfKeywordsByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSentimentOfKeywordsByTime
GO
/*
* Description: 
* History
-------------------------------------------------------------
3/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSentimentOfKeywordsByTime 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetSentimentOfKeywordsByTime
    @Keyword varchar(1024),        
    @StartDate date,
    @EndDate date
AS
BEGIN	
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
	
	select leftside.Date, leftside.KeywordID, leftside.Word, ISNULL(rightside.Total, 0) as 'Total', ISNULL(rightside.Positive, 0) as 'Positive', ISNULL(rightside.Negative, 0) as 'Negative', ISNULL(rightside.Neutral, 0) as 'Neutral'
	from
		(select dt.Date, dt.DimTimeID, kw.KeywordID, kw.Word
		from DimTime dt, Keyword kw, @TempKeywordID tk
		where kw.KeywordID = tk.KeywordID and dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID) leftside
	left join
		(SELECT fkr.DimTimeID, fkr.KeywordID, SUM(fkr.Total) as 'Total', SUM(fkr.Positive) as 'Positive', SUM(fkr.Negative) as 'Negative', SUM(fkr.Neutral) as 'Neutral'
		FROM FactKeywordRecord fkr join @TempKeywordID tkw on fkr.KeywordID = tkw.KeywordID
		where fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID
		group by fkr.DimTimeID, fkr.KeywordID) rightside
		on leftside.DimTimeID = rightside.DimTimeID and leftside.KeywordID = rightside.KeywordID
	order by leftside.KeywordID, leftside.DimTimeID
END
GO


if OBJECT_ID ( 'GetSentimentOfSitesByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSentimentOfSitesByTime
GO
/*
* Description: Get positive, negative, neutral by date
* History
-------------------------------------------------------------
3/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSentimentOfSitesByTime 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetSentimentOfSitesByTime
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
			
	select leftside.Date, leftside.SiteID, leftside.Name, leftside.URL, ISNULL(rightside.Total,0) 'Total', ISNULL(rightside.Positive, 0) 'Positive', ISNULL(rightside.Negative, 0) 'Negative', ISNULL(rightside.Neutral, 0) 'Neutral'
	from(
		select distinct dt.date, dt.DimTimeID, s.SiteID, s.Name, s.URL
		from DimTime dt, Site s
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID) leftside
	left join
		(SELECT fkr.DimTimeID, fkr.SiteID, SUM(fkr.Total) as 'Total', SUM(fkr.Positive) as 'Positive', SUM(fkr.Negative) as 'Negative', SUM(fkr.Neutral) as 'Neutral'
		FROM FactKeywordRecord fkr join @TempKeywordID tkw on fkr.KeywordID = tkw.KeywordID
		where fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID		
		group by fkr.DimTimeID, fkr.SiteID) rightside
	on (leftside.DimTimeID = rightside.DimTimeID and leftside.SiteID = rightside.SiteID)	
	order by leftside.SiteID, leftside.DimTimeID 
END
GO

if OBJECT_ID ( 'GetSentimentOfSites', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSentimentOfSites
GO
/*
* Description: Get setiment of sites
* History
-------------------------------------------------------------
3/23/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSentimentOfSites 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetSentimentOfSites
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
	
	SELECT fkr.SiteID, s.Name , s.URL, s.Type, SUM(fkr.Total) as 'Total', SUM(fkr.Positive) as 'Positive', SUM(fkr.Negative) as 'Negative', SUM(fkr.Neutral) as 'Neutral'
	FROM FactKeywordRecord fkr join @TempKeywordID tk on fkr.KeywordID = tk.KeywordID,
		Site s
	where s.SiteID = fkr.SiteID and fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID
	group by fkr.SiteID, s.Name, s.URL, s.Type
	order by Total desc
END
GO


if OBJECT_ID ( 'GetTotalSentimentByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalSentimentByTime
GO
/*
* Description: Get total sentiment by timeS
* History
-------------------------------------------------------------
3/23/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalSentimentByTime 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetTotalSentimentByTime
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END		
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
		
	select leftside.Date, ISNULL(rightside.LifetimeBuzz,0) 'LifetimeBuzz', ISNULL(rightside.Positive, 0) 'Positive', ISNULL(rightside.Negative, 0) 'Negative', ISNULL(rightside.Neutral, 0) 'Neutral'
	from(
		select distinct dt.DimTimeID, dt.date
		from DimTime dt
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID) leftside
	left join
		(SELECT f.DimTimeID,
			(SELECT SUM(fkr.Total)
			FROM FactKeywordRecord fkr join @TempKeywordID tkw on fkr.KeywordID = tkw.KeywordID
			WHERE fkr.DimTimeID <= f.DimTimeID	) as 'LifetimeBuzz',
		 SUM(f.Total) as 'Buzz', SUM(f.Positive) as 'Positive', SUM(f.Negative) as 'Negative', SUM(f.Neutral) as 'Neutral'
		FROM FactKeywordRecord f join @TempKeywordID tk on f.KeywordID = tk.KeywordID	
		where f.DimTimeID >= @StartTimeID and f.DimTimeID <= @EndTimeID
		group by f.DimTimeID) rightside
	on (leftside.DimTimeID = rightside.DimTimeID)			
END
GO

if OBJECT_ID ( 'GetTotalSitesByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalSitesByTime
GO
/*
* Description: Get total sentiment by timeS
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalSitesByTime 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetTotalSitesByTime
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)

	SELECT dt.DimTimeID, dt.Date, COUNT(distinct fka.SiteID) as 'Site',
	(SELECT COUNT(distinct f.SiteID)
	FROM FactKeywordRecord f join @TempKeywordID tkw on f.KeywordID = tkw.KeywordID	
		where f.DimTimeID <= dt.DimTimeID) as 'LifetimeSite'
	FROM DimTime dt left join(FactKeywordRecord fka join @TempKeywordID tk on fka.KeywordID = tk.KeywordID) on dt.DimTimeID = fka.DimTimeID
	where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
	group by dt.DimTimeID, dt.Date	
END
GO


if OBJECT_ID ( 'GetSentimentOfSiteTypes', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSentimentOfSiteTypes
GO
/*
* Description: 
* History
-------------------------------------------------------------
3/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSentimentOfSiteTypes 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetSentimentOfSiteTypes
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
	
	SELECT st.SiteTypeID, st.Name, sum(fkr.Total) as 'Buzz'	
	FROM FactKeywordRecord fkr join @TempKeywordID tk on fkr.KeywordID = tk.KeywordID, Site s, SiteType st	
	where  fkr.SiteID = s.SiteID and s.Type = st.SiteTypeID and fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID
	group by st.SiteTypeID, st.Name
	order by st.Name
END
GO


if OBJECT_ID ( 'GetVoicesOfSiteTypes', 'P' ) IS NOT NULL
	DROP PROCEDURE GetVoicesOfSiteTypes
GO
/*
* Description: get number of author by site type in a period of time
* History
-------------------------------------------------------------
3/28/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetVoicesOfSiteTypes 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetVoicesOfSiteTypes
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
	
	SELECT st.SiteTypeID, st.Name, COUNT(distinct fka.Author) as 'Voice'	
	FROM FactKeywordAuthor fka join @TempKeywordID tk on fka.KeywordID = tk.KeywordID, Site s, SiteType st	
	where fka.SiteID = s.SiteID and s.Type = st.SiteTypeID and fka.DimTimeID >= @StartTimeID and fka.DimTimeID <= @EndTimeID
	group by st.SiteTypeID, st.Name
	order by st.Name
END
GO

if OBJECT_ID ( 'GetTotalVoicesByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalVoicesByTime
GO
/*
* Description: get number of author by time
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalVoicesByTime 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetTotalVoicesByTime
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
					
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)	
					
	SELECT dt.DimTimeID, dt.Date, COUNT(distinct fka.Author) as 'Voice',
		(SELECT COUNT(distinct f.Author)
		FROM FactKeywordAuthor f join @TempKeywordID tkw on f.KeywordID = tkw.KeywordID
		where f.DimTimeID <= dt.DimTimeID) as 'LifetimeVoice'
	FROM DimTime dt left join (FactKeywordAuthor fka join @TempKeywordID tk on fka.KeywordID = tk.KeywordID) on fka.DimTimeID = dt.DimTimeID
	where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
	group by dt.DimTimeID, dt.Date
END
GO

if OBJECT_ID ( 'GetSiteVoicesByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSiteVoicesByTime
GO
/*
* Description: get number of author of a site by time
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSiteVoicesByTime 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/15/2011'
*/
CREATE PROCEDURE GetSiteVoicesByTime
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END			
		
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)		
	
	select leftside.Date, leftside.SiteID, leftside.Name, leftside.URL, ISNULL(rightside.Voice,0) 'Voice'
	from(
		select distinct dt.date, dt.DimTimeID, s.SiteID, s.Name, s.URL
		from DimTime dt, Site s
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID) leftside
	left join
		(SELECT fka.DimTimeID, s.SiteID, COUNT(distinct fka.Author) as 'Voice'
			FROM FactKeywordAuthor fka join @TempKeywordID tk on fka.KeywordID = tk.KeywordID, Site s
			where fka.SiteID = s.SiteID and fka.DimTimeID >= @StartTimeID and fka.DimTimeID <= @EndTimeID
			group by fka.DimTimeID, s.SiteID, s.Name, s.URL) rightside 
	on (leftside.DimTimeID = rightside.DimTimeID and leftside.SiteID = rightside.SiteID)	
END
GO

if OBJECT_ID ( 'GetInfoBar', 'P' ) IS NOT NULL
	DROP PROCEDURE GetInfoBar
GO
/*
* Description: get new buzz, lifetime buzz, new voices, sites, topics in a day, week, or month
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetInfoBar 
	@KeywordID = 19,
	@Site = null,
	@PreStartDate = '4/1/2012',
	@PreEndDate = '4/30/2012',
	@StartDate = '5/1/2012',
	@EndDate = '5/30/2012'
*/
CREATE PROCEDURE GetInfoBar
	@KeywordID int,
	@Site varchar(1024),
    @PreStartDate datetime,
    @PreEndDate datetime,
    @StartDate datetime,
    @EndDate datetime
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	SET @SQLString = '
	SET NOCOUNT ON
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @KeywordID	);
	
	declare @Pos int
	-- create temp site id
	DECLARE @TempSite table
	(
		SiteID int,
		SiteGUID uniqueidentifier
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
				INSERT INTO @TempSite (SiteID, SiteGUID) select SiteID, GUID from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @PreValue int
	declare @Value int
	declare @Diff int
	
	DECLARE @TodayInfoTable table
	(
		[Date] date,
		[Name] nvarchar(100),
		[Value] int,
		[Diff] int
	)
	-- get new buzz today
	-- Total of record and sub record all time
	set @PreValue = (SELECT Count(rd.RecordID)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @PreStartDate and rd.PublishedDate <= @PreEndDate) '
	
	SET @SQLString = @SQLString + '
	set @PreValue = @PreValue + (SELECT Count(sr.SubRecordID)
	FROM ContentCrawler.dbo.SubRecord sr with(nolock)
	inner join ContentCrawler.dbo.Record rd with(nolock) on sr.RecordID = rd.RecordID
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and sr.PublishedDate >= @PreStartDate and sr.PublishedDate <= @PreEndDate) '
		
	SET @SQLString = @SQLString + '
	set @Value = (SELECT Count(rd.RecordID)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate) '
	
	SET @SQLString = @SQLString + '
	set @Value = @Value + (SELECT Count(sr.SubRecordID)
	FROM ContentCrawler.dbo.SubRecord sr with(nolock)
	inner join ContentCrawler.dbo.Record rd with(nolock) on sr.RecordID = rd.RecordID
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '	
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and sr.PublishedDate >= @StartDate and sr.PublishedDate <= @EndDate) '
	
	SET @SQLString = @SQLString + '
	if @PreValue = 0
		begin
			if @Value = 0
				set @Diff = 0
			else
				set @Diff = 100
		end
	else
		begin
			set @Diff = (@Value - @PreValue)*100/@PreValue
		end
		
	set @Value = ISNULL(@Value,0)
	set @Diff = ISNULL(@Diff,0)
	insert into @TodayInfoTable ( Date, Name, Value, Diff)
	values (@EndDate, ''NewBuzz'', @Value, @Diff) '
	
	SET	@SQLString =  @SQLString + '
	-- Total of record and sub record all time
	set @PreValue = (SELECT Count(rd.RecordID)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= ''1/1/2011'' and rd.PublishedDate <= @PreEndDate) '
	
	SET	@SQLString =  @SQLString + '
	set @PreValue = @PreValue + (SELECT Count(sr.SubRecordID)
	FROM ContentCrawler.dbo.SubRecord sr with(nolock)
	inner join ContentCrawler.dbo.Record rd with(nolock) on sr.RecordID = rd.RecordID
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and sr.PublishedDate >= ''1/1/2011'' and sr.PublishedDate <= @PreEndDate) '
	
	SET	@SQLString =  @SQLString + '
	set @Value = (SELECT Count(rd.RecordID)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= ''1/1/2011'' and rd.PublishedDate <= @EndDate) '
	
	SET	@SQLString =  @SQLString + '
	set @Value = @Value + (SELECT Count(sr.SubRecordID)
	FROM ContentCrawler.dbo.SubRecord sr with(nolock)
	inner join ContentCrawler.dbo.Record rd with(nolock) on sr.RecordID = rd.RecordID
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and sr.PublishedDate >= ''1/1/2011'' and sr.PublishedDate <= @EndDate) '
	
	SET	@SQLString =  @SQLString + '
	if @PreValue = 0
		begin
			if @Value = 0
				set @Diff = 0
			else
				set @Diff = 100
		end
	else
		begin
			set @Diff = (@Value - @PreValue)*100/@PreValue
		end
	
	set @Value = ISNULL(@Value,0)
	set @Diff = ISNULL(@Diff,0)		
	insert into @TodayInfoTable ( Date, Name, Value, Diff)
	values (@EndDate, ''LifetimeBuzz'', @Value, @Diff) '
			
	SET @SQLString = @SQLString + '
	-- New Voices
	set @PreValue = (SELECT Count(distinct rd.Author)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @PreStartDate and rd.PublishedDate <= @PreEndDate) '
	
	SET @SQLString = @SQLString + '
	set @PreValue = @PreValue + (SELECT Count(distinct sr.Author)
	FROM ContentCrawler.dbo.SubRecord sr with(nolock)
	inner join ContentCrawler.dbo.Record rd with(nolock) on sr.RecordID = rd.RecordID
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and sr.PublishedDate >= @PreStartDate and sr.PublishedDate <= @PreEndDate) '
	
	SET @SQLString = @SQLString + '			
	set @Value = (SELECT Count(distinct rd.Author)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString +'
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate) '
	
	SET @SQLString = @SQLString + '			
	set @Value = @Value + (SELECT Count(distinct sr.Author)
	FROM ContentCrawler.dbo.SubRecord sr with(nolock)
	inner join ContentCrawler.dbo.Record rd with(nolock) on sr.RecordID = rd.RecordID
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and sr.PublishedDate >= @StartDate and sr.PublishedDate <= @EndDate) '
	
	SET @SQLString = @SQLString + '
	if @PreValue = 0
		begin
			if @Value = 0
				set @Diff = 0
			else
				set @Diff = 100
		end
	else
		begin
			set @Diff = (@Value - @PreValue)*100/@PreValue
		end
	set @Value = ISNULL(@Value,0)
	set @Diff = ISNULL(@Diff,0)	
	insert into @TodayInfoTable ( Date, Name, Value, Diff)
	values (@EndDate, ''NewVoices'', @Value, @Diff) '
	
	SET	@SQLString =  @SQLString + '
	-- Channel
	set @PreValue = (SELECT Count(distinct rd.SiteGUID)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @PreStartDate and rd.PublishedDate <= @PreEndDate) '
	
	SET	@SQLString =  @SQLString + '
	set @Value = (SELECT Count(distinct rd.SiteGUID)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate) '
	
	SET	@SQLString =  @SQLString + '
	if @PreValue = 0
		begin
			if @Value = 0
				set @Diff = 0
			else
				set @Diff = 100
		end
	else
		begin
			set @Diff = (@Value - @PreValue)*100/@PreValue
		end		
	set @Value = ISNULL(@Value,0)
	set @Diff = ISNULL(@Diff,0)
	insert into @TodayInfoTable ( Date, Name, Value, Diff)
	values (@EndDate, ''Channels'', @Value, @Diff) '
	
	SET	@SQLString =  @SQLString + '
	-- topic
	set @PreValue = (SELECT Count(rd.RecordID)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @PreStartDate and rd.PublishedDate <= @PreEndDate) '
	
	SET	@SQLString =  @SQLString + '
	set @Value = (SELECT Count(rd.RecordID)
	FROM ContentCrawler.dbo.Record rd with(nolock)
	inner join ContentCrawler.dbo.FactRecord fr with(nolock) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 '
	IF @Site is not null
		SET @SQLString = @SQLString + '
	inner join @TempSite ts on rd.SiteGUID = ts.SiteGUID '
	SET @SQLString = @SQLString + '
	where rd.KeywordGUID = @KeywordGUID and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate) '
	
	SET	@SQLString =  @SQLString + '
	if @PreValue = 0
		begin
			if @Value = 0
				set @Diff = 0
			else
				set @Diff = 100
		end
	else
		begin
			set @Diff = (@Value - @PreValue)*100/@PreValue
		end		
	set @Value = ISNULL(@Value,0)
	set @Diff = ISNULL(@Diff,0)
	insert into @TodayInfoTable ( Date, Name, Value, Diff)
	values (@EndDate, ''Topics'', @Value, @Diff) '
	
	SET @SQLString = @SQLString + '
	select * from @TodayInfoTable '
	
		SET @ParmDefinition = '
					@KeywordID int,
					@Site varchar(1024),
					@PreStartDate datetime,
					@PreEndDate datetime,
					@StartDate datetime,
					@EndDate datetime';
	print @SQLString
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@Site,
						@PreStartDate,
						@PreEndDate,
						@StartDate,						
						@EndDate;	
END
GO

if OBJECT_ID ( 'GetRecordCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordCount
GO
/*
* Description: get total record for frontend
* Params
	Owner: none: records that have not tagged sentiment. auto: service. manual: 
	Tagged: Tagged, UnTagged
	Bookmarked: Followed, Unfollowed
	Reviewed: 
	Sorting: InsertedDate, PublishedDate, UpdatedDate
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetRecordCount 
	@KeywordID = 72,
	@Site = null,
	@Tag = null,
	@Tagged = null,
	@Bookmarked = null,	
	@Reviewed = '-1',
	@IsBrand = 1,
	@Owner = null,
	@StartDate = '4/11/2011',
	@EndDate = '5/20/2012',
	@Sentiment = -1
*/
CREATE PROCEDURE GetRecordCount
	@KeywordID int,
	@Site varchar(1024),
	@Tag varchar(1024),
	@Tagged varchar(128),
	@Bookmarked varchar(128),
	@Reviewed varchar(128),
	@IsBrand bit,	
	@Owner varchar(128),
    @StartDate datetime,
    @EndDate datetime,
    @Sentiment int
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

	SET @Site = LTRIM(RTRIM(@Site))+ '',''
	SET @Pos = CHARINDEX('','', @Site, 1)

	IF REPLACE(@Site, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @SiteID = LTRIM(RTRIM(LEFT(@Site, @Pos - 1)))
			IF @SiteID <> ''''
			BEGIN
				INSERT INTO @TempSite (SiteID, SiteGUID, URL) select SiteID, GUID, URL from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

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
				INSERT INTO @TempTag (TagID, TagGUID) select TagID, GUID from Tag where TagID = CAST(@TagID AS int)
			END
			SET @Tag = RIGHT(@Tag, LEN(@Tag) - @Pos)
			SET @Pos = CHARINDEX('','', @Tag, 1)

		END
	END;
				
	'
	
	SET @SQLString = @SQLString + ' 
			select count(rd.RecordID) Total
			from ContentCrawler.dbo.Record rd WITH(NOLOCK) '
									
	IF @Tag is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join (select distinct frt.RecordID from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) inner join @TempTag tt on frt.TagGUID = tt.TagGUID) frt on rd.RecordID = frt.RecordID '
	END;		
			
	IF @Site is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
	END

	IF @Sentiment <> 0 --get all
	BEGIN
		SET @SQLString = @SQLString + '			
			inner join ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 and fr.Sentiment = ' + CONVERT(varchar(5), @Sentiment )
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		left join ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0'
	END
		
	SET @SQLString = @SQLString + ' 
	where (rd.IsDeleted = 0 or rd.IsDeleted is null) 	
		and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate 
		and rd.KeywordGUID = @KeywordGUID '
	IF @Bookmarked = 'Followed'
	BEGIN
		SET @SQLString = @SQLString + ' and rd.IsFollowed = 1'
	END
	ELSE IF @Bookmarked = 'Unfollowed'
	BEGIN
		SET @SQLString = @SQLString + ' and ( rd.IsFollowed is null or rd.IsFollowed = 0)'
	END
	
	IF @Reviewed = 'reviewed'
	BEGIN		
		IF @IsBrand = 1
		BEGIN
			SET @SQLString = @SQLString + ' 
			and fr.Sentiment is not null '	
		END
		ELSE
		BEGIN
			SET @SQLString = @SQLString + ' 
			and (rd.Irrelevant = 1 or rd.IsFollowed = 1 or fr.Sentiment is not null or 
			exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0))'		
		END
		
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN		
		IF @IsBrand = 1
		BEGIN
			SET @SQLString = @SQLString + ' 
			and fr.Sentiment is null '
		END
		ELSE
		BEGIN
			SET @SQLString = @SQLString + ' 
			and ((rd.Irrelevant is NULL or rd.Irrelevant = 0) and (rd.IsFollowed is NULL or rd.IsFollowed = 0) and (fre.Sentiment is null )  
			and not exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0))'		
		END		
	END	
	
	IF @Tagged = 'Tagged'
	BEGIN
		SET @SQLString = @SQLString + '
			and exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0) '
	END
	ELSE IF @Tagged = 'UnTagged'
	BEGIN
		SET @SQLString = @SQLString + '
			and not exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0) '
	END			
		
	print @SQLString;
	SET @ParmDefinition = '
				@KeywordID int,
				@Site varchar(1024),
				@Tag varchar(1024),				
				@Owner varchar(512),
				@StartDate datetime,
				@EndDate datetime,
				@Sentiment int';

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@Site,
						@Tag,						
						@Owner,
						@StartDate,
						@EndDate,
						@Sentiment;			
END
GO


if OBJECT_ID ( 'GetLatestContents', 'P' ) IS NOT NULL
	DROP PROCEDURE GetLatestContents
GO
/*
* Description: get latest records
* Params
	Owner: none: records that have not tagged sentiment. auto: service. manual: 
	Tagged: Tagged, UnTagged
	Bookmarked: Followed, Unfollowed
	Reviewed: 
	Sorting: InsertedDate, PublishedDate, UpdatedDate
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
8/14/2011	|	Vu Do	|	Add Owner column
-------------------------------------------------------------
* Sample:
EXEC GetLatestContents 
	@KeywordID = 72,
	@Site = null,
	@Tag = null,
	@Tagged = null,
	@Bookmarked = null,	
	@Reviewed = '-1',
	@IsBrand = 1,
	@Owner = null,
	@StartDate = '4/11/2011',
	@EndDate = '5/20/2012',
	@Sentiment = -1,
	@Sorting = 'PublishedDate',
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE GetLatestContents
	@KeywordID int,
	@Site varchar(1024),
	@Tag varchar(1024),
	@Tagged varchar(128),
	@Bookmarked varchar(128),
	@Reviewed varchar(128),
	@IsBrand bit,	
	@Owner varchar(128),
    @StartDate datetime,
    @EndDate datetime,
    @Sentiment int,
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
				INSERT INTO @TempSite (SiteID, SiteGUID, URL) select SiteID, GUID, URL from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

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
				INSERT INTO @TempTag (TagID, TagGUID) select TagID, GUID from Tag where TagID = CAST(@TagID AS int)
			END
			SET @Tag = RIGHT(@Tag, LEN(@Tag) - @Pos)
			SET @Pos = CHARINDEX('','', @Tag, 1)

		END
	END;
				
	'
	
	SET @SQLString = @SQLString + ' with records as(
			select ROW_NUMBER() OVER(ORDER BY rd.' + @Sorting + ' DESC) AS ''RowNumber'', rd.RecordID, rd.RecordGUID, rd.Title, rd.URL, s.URL as ''SiteURL'', Convert(date, rd.PublishedDate) as ''PublishedDate'', fr.Sentiment, fr.Owner, rd.IsFollowed, rd.Irrelevant
			from ContentCrawler.dbo.Record rd WITH(NOLOCK) '
									
	IF @Tag is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join (
				select frt.RecordID from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) inner join @TempTag tt on frt.TagGUID = tt.TagGUID and frt.IsDeleted = 0
				union 
				select sr.RecordID from ContentCrawler.dbo.Subrecord sr with(nolock) 
				inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on sr.SubrecordID = frt.RecordID and frt.IsDeleted = 0
				inner join @TempTag tt on frt.TagGUID = tt.TagGUID
			) frt on rd.RecordID = frt.RecordID '
	END;		
			
	IF @Site is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
	END
	ELSE
	BEGIN
			SET @SQLString = @SQLString + '
			left join Site s on s.GUID = rd.SiteGUID '
	END;
	IF @Sentiment <> 0 --get all
	BEGIN
		SET @SQLString = @SQLString + '			
			inner join ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 and fr.Sentiment = ' + CONVERT(varchar(5), @Sentiment )
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
		left join ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) on rd.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0'
	END
		
	SET @SQLString = @SQLString + ' 
	where (rd.IsDeleted = 0 or rd.IsDeleted is null) 	
		and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate 
		and rd.KeywordGUID = @KeywordGUID '
	IF @Bookmarked = 'Followed'
	BEGIN
		SET @SQLString = @SQLString + ' and rd.IsFollowed = 1'
	END
	ELSE IF @Bookmarked = 'Unfollowed'
	BEGIN
		SET @SQLString = @SQLString + ' and ( rd.IsFollowed is null or rd.IsFollowed = 0)'
	END
	
	IF @Reviewed = 'reviewed'
	BEGIN		
		IF @IsBrand = 1
		BEGIN
			SET @SQLString = @SQLString + ' 
			and fr.Sentiment is not null '	
		END
		ELSE
		BEGIN
			SET @SQLString = @SQLString + ' 
			and (rd.Irrelevant = 1 or rd.IsFollowed = 1 or fr.Sentiment is not null or 
			exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0))'		
		END
		
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN		
		IF @IsBrand = 1
		BEGIN
			SET @SQLString = @SQLString + ' 
			and fr.Sentiment is null '
		END
		ELSE
		BEGIN
			SET @SQLString = @SQLString + ' 
			and ((rd.Irrelevant is NULL or rd.Irrelevant = 0) and (rd.IsFollowed is NULL or rd.IsFollowed = 0) and (fre.Sentiment is null )  
			and not exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0))'		
		END		
	END	
	
	IF @Tagged = 'Tagged'
	BEGIN
		SET @SQLString = @SQLString + '
			and exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0) '
	END
	ELSE IF @Tagged = 'UnTagged'
	BEGIN
		SET @SQLString = @SQLString + '
			and not exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0) '
	END			
	
	SET @SQLString = @SQLString + '	
	)		
	select RecordID, RecordGUID, Title, URL, ISNULL(SiteURL,'''') SiteURL, PublishedDate, Sentiment, Owner, ISNULL(IsFollowed, 0) IsFollowed, ISNULL(Irrelevant, 0) Irrelevant, 0 as ''TotalRecord''
	, 0 Tags
	from records
	where RowNumber > @FromRecord and RowNumber <= @ToRecord
	order by RowNumber asc';
	print @SQLString;
	SET @ParmDefinition = '
				@KeywordID int,
				@Site varchar(1024),
				@Tag varchar(1024),				
				@Owner varchar(512),
				@StartDate datetime,
				@EndDate datetime,
				@Sentiment int,
				@FromRecord int,
				@ToRecord int';

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
						@Site,
						@Tag,						
						@Owner,
						@StartDate,
						@EndDate,
						@Sentiment,
						@FromRecord,
						@ToRecord;			
END
GO


if OBJECT_ID ( 'GetRecordsEmotion', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordsEmotion
GO
/*
* Description: get a list of records with emotions
* Params
	Sentiment: emotion
	Owner: none: records that have not tagged sentiment. auto: service. manual: 
	TagFilter: Tagged, UnTagged
	Filter: Followed, Unfollowed
	Sorting: InsertedDate, PublishedDate, UpdatedDate
* History
-------------------------------------------------------------
3/12/2011	|	Vu Do	|	Add
8/14/2011	|	Vu Do	|	Add Owner column
-------------------------------------------------------------
* Sample:
EXEC GetRecordsEmotion 
	@KeywordID = 72,
	@SubKeywordID = 15,
	@Site = null,
	@Tag = null,
	@Tagged = null,
	@Bookmarked = null,	
	@Reviewed = null,
	@SubKeyword = null,	
	@Owner = null,
	@StartDate = '1/1/2012',
	@EndDate = '11/20/2012',
	@Emotion = null,
	@Sorting = 'PublishedDate',
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE GetRecordsEmotion
	@KeywordID int,
	@SubKeywordID int,
	@Site varchar(1024),
	@Tag varchar(1024),
	@Tagged varchar(128),
	@Bookmarked varchar(128),
	@Reviewed varchar(128),
	@SubKeyword nvarchar(128),	
	@Owner varchar(128),
    @StartDate datetime,
    @EndDate datetime,
    @Emotion varchar(32),
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
	declare @SubKeywordGUID uniqueidentifier;
	
	IF @SubKeywordID <> -1
	BEGIN
		set @SubKeywordGUID = (select GUID from ContentAggregator.dbo.SubKeyword where SubKeywordID = @SubKeywordID	);
	END	
	
	DECLARE @Pos int
	-- create temp keyword id	
	--DECLARE @TempKeyword table
	--(
	--	KeywordID int,
	--	KeywordGUID uniqueidentifier
	--)
	--DECLARE @KeywordID varchar(10)

	--SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	--SET @Pos = CHARINDEX('','', @Keyword, 1)

	--IF REPLACE(@Keyword, '','', '''') <> ''''
	--BEGIN
	--	WHILE @Pos > 0
	--	BEGIN
	--		SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
	--		IF @KeywordID <> ''''
	--		BEGIN
	--			INSERT INTO @TempKeyword (KeywordID, KeywordGUID)  select KeywordID, GUID from Keyword where KeywordID = CAST(@KeywordID AS int)
	--		END
	--		SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
	--		SET @Pos = CHARINDEX('','', @Keyword, 1)

	--	END
	--END	;
	
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
				INSERT INTO @TempSite (SiteID, SiteGUID, URL) select SiteID, GUID, URL from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

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
				INSERT INTO @TempTag (TagID, TagGUID) select TagID, GUID from Tag where TagID = CAST(@TagID AS int)
			END
			SET @Tag = RIGHT(@Tag, LEN(@Tag) - @Pos)
			SET @Pos = CHARINDEX('','', @Tag, 1)

		END
	END;	
		
	'
	
	SET @SQLString = @SQLString + ' with records as(
		select ROW_NUMBER() OVER(ORDER BY rd.' + @Sorting + ' DESC) AS ''RowNumber'', rd.RecordID, rd.RecordGUID, rd.Title, rd.URL, s.URL as ''SiteURL'', Convert(date, rd.PublishedDate) as ''PublishedDate'', rd.IsFollowed, rd.Irrelevant
			, fre.Acceptance, fre.Fear, fre.Supprise, fre.Sadness, fre.Disgust, fre.Anger, fre.Anticipation, fre.Joy
			
		from ContentCrawler.dbo.Record rd WITH(NOLOCK) '

	IF @Tag is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join (select distinct frt.RecordID from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) inner join @TempTag tt on frt.TagGUID = tt.TagGUID) frt on rd.RecordID = frt.RecordID '
	END;			
			
	IF @Site is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
			left join Site s on s.GUID = rd.SiteGUID '
	END;
			
	
	IF @Emotion <> 'all' --get all
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
		where (rd.IsDeleted = 0 or rd.IsDeleted is null) 	
		and rd.PublishedDate >= @StartDate and rd.PublishedDate <= @EndDate 
		and rd.KeywordGUID = @KeywordGUID '
	IF @SubKeywordID <> -1
	BEGIN
		SET @SQLString = @SQLString + ' and rd.SubKeywordGUID = @SubKeywordGUID'
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + ' and rd.SubKeywordGUID is null'
	END
	
	IF @Bookmarked = 'Followed'
	BEGIN
		SET @SQLString = @SQLString + ' and rd.IsFollowed = 1'
	END
	ELSE IF @Bookmarked = 'Unfollowed'
	BEGIN
		SET @SQLString = @SQLString + ' and ( rd.IsFollowed is null or rd.IsFollowed = 0)'
	END
	
	--IF @SubKeyword is not null or @SubKeyword <> ''
	--BEGIN
	--	SET @SQLString = @SQLString + ' 
	--	and ( Contains(rd.Content, @SubKeyword) or Contains(rd.Title, @SubKeyword) /*or rd.RecordID in (select sr.RecordID from ContentCrawler.dbo.SubRecord sr where contains(sr.Content, @SubKeyword))*/)'
	--END
			
	--IF @Keyword is NOT NULL
	--BEGIN
	--	SET @SQLString = @SQLString + '
	--		inner join @TempKeyword kt on kt.KeywordGUID = rd.KeywordGUID '
	--END;
	
	
	
	IF @Reviewed = 'reviewed'
	BEGIN
		SET @Tagged = null;
		SET @SQLString = @SQLString + ' 
		and (rd.Irrelevant = 1 or rd.IsFollowed = 1 or fre.Acceptance = 1 or fre.Fear = 1 or fre.Supprise = 1 or fre.Sadness = 1 or fre.Disgust = 1 or fre.Anger = 1 or fre.Anticipation = 1 or fre.Joy = 1 or 
		exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0))'	
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN
		SET @Tagged = null;
		SET @SQLString = @SQLString + ' 
		and ((rd.Irrelevant is NULL or rd.Irrelevant = 0) and (rd.IsFollowed is NULL or rd.IsFollowed = 0) and (fre.Acceptance is null or fre.Acceptance = 0) and (fre.Fear is null or fre.Fear = 0) and (fre.Supprise is null or fre.Supprise = 0) and (fre.Sadness is null or fre.Sadness = 0) and (fre.Disgust is null or fre.Disgust = 0) and (fre.Anger is null or fre.Anger = 0) and (fre.Anticipation is null or fre.Anticipation = 0) and (fre.Joy is null or fre.Joy = 0) and 
		not exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID and frt.IsDeleted = 0))'	
	END	
	
	IF @Tagged = 'Tagged'
	BEGIN
		SET @SQLString = @SQLString + '
			and exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID) '
	END
	ELSE IF @Tagged = 'UnTagged'
	BEGIN
		SET @SQLString = @SQLString + '
			and not exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = rd.RecordID) '
	END
				
	IF @Owner = 'none'
	BEGIN
		SET @SQLString = @SQLString + '
			and fr.Owner is null '
	END		
	
		
	SET @SQLString = @SQLString + '	
	)		
	select RecordID, RecordGUID, Title, URL, ISNULL(SiteURL,'''') SiteURL, PublishedDate, ISNULL(IsFollowed, 0) IsFollowed, ISNULL(Irrelevant, 0) Irrelevant, Acceptance, Fear, Supprise, Sadness, Disgust, Anger, Anticipation, Joy
	, (select count(1) from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = records.RecordID and frt.IsDeleted = 0) Tags, (select COUNT(*) from records) as ''TotalRecord'', (select COUNT(1) from ContentCrawler.dbo.SubRecord sr where records.RecordID = sr.RecordID ) SubRecords
	from records
	where RowNumber > @FromRecord and RowNumber <= @ToRecord
	order by RowNumber asc';	
	
	SET @ParmDefinition = '
				@KeywordID int,
				@SubKeywordID int,
				@Site varchar(1024),
				@Tag varchar(1024),				
				@Owner varchar(512),
				@SubKeyword nvarchar(128),	
				@StartDate datetime,
				@EndDate datetime,
				@Emotion varchar(32),
				@FromRecord int,
				@ToRecord int';
	
	print @SQLString;
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@KeywordID,
					  	@SubKeywordID,
						@Site,
						@Tag,						
						@Owner,
						@SubKeyword,
						@StartDate,
						@EndDate,
						@Emotion,
						@FromRecord,
						@ToRecord;			
END
GO

if OBJECT_ID ( 'GetSubRecordsEmotion', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSubRecordsEmotion
GO
/*
* Description: Get sub records from for backend, with emotion
* History
-------------------------------------------------------------
2/1/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSubRecordsEmotion
	@RecordID = 672039,	
	@Words = null,	
	@Reviewed = '-1',
	@Status = -1,
	@FromRecord = 0,
	@ToRecord = 100
*/
CREATE PROCEDURE GetSubRecordsEmotion
	@RecordID int,	
	@Words nvarchar(512),  
	@Reviewed varchar(128),
	@Status int,      
    @FromRecord int,
    @ToRecord int
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
			with subrecords as(
				select ROW_NUMBER() OVER(ORDER BY sr.PublishedDate ASC) AS ''RowNumber'', sr.SubRecordID, sr.Content, sr.Author, sr.PublishedDate, sr.URL, sr.Irrelevant
				, fre.Acceptance, fre.Fear, fre.Supprise, fre.Sadness, fre.Disgust, fre.Anger, fre.Anticipation, fre.Joy, ISNULL(srs.Status, 101) Status
				from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
				left join ContentCrawler.dbo.FactRecordEmotion fre WITH(NOLOCK) on sr.SubRecordID = fre.RecordID and fre.IsSubRecord = 1 and fre.IsDeleted = 0
				left join ContentCrawler.dbo.SubRecordStatus srs WITH(NOLOCK) on sr.SubRecordID = srs.SubRecordID '
	SET @SQLString = @SQLString + ' 
				where sr.RecordID = @RecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) ' + @SQLStringTemp
		
	IF @Status = 102 or @Status = 103
	BEGIN
		SET @SQLString = @SQLString + ' and srs.Status = ' + CONVERT(varchar(10), @Status)
	END
	ELSE IF @Status = 101
	BEGIN
		SET @SQLString = @SQLString + ' and (srs.Status is null or srs.Status = 101 ) '
	END
	
	IF @Reviewed = 'reviewed'
	BEGIN		
		SET @SQLString = @SQLString + ' 
		and (sr.Irrelevant = 1 or fre.Acceptance = 1 or fre.Fear = 1 or fre.Supprise = 1 or fre.Sadness = 1 or fre.Disgust = 1 or fre.Anger = 1 or fre.Anticipation = 1 or fre.Joy = 1 or 
		exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = sr.SubRecordID and frt.IsSubRecord = 1 and frt.IsDeleted = 0))'	
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN		
		SET @SQLString = @SQLString + ' 
		and ((sr.Irrelevant is NULL or sr.Irrelevant = 0) and (fre.Acceptance is null or fre.Acceptance = 0) and (fre.Fear is null or fre.Fear = 0) and (fre.Supprise is null or fre.Supprise = 0) and (fre.Sadness is null or fre.Sadness = 0) and (fre.Disgust is null or fre.Disgust = 0) and (fre.Anger is null or fre.Anger = 0) and (fre.Anticipation is null or fre.Anticipation = 0) and (fre.Joy is null or fre.Joy = 0) and 
		not exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = sr.SubRecordID and frt.IsSubRecord = 1 and frt.IsDeleted = 0 ))'	
	END	
	
	SET @SQLString = @SQLString + ')
			select SubRecordID, Content, Author, PublishedDate, URL, Irrelevant, Acceptance, Fear, Supprise, Sadness, Disgust, Anger, Anticipation, Joy, Status, (select COUNT(*) from subrecords) as ''TotalRecord'', 
					ISNULL((select distinct word + '';'' as [data()] from ContentAggregator.dbo.Tag t WITH(NOLOCK) inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on (frt.RecordID = subrecords.SubRecordID and frt.IsSubRecord = 1 and frt.IsDeleted = 0) and frt.TagGUID = t.GUID  for xml path('''')),'''') as Tags
			from subrecords
			where RowNumber > @FromRecord and RowNumber <= @ToRecord
			order by RowNumber asc'	
	
	SET @ParmDefinition = '
				@RecordID int,				        
				@FromRecord int,
				@ToRecord int';
	print @SQLString
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID,
					  	@FromRecord,
					  	@ToRecord;
					  					  		
END
GO

if OBJECT_ID ( 'GetSubRecordStatusCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSubRecordStatusCount
GO
/*
* Description: get comment status count: Open, Pending, Done
* History
-------------------------------------------------------------
2/1/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSubRecordStatusCount
	@RecordID = 672039
*/
CREATE PROCEDURE GetSubRecordStatusCount
	@RecordID int	
AS
BEGIN					
	select isnull(srs.Status, 101), COUNT(sr.RecordID)
	from ContentCrawler.dbo.SubRecord sr
	left join ContentCrawler.dbo.SubRecordStatus srs on sr.SubRecordID = srs.SubRecordID
	where sr.RecordID = 92843 and ( sr.IsDeleted is null or sr.IsDeleted = 0)
	group by srs.Status
END
GO

if OBJECT_ID ( 'GetSubRecordReviewedCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSubRecordReviewedCount
GO
/*
* Description: get comment reviewed/count
	Brand: tagged, sentiment, irrelevant, deleted
	Category: tagged, irrelevant, deleted
* History
-------------------------------------------------------------
2/1/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSubRecordReviewedCount
	@RecordID = 96684,
	@IsBrand = 0
*/
CREATE PROCEDURE GetSubRecordReviewedCount
	@RecordID int,
	@IsBrand bit	
AS
BEGIN					
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	with subrecords as(
			select ROW_NUMBER() OVER(ORDER BY sr.SubRecordID) RowNumber, sr.SubRecordID, sr.Irrelevant
			from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
			where sr.RecordID = @RecordID and ( sr.IsDeleted is null or sr.IsDeleted = 0))
	select count(1) Reviewed, (select count(1) from subrecords) Total 
	from subrecords sr '
	IF @IsBrand = 1
	BEGIN
		set @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) on sr.SubRecordID = fr.SubRecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 1 and fr.Sentiment is not null ' 
	END
	ELSE
	BEGIN
		set @SQLString = @SQLString + ' 		
		where sr.Irrelevant = 1
		or exists (select * from ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) where sr.SubRecordID = fr.SubRecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 1 and fr.Sentiment is not null)
		or exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = sr.SubRecordID and frt.IsSubRecord = 1 and frt.IsDeleted = 0) '
	END
	SET @ParmDefinition = '
					@RecordID int'
	print @SQLString;

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID;
END
GO

if OBJECT_ID ( 'GetIsRecordReviewed', 'P' ) IS NOT NULL
	DROP PROCEDURE GetIsRecordReviewed
GO
/*
* Description: get comment reviewed/count
	Brand: tagged, sentiment, irrelevant, deleted
	Category: tagged, irrelevant, deleted
* History
-------------------------------------------------------------
2/1/2012	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetIsRecordReviewed
	@RecordID = 96684,
	@IsBrand = 0
*/
CREATE PROCEDURE GetIsRecordReviewed
	@RecordID int,
	@IsBrand bit	
AS
BEGIN					
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	select count(1) Total
	from ContentCrawler.dbo.Record r WITH(NOLOCK)'
	IF @IsBrand = 1
	BEGIN
		set @SQLString = @SQLString + '
		inner join ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) on r.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 and fr.Sentiment is not null 
		where r.RecordID = @RecordID' 
	END
	ELSE
	BEGIN
		set @SQLString = @SQLString + ' 		
		where r.RecordID = @RecordID and ( r.Irrelevant = 1
		or exists (select * from ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) where r.RecordID = fr.RecordID and fr.ActiveIndicator = 1 and fr.IsSubRecord = 0 and fr.Sentiment is not null)
		or exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = r.RecordID and frt.IsSubRecord = 0 and frt.IsDeleted = 0) )'
	END
	SET @ParmDefinition = '
					@RecordID int'
	print @SQLString;

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID;
END
GO


if OBJECT_ID ( 'GetSubRecordSentimentCount', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSubRecordSentimentCount
GO
/*
* Description: 
* Params
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetSubRecordSentimentCount 
	@RecordID = 1
*/
CREATE PROCEDURE GetSubRecordSentimentCount
	@RecordID int
AS
BEGIN			
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	DECLARE @SQLStringTemp nvarchar(1024);
	
	SET @SQLString = '		
			select 
			ISNULL(sum(case when fr.Sentiment=1 THEN 1 ELSE 0 END),0) Positive,
			ISNULL(sum(case when fr.Sentiment=2 THEN 1 ELSE 0 END),0) Negative,
			ISNULL(sum(case when fr.Sentiment=3 THEN 1 ELSE 0 END),0) Neutral,
			ISNULL(sum(case when fr.Sentiment=4 THEN 1 ELSE 0 END),0) VeryPositive,
			ISNULL(sum(case when fr.Sentiment=5 THEN 1 ELSE 0 END),0) VeryNegative
			from ContentCrawler.dbo.FactRecord fr
			where fr.RecordID = @RecordID and fr.ActiveIndicator = 1
		'
	
	SET @ParmDefinition = '
				@RecordID int';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID;		
END
GO

if OBJECT_ID ( 'GetDeletedRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetDeletedRecords
GO
/*
* Description: get deleted records, for recovery function
* Params
* History
-------------------------------------------------------------
9/12/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetDeletedRecords 
	@Keyword = null,
	@Site = null,
	@Tag = null,
	@Owner = 'none',
	@StartDate = '4/11/2011',
	@EndDate = '12/20/2011',
	@Sentiment = 0,
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE GetDeletedRecords
	@Keyword varchar(1024),
	@Site varchar(1024),
	@Tag varchar(1024),
	@Owner varchar(512),
    @StartDate datetime,
    @EndDate datetime,
    @Sentiment int,
    @FromRecord int,
    @ToRecord int
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		KeywordGUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, KeywordGUID)  select KeywordID, GUID from Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END	;
	
	
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
				INSERT INTO @TempTag (TagID, TagGUID) select TagID, GUID from Tag where TagID = CAST(@TagID AS int)
			END
			SET @Tag = RIGHT(@Tag, LEN(@Tag) - @Pos)
			SET @Pos = CHARINDEX('','', @Tag, 1)

		END
	END;
		
	DECLARE @TempSentiment table
	(
		Sentiment smallint
	)
	
	IF @Sentiment = 0
	BEGIN
		insert into @TempSentiment (Sentiment) values (1),(2),(3)		
	END	 
	ELSE
	BEGIN
		insert into @TempSentiment (Sentiment) values (@Sentiment)		
	END;
		
	'
	
	SET @SQLString = @SQLString + ' with records as(
			select ROW_NUMBER() OVER(ORDER BY rd.PublishedDate DESC) AS ''RowNumber'', rd.RecordID, rd.RecordGUID, rd.Title, rd.URL, s.URL as ''SiteURL'', Convert(date, rd.PublishedDate) as ''PublishedDate'', fr.Sentiment 
			from (select * from ContentCrawler.dbo.Record where IsDeleted = 1 	
					and PublishedDate >= @StartDate and PublishedDate <= @EndDate) rd '
	IF @Keyword is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempKeyword kt on kt.KeywordGUID = rd.KeywordGUID '
	END;
	
	IF @Tag is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join (select distinct frt.RecordID from ContentCrawler.dbo.FactRecordTag frt inner join @TempTag tt on frt.TagGUID = tt.TagGUID) frt on rd.RecordID = frt.RecordID '
	END;		
			
	IF @Site is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
	END
	ELSE
	BEGIN
			SET @SQLString = @SQLString + '
			left join Site s on s.GUID = rd.SiteGUID '
	END;
	
	SET @SQLString = @SQLString + '
		left join (select distinct * from ContentCrawler.dbo.FactRecord where IsSubRecord = 0 and  ActiveIndicator = 1) fr on rd.RecordID = fr.RecordID '
	
	IF @Sentiment <> 0 --get all
	BEGIN
		SET @SQLString = @SQLString + '			
			inner join @TempSentiment ts on ts.Sentiment = fr.Sentiment '
	END;
				
		
	SET @SQLString = @SQLString + '	
	)		
	select RecordID, RecordGUID, Title, URL, SiteURL, PublishedDate, Sentiment, (select COUNT(*) from records) as ''TotalRecord''
	from records
	where RowNumber > @FromRecord and RowNumber <= @ToRecord';
	SET @ParmDefinition = '
				@Keyword varchar(1024),
				@Site varchar(1024),
				@Tag varchar(1024),
				@Owner varchar(512),
				@StartDate datetime,
				@EndDate datetime,
				@Sentiment int,
				@FromRecord int,
				@ToRecord int';
	print @SQLString;

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@Keyword,
						@Site,
						@Tag,
						@Owner,
						@StartDate,
						@EndDate,
						@Sentiment,
						@FromRecord,
						@ToRecord;			
END
GO

if OBJECT_ID ( 'GetContextRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetContextRecords
GO
/*
* Description: get records when drill down. Only records that tagged	
* History
-------------------------------------------------------------
8/19/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetContextRecords 
	@Keyword = '19',
	@Site = '1,2,3,4,5,38,47,49,51,54,55,61,62,63,64,66,71,75',
	@Channel = null,
	@Tag = null,
	@SenKeyword = null,
	@Owner = 'manual',	
	@StartDate = '10/14/2011',
	@EndDate = '10/15/2011',
	@Sentiment = 0,
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE GetContextRecords
	@Keyword varchar(1024),
	@Site varchar(1024),
	@Channel varchar(1024),
	@Tag varchar(1024),
	@SenKeyword varchar(1024),
	@Owner varchar(512),
    @StartDate datetime,
    @EndDate datetime,
    @Sentiment int,
    @FromRecord int,
    @ToRecord int
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	set @SQLString = '
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		KeywordGUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, KeywordGUID)  select KeywordID, GUID from Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END	;
	
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
				INSERT INTO @TempSite (SiteID, SiteGUID, URL) select SiteID, GUID, URL from Site where SiteID = CAST(@SiteID AS int)				
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	-- create temp channel id
	declare @ChannelGUID uniqueidentifier
	set @ChannelGUID= (select GUID from ContentAggregator.dbo.Channel where ChannelID = CAST(@Channel AS int))
	
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
				INSERT INTO @TempTag (TagID, TagGUID) select TagID, GUID from Tag where TagID = CAST(@TagID AS int)
			END
			SET @Tag = RIGHT(@Tag, LEN(@Tag) - @Pos)
			SET @Pos = CHARINDEX('','', @Tag, 1)

		END
	END;
	-- create temp sentiment keyword id
	DECLARE @TempSenKeyword table
	(
		SenKeyID int,
		SenKeyGUID uniqueidentifier
	)
	DECLARE @SenKeyID varchar(10)

	SET @SenKeyword = LTRIM(RTRIM(@SenKeyword))+ '',''
	SET @Pos = CHARINDEX('','', @SenKeyword, 1)

	IF REPLACE(@SenKeyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @SenKeyID = LTRIM(RTRIM(LEFT(@SenKeyword, @Pos - 1)))
			IF @SenKeyID <> ''''
			BEGIN
				INSERT INTO @TempSenKeyword (SenKeyID, SenKeyGUID) select SentimentKeywordID, GUID from SentimentKeyword where SentimentKeywordID = CAST(@SenKeyID AS int)
			END
			SET @SenKeyword = RIGHT(@SenKeyword, LEN(@SenKeyword) - @Pos)
			SET @Pos = CHARINDEX('','', @SenKeyword, 1)

		END
	END;	
		
	'
	
	SET @SQLString = @SQLString + ' with records as(
			select ROW_NUMBER() OVER(ORDER BY rd.PublishedDate DESC) AS ''RowNumber'', rd.RecordID, rd.RecordGUID, rd.Title, rd.URL, s.URL as ''SiteURL'', rd.Irrelevant, rd.IsFollowed, Convert(date, rd.PublishedDate) as ''PublishedDate'', fr.Sentiment, fr.Owner 
			from (select * from ContentCrawler.dbo.Record with(nolock) where (IsDeleted = 0 or IsDeleted is null) 	
					and PublishedDate >= @StartDate and PublishedDate <= @EndDate) rd '
	IF @Keyword is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempKeyword kt on kt.KeywordGUID = rd.KeywordGUID '
	END;
			
	IF @Tag is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join (select distinct frt.RecordID from ContentCrawler.dbo.FactRecordTag frt with(nolock) inner join @TempTag tt on frt.TagGUID = tt.TagGUID) frt on rd.RecordID = frt.RecordID '
	END;
		
	IF @SenKeyword is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join (select distinct rsk.RecordID from ContentCrawler.dbo.RecordSentimentKeyword rsk inner join @TempSenKeyword ts on rsk.SentimentKeywordGUID = ts.SenKeyGUID and rsk.IsSubRecord = 0 and ActiveIndicator = 1) rsk on rd.RecordID = rsk.RecordID '
	END;	
			
	IF @Site is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite s on s.SiteGUID = rd.SiteGUID '
	END
	ELSE
	BEGIN
			SET @SQLString = @SQLString + '
			left join Site s on s.GUID = rd.SiteGUID '
	END;
	
	IF @Sentiment = 0
	BEGIN
		SET @SQLString = @SQLString + '
			inner join (select distinct * from ContentCrawler.dbo.FactRecord with(nolock) where IsSubRecord = 0 and  ActiveIndicator = 1 and Owner=''manual'') fr on rd.RecordID = fr.RecordID '
	END
	ELSE
	BEGIN
		SET @SQLString = @SQLString + '
			inner join (select distinct RecordID, Sentiment, Owner 
				from ContentCrawler.dbo.FactRecord  with(nolock)
				where IsSubRecord = 0 and ActiveIndicator = 1 and Sentiment = @Sentiment and Owner=''manual''
				union all
				select distinct RecordID, CONVERT(smallint,-1) as ''Sentiment'', Owner 
				from ContentCrawler.dbo.FactRecord with(nolock) 
				where IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = @Sentiment and Owner=''manual'') fr on rd.RecordID = fr.RecordID '
	END;
	IF @Channel is NOT NULL
	BEGIN
		SET @SQLString = @SQLString + '
			where @ChannelGUID = rd.ChannelGUID '
	END;			
	SET @SQLString = @SQLString + '	
	)		
	select RecordID, RecordGUID, Title, URL, SiteURL, PublishedDate, Sentiment, Owner, ISNULL(Irrelevant, 0) Irrelevant, ISNULL(IsFollowed, 0) IsFollowed, (select COUNT(*) from records) as ''TotalRecord'', 0 Tags
	from records
	where RowNumber > @FromRecord and RowNumber <= @ToRecord';
	SET @ParmDefinition = '
				@Keyword varchar(1024),
				@Site varchar(1024),
				@Channel varchar(1024),
				@Tag varchar(1024),
				@SenKeyword varchar(1024),
				@StartDate datetime,
				@EndDate datetime,
				@Sentiment int,
				@FromRecord int,
				@ToRecord int';
	print @SQLString
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@Keyword,
						@Site,
						@Channel,
						@Tag,
						@SenKeyword,
						@StartDate,
						@EndDate,
						@Sentiment,
						@FromRecord,
						@ToRecord;			
END
GO

if OBJECT_ID ( 'GetRecord', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecord
GO
/*
* Description: get a record by backend (Content page)
* Params
	- Words: to find subrecords that contain words
* History
-------------------------------------------------------------
4/12/2011	|	Vu Do	|	Add
10/09/2011	|	Vu Do	|	Add IsFollowed column
-------------------------------------------------------------
* Sample:
EXEC GetRecord 
	@RecordID = 92843,
	@Owner = null,
	@Words = null
*/
CREATE PROCEDURE GetRecord
	@RecordID int  ,
	@Owner varchar(512),
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
	
	IF @Owner is not null
	BEGIN
		-- create a array from string
		SET @Owner = '''' + REPLACE(@Owner, ',',''',''') + ''''
		SET @SQLString = '
			select rd.URL, rd.Content, rd.Author , ISNULL(s.URL, '''') SiteURL, Convert(date, rd.PublishedDate) PublishedDate, fr.Sentiment, rd.IsFollowed, rd.Irrelevant ,
				(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Owner IN (' + @Owner + ')) NumOfSubRecords,
				(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 1 and Owner IN (' + @Owner + ')) NumOfPositiveSR,
				(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 2 and Owner IN (' + @Owner + ')) NumOfNegativeSR,
				(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 3 and Owner IN (' + @Owner + ')) NumOfNeutralSR,
				(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 4 and Owner IN (' + @Owner + ')) NumOfVeryPositiveSR,
				(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 5 and Owner IN (' + @Owner + ')) NumOfVeryNegativeSR
			from ContentCrawler.dbo.Record rd left join ContentCrawler.dbo.FactRecord fr on (rd.RecordID = fr.RecordID and fr.IsSubRecord = 0 and fr.ActiveIndicator = 1 )
			left join Site s on s.GUID = rd.SiteGUID
			where rd.RecordID = @RecordID'
	END
	ELSE
	BEGIN
		SET @SQLString = '
		select rd.URL, rd.Content, rd.Author, ISNULL(s.URL,'''') SiteURL, Convert(date, rd.PublishedDate) PublishedDate, fr.Sentiment, rd.IsFollowed, rd.Irrelevant ,
			(SELECT COUNT(*) from ContentCrawler.dbo.SubRecord sr where sr.RecordID = @RecordID and (sr.IsDeleted is null or sr.IsDeleted = 0) ' + @SQLStringTemp + ') NumOfSubRecords,
			(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 1) NumOfPositiveSR,
			(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 2) NumOfNegativeSR,
			(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 3) NumOfNeutralSR,
			(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 4) NumOfVeryPositiveSR,
			(SELECT COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = @RecordID and fr.IsSubRecord = 1 and ActiveIndicator = 1 and Sentiment = 5) NumOfVeryNegativeSR
		from ContentCrawler.dbo.Record rd left join ContentCrawler.dbo.FactRecord fr on (rd.RecordID = fr.RecordID and fr.IsSubRecord = 0 and fr.ActiveIndicator = 1)
		left join Site s on s.GUID = rd.SiteGUID
		where rd.RecordID = @RecordID'
	END

	SET @ParmDefinition = '
				@RecordID int  ,
				@Owner varchar(512)';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID,
					  	@Owner;		
END
GO

if OBJECT_ID ( 'GetRecordEarnedValues', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordEarnedValues
GO
/*
* Description: get values of record, compute if there is no value
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC GetRecordEarnedValues 
	@RecordID = 56521
*/
CREATE PROCEDURE GetRecordEarnedValues
	@RecordID int
AS
BEGIN			
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	DECLARE @SQLStringTemp nvarchar(1024);
	declare @score float, @impressionrate float
	declare @isdirty bit
	--get score
	set @score = (select score from ContentCrawler.dbo.FactRecordEmotion where RecordID = @RecordID)
	set @impressionrate = (select ImpressionRate from ContentCrawler.dbo.FactRecordEmotion where RecordID = @RecordID)
	set @isdirty = (select IsDirty from ContentCrawler.dbo.Record where RecordID = @RecordID)
	
	--compute score
	if @score is null or @impressionrate is null or @isdirty = 1
	begin
		declare @sitetype int, @noofcomment int, @noofcommentround int, @constant int, @constantcomment int
		set @sitetype = (select s.Type from ContentAggregator.dbo.Site s
						inner join ContentCrawler.dbo.Record r on s.GUID = r.SiteGUID and r.RecordID = @RecordID)
		
		set @noofcomment = (select COUNT(*) SubRecords from ContentCrawler.dbo.SubRecord sr where sr.RecordID = @RecordID) 
		set @noofcommentround = @noofcomment
		if @noofcomment = 0
		begin
			set @noofcommentround = 1
		end
		
		if @sitetype = 1 or @sitetype = 3 --news/blog
		begin
			set @constant = (select cf.Value from ContentAggregator.dbo.Config cf where cf.Name = 'CONSTANT_NEWS_ARTICLE')
			set @constantcomment = (select cf.Value from ContentAggregator.dbo.Config cf where cf.Name = 'CONSTANT_NEWS_COMMENT')
		end
		else if @sitetype = 5 --forums
		begin
			set @constant = (select cf.Value from ContentAggregator.dbo.Config cf where cf.Name = 'CONTSTANT_FORUM_INITIAL_POST')						
			set @constantcomment = (select cf.Value from ContentAggregator.dbo.Config cf where cf.Name = 'CONSTANT_FORUM_INITIAL_COMMENT')
		end
		else
		begin --sns
			declare @siteid int
			set @siteid = (select top 1 siteid from ContentAggregator.dbo.Site s
							inner join ContentCrawler.dbo.Record r on s.GUID = r.SiteGUID and r.RecordID = @RecordID)
			if @siteid = 6 --facebook
			begin
				set @constant = (select cf.Value from ContentAggregator.dbo.Config cf where cf.Name = 'CONTSTANT_FB_INITIAL_POST')
				set @constantcomment = (select cf.Value from ContentAggregator.dbo.Config cf where cf.Name = 'CONSTANT_FB_COMMENT')
			end
			else
			begin
				set @constant = 0
				set @constantcomment = 0
			end						
		end
		
		set @score = @constant * @noofcommentround
		set @impressionrate = @constant * 1 + @noofcomment * @constantcomment
		--insert a record if it is not existed
		if(@score is not null and @impressionrate is not null)
		begin
			if(select COUNT(*) from ContentCrawler.dbo.FactRecordEmotion where RecordID = @RecordID) = 0
			begin
				insert into ContentCrawler.dbo.FactRecordEmotion(RecordID, Score, ImpressionRate, IsDeleted, InsertedDate, UpdatedDate)
				values (@RecordID, @score, @impressionrate, 0, GETDATE(), GETDATE())
			end
			else
			begin
				--update score for record
				update ContentCrawler.dbo.FactRecordEmotion
				set Score = @score, ImpressionRate = @impressionrate
				where RecordID = @RecordID
			end
		end
	end	
	
	select @score Score, @impressionrate ImpressionRate
END
GO

if OBJECT_ID ( 'GetRecordSentimentKeywords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordSentimentKeywords
GO
/*
* Description: sentiment keyword 
* History
-------------------------------------------------------------
3/27/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetRecordSentimentKeywords 
	@RecordID = 1,
	@IsSubRecord = 0
*/
CREATE PROCEDURE GetRecordSentimentKeywords
	@RecordID int,
	@IsSubRecord bit	
AS
BEGIN		
	select rsk.RecordSentimentKeywordID, sk.SentimentGroupID, sk.SentimentKeywordID, sk.Word, sk.WordWithoutAccent, sk.Type, rsk.Total
	from SentimentKeyword sk, ContentCrawler.dbo.RecordSentimentKeyword rsk
	where rsk.RecordID = @RecordID and sk.GUID = rsk.SentimentKeywordGUID and rsk.ActiveIndicator = 1
END
GO

if OBJECT_ID ( 'GetRecordTags', 'P' ) IS NOT NULL
	DROP PROCEDURE GetRecordTags
GO
/*
* Description: get tags of record.
* History
-------------------------------------------------------------
7/27/2011	|	Vu Do	|	Add
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
	from Tag t, ContentCrawler.dbo.FactRecordTag frt	
	where t.GUID = frt.TagGUID and frt.RecordID = @RecordID and frt.IsSubRecord = @IsSubRecord and frt.IsDeleted = 0
	order by t.Word
END
GO

if OBJECT_ID ( 'GetSubRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSubRecords
GO
/*
* Description: Get sub records from FrontEnd (Content Page)
* History
-------------------------------------------------------------
5/15/2011	|	Vu Do	|	Add
5/16/2012	|			|	Add IsBrand, Reviewed
-------------------------------------------------------------
* Sample:
EXEC GetSubRecords 
	@RecordID = 96684,	
	@Words = '"tieng anh"',
	@Reviewed = '-1',
	@IsBrand = 1,
	@FromRecord = 0,
	@ToRecord = 50
*/
CREATE PROCEDURE GetSubRecords
	@RecordID int,	
	@Words nvarchar(512), 
	@Reviewed varchar(128),  
	@IsBrand bit,     
    @FromRecord int,
    @ToRecord int
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
			with subrecords as(
				select ROW_NUMBER() OVER(ORDER BY sr.PublishedDate ASC) AS ''RowNumber'', sr.SubRecordID, sr.Content, sr.Author, sr.PublishedDate, sr.Irrelevant, sr.URL, fr.Sentiment, fr.Owner
				from ContentCrawler.dbo.SubRecord sr WITH(NOLOCK)
				left join ContentCrawler.dbo.FactRecord fr WITH(NOLOCK) on ( sr.SubRecordID = fr.SubRecordID and fr.IsSubRecord = 1 and fr.ActiveIndicator = 1 )'
		
	SET @SQLString = @SQLString + ' 
				where sr.RecordID = @RecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) ' + @SQLStringTemp
	IF @Reviewed = 'reviewed'
	BEGIN		
		IF @IsBrand = 1
		BEGIN
			SET @SQLString = @SQLString + ' 
			and fr.Sentiment is not null '	
		END
		ELSE
		BEGIN
			SET @SQLString = @SQLString + ' 
			and (sr.Irrelevant = 1 or fr.Sentiment is not null
			or exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = sr.SubRecordID and frt.IsSubRecord = 1 and frt.IsDeleted = 0))'	
		END
		
	END	
	ELSE IF @Reviewed = 'unreviewed'
	BEGIN		
		IF @IsBrand = 1
		BEGIN
			SET @SQLString = @SQLString + ' 
			and fr.Sentiment is null '
		END
		ELSE
		BEGIN
			SET @SQLString = @SQLString + ' 
			and ((sr.Irrelevant is NULL or sr.Irrelevant = 0) and (fr.Sentiment is null )  
			and not exists (select * from ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) where frt.RecordID = sr.SubRecordID and frt.IsSubRecord = 1 and frt.IsDeleted = 0))'		
		END			
	END
	SET @SQLString = @SQLString + ')
			select SubRecordID, Content, Author, PublishedDate,Irrelevant, URL, Sentiment, Owner, (select COUNT(*) from subrecords) as ''TotalRecord'',
			ISNULL((select distinct word + '';'' as [data()] from ContentAggregator.dbo.Tag t WITH(NOLOCK) inner join ContentCrawler.dbo.FactRecordTag frt WITH(NOLOCK) on (frt.RecordID = subrecords.SubRecordID and frt.IsSubRecord = 1 and frt.IsDeleted = 0) and frt.TagGUID = t.GUID  for xml path('''')),'''') as Tags
			from subrecords
			where RowNumber > @FromRecord and RowNumber <= @ToRecord
			order by rownumber'	
	
	SET @ParmDefinition = '
				@RecordID int,				     
				@FromRecord int,
				@ToRecord int';
	PRINT @SQLString
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID,					  	
					  	@FromRecord,
					  	@ToRecord;	
END
GO


if OBJECT_ID ( 'GetContextSubRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE GetContextSubRecords
GO
/*
* Description: Get sub records in contextual click
	@Owner: who set sentiment - NULL, manual, auto
	@Sentiment: filtered by sentiment
* History
-------------------------------------------------------------
5/15/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetContextSubRecords 
	@RecordID = 91961,
	@Owner = 'manual',
	@Sentiment = 1
*/
CREATE PROCEDURE GetContextSubRecords
	@RecordID int,
	@Owner varchar(512),
	@Sentiment int,
	@StartDate datetime,
	@EndDate datetime
AS
BEGIN					
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '			
			select sr.SubRecordID, sr.Content, sr.Author, sr.PublishedDate, sr.URL, fr.Sentiment, fr.Owner
			from ContentCrawler.dbo.SubRecord sr 
			inner join ContentCrawler.dbo.FactRecord fr on (fr.IsSubRecord = 1 and sr.SubRecordID = fr.SubRecordID and fr.ActiveIndicator = 1'
			
	IF @Sentiment is not null
	BEGIN
		SET @SQLString = @SQLString + ' and fr.Sentiment = @Sentiment '
	END
	
	IF @Owner is NOT NULL
	BEGIN
		-- create a array from string	
		SET @Owner = '''' + REPLACE(@Owner, ',',''',''') + ''''
		SET @SQLString = @SQLString + ' and fr.Owner IN (' + @Owner + ') '			
	END
	
	SET @SQLString = @SQLString + ')
			where sr.RecordID = @RecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null) and sr.PublishedDate >= @StartDate and sr.PublishedDate <= @EndDate';
	SET @SQLString = @SQLString + ' order by sr.PublishedDate asc '
	print @SQLString
	SET @ParmDefinition = '
				@RecordID int,
				@Owner varchar(512),
				@Sentiment int,
				@StartDate datetime,
				@EndDate datetime';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  	@RecordID,
					  	@Owner,
					  	@Sentiment,
					  	@StartDate,
					  	@EndDate;	
END
GO


if OBJECT_ID ( 'GetTotalTagsByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalTagsByTime
GO
/*
* Description: 
* History
-------------------------------------------------------------
4/25/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSentimentOfTagsByTime 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/30/2011'
*/
CREATE PROCEDURE GetTotalTagsByTime
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
			
	select leftside.Date, leftside.TagID, leftside.Word, ISNULL(rightside.Total,0) 'Total'
	from(
		select distinct dt.date, dt.DimTimeID, t.TagID, t.Word
		from DimTime dt, KeywordGroupKeyword kgk join @TempKeywordID tk on kgk.KeywordID = tk.KeywordID, tag t, TagGroupKeywordGroup tgkg
		where t.TagGroupID = tgkg.TagGroupID and kgk.KeywordGroupID = tgkg.KeywordGroupID and dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID) leftside
	left join
		(SELECT fktr.DimTimeID, fktr.TagID, SUM(fktr.Total) 'Total'
		FROM FactKeywordTagRecord fktr join @TempKeywordID tk on fktr.KeywordID = tk.KeywordID
		where fktr.DimTimeID >= @StartTimeID and fktr.DimTimeID <= @EndTimeID
		group by fktr.DimTimeID, fktr.TagID) rightside
	On (leftside.DimTimeID = rightside.DimTimeID and leftside.TagID = rightside.TagID)

END
GO


if OBJECT_ID ( 'GetTotalTagsByKeyword', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalTagsByKeyword
GO
/*
* Description: get tag and its count for a keyword.
* History
-------------------------------------------------------------
5/3/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalTagsByKeyword 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/20/2011'
*/
CREATE PROCEDURE GetTotalTagsByKeyword
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END				
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)

	select leftside.TagID, leftside.Name, leftside.KeywordID, leftside.Word, ISNULL(rightside.Total, 0) 'Total' from 
	(select t.TagID, t.Word 'Name', kw.KeywordID, kw.Word from Tag t, Keyword kw join @TempKeywordID tk on kw.KeywordID = tk.KeywordID) leftside
	left join 
	(
		SELECT fktr.TagID, fktr.KeywordID, SUM(fktr.Total) 'Total'
		FROM FactKeywordTagRecord fktr join @TempKeywordID tk on fktr.KeywordID = tk.KeywordID
		where fktr.DimTimeID >= @StartTimeID and fktr.DimTimeID <= @EndTimeID
		group by fktr.TagID, fktr.KeywordID
	) rightside
	on leftside.TagID = rightside.TagID and leftside.KeywordID = rightside.KeywordID			
END
GO


if OBJECT_ID ( 'GetTotalTags', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalTags
GO
/*
* Description: get tag and its count within a period of time
* History
-------------------------------------------------------------
5/3/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalTags 
	@Keyword = '19,20',
	@Site = '7,15',
	@StartDate = '8/1/2011',
	@EndDate = '9/20/2011'
*/
CREATE PROCEDURE GetTotalTags
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END;
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)

	SELECT fktr.TagID, t.Word, SUM(fktr.Total) Total
	FROM FactKeywordTagRecord fktr '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on fktr.SiteID = ts.SiteID '
	END
	SET @SQLString = @SQLString + '
		inner join @TempKeyword tk on fktr.KeywordID = tk.KeywordID
		left join Tag t on fktr.TagID = t.TagID
		where fktr.DimTimeID >= @StartTimeID and fktr.DimTimeID <= @EndTimeID and t.word is not null
		group by fktr.TagID, t.Word
		order by Total desc '

	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;
END
GO

if OBJECT_ID ( 'GetSentimentOfCategory', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSentimentOfCategory
GO
/*
* Description: get category and its sentiment
* History
-------------------------------------------------------------
9/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSentimentOfCategory 
	@Keyword = '1,2,3',
	@Site = null,
	@StartDate = '4/1/2011',
	@EndDate = '10/20/2011'
*/
CREATE PROCEDURE GetSentimentOfCategory
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END;
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate);
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate);

		
	with cte as(
		select ct.CategoryID, ft.Sentiment, COUNT(*) as SentimentCount
		from ContentCrawler.dbo.FactRecordTag frt
		inner join ContentCrawler.dbo.Record r on frt.RecordID = r.RecordID and (r.IsDeleted = 0 or r.IsDeleted is null) and r.PublishedDate >= @StartDate and r.PublishedDate <= @EndDate '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on r.SiteGUID = ts.GUID '
	END
	SET @SQLString = @SQLString + '
		inner join @TempKeyword tk on r.KeywordGUID = tk.GUID
		inner join ContentCrawler.dbo.FactRecord ft on frt.RecordID = ft.RecordID and ft.ActiveIndicator = 1
		inner join ContentAggregator.dbo.Tag t on frt.TagGUID = t.GUID
		inner join CategoryTag ct on t.TagID = ct.TagID
		where frt.IsDeleted = 0
		group by ct.CategoryID, ft.Sentiment)

	select distinct c.CategoryID, c.Name
	,(select SUM(cte.SentimentCount) from cte where cte.CategoryID = c1.CategoryID and cte.Sentiment = 1) Positive
	,(select SUM(cte.SentimentCount) from cte where cte.CategoryID = c1.CategoryID and cte.Sentiment = 2) Negative
	,(select SUM(cte.SentimentCount) from cte where cte.CategoryID = c1.CategoryID and cte.Sentiment = 3) Neutral
	,(select SUM(cte.SentimentCount) from cte where cte.CategoryID = c1.CategoryID) Total
	from cte c1
	inner join Category c on c1.CategoryID = c.CategoryID and (c.IsDeleted = 0 or c.IsDeleted is null)
	order by Total desc '
	
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;
END
GO


if OBJECT_ID ( 'GetSentimentOfSiteCategory', 'P' ) IS NOT NULL
	DROP PROCEDURE GetSentimentOfSiteCategory
GO
/*
* Description: get category and its sentiment
* History
-------------------------------------------------------------
9/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetSentimentOfSiteCategory 
	@Keyword = '1,2,3',
	@Site = null,
	@StartDate = '4/1/2011',
	@EndDate = '4/2/2011'
*/
CREATE PROCEDURE GetSentimentOfSiteCategory
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END;
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate);
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate);

	select sc.SiteCategoryID, sc.Name, SUM(fkr.Total) Total, SUM(fkr.VeryPositive) VeryPositive,  SUM(fkr.Positive) Positive, SUM(fkr.Neutral) Neutral, SUM(fkr.Negative) Negative, SUM(fkr.VeryNegative) VeryNegative
	from FactKeywordRecord fkr
	inner join @TempKeyword tk on fkr.KeywordID = tk.KeywordID
	inner join ContentAggregator.dbo.Site s on fkr.SiteID = s.SiteID '
	
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on s.SiteID = ts.SiteID '
	END
	SET @SQLString = @SQLString + ' 
	inner join ContentAggregator.dbo.SiteCategory sc on s.SiteCategoryID = sc.SiteCategoryID
	where fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID
	group by sc.SiteCategoryID, sc.Name '
				
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;
END
GO

if OBJECT_ID ( 'GetTotalCategoryByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalCategoryByTime
GO
/*
* Description: get channel and its count by time
* History
-------------------------------------------------------------
9/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalCategoryByTime 
	@Keyword = '1,2,3,4,19,20',
	@Site = null,
	@StartDate = '4/1/2011',
	@EndDate = '4/20/2011'
*/
CREATE PROCEDURE GetTotalCategoryByTime
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '								
	SET NOCOUNT ON	
	-- create temp keyword	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END		
	
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate);
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate);
	'
	SET @SQLString = @SQLString + '	
		select dt.DimTimeID, dt.Date, c.CategoryID, c.Name, SUM(fktr.Total) Total
		from ContentAggregator.dbo.DimTime dt
		inner join ContentAggregator.dbo.FactKeywordTagRecord fktr on dt.DimTimeID = fktr.DimTimeID '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on fktr.SiteID = ts.SiteID '
	END
	
	SET @SQLString = @SQLString + '
		inner join @TempKeyword tk on fktr.KeywordID = tk.KeywordID
		inner join ContentAggregator.dbo.CategoryTag ct on fktr.TagID = ct.TagID
		left join ContentAggregator.dbo.Category c on ct.CategoryID = c.CategoryID
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
		group by dt.DimTimeID, dt.Date, c.CategoryID, c.Name
		order by dt.DimTimeID '
	
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;	
END
GO


if OBJECT_ID ( 'GetTotalSiteCategoryByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalSiteCategoryByTime
GO
/*
* Description: get channel and its count by time
* History
-------------------------------------------------------------
9/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalSiteCategoryByTime 
	@Keyword = '19',
	@Site = '12,23',
	@StartDate = '7/22/2011',
	@EndDate = '10/20/2011'
*/
CREATE PROCEDURE GetTotalSiteCategoryByTime
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '								
	SET NOCOUNT ON	
	-- create temp keyword	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END		
	
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier,
		SiteCategoryID int
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
				INSERT INTO @TempSite(SiteID, GUID, SiteCategoryID) select SiteID, guid, SiteCategoryID from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate);
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate);
	'
	SET @SQLString = @SQLString + '	
		select leftside.DimTimeID,leftside.Date, leftside.SiteCategoryID, leftside.Name, ISNULL(rightside.Total, 0) Total
	from (select dt.DimTimeID, dt.date, sc.SiteCategoryID, sc.Name
		from ContentAggregator.dbo.DimTime dt, ContentAggregator.dbo.SiteCategory sc
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID) leftside
	left join
		(select fkr.DimTimeID, sc.SiteCategoryID, SUM(fkr.Total) Total
		from ContentAggregator.dbo.FactKeywordRecord fkr
		inner join @TempKeyword tk on fkr.KeywordID = tk.KeywordID '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on fkr.SiteID = ts.SiteID '
	END
	SET @SQLString = @SQLString + '
		inner join ContentAggregator.dbo.Site s on fkr.SiteID = s.SiteID
		inner join ContentAggregator.dbo.SiteCategory sc on s.SiteCategoryID = sc.SiteCategoryID
		where fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID
		group by fkr.DimTimeID,sc.SiteCategoryID) rightside
	on leftside.DimTimeID = rightside.DimTimeID and leftside.SiteCategoryID = rightside.SiteCategoryID '
	
	
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;	
END
GO

if OBJECT_ID ( 'GetTotalChannels', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalChannels
GO
/*
* Description: get channel and its count
* History
-------------------------------------------------------------
9/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalChannels 
	@Keyword = '1,2,3,19,20',
	@Site = null,
	@StartDate = '4/1/2011',
	@EndDate = '9/20/2011'
*/
CREATE PROCEDURE GetTotalChannels
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '								
	SET NOCOUNT ON	
	-- create temp keyword	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END		
	
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate);
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate);
	'
	SET @SQLString = @SQLString + '	
		select c.ChannelID, c.Name, SUM(fkr.Total) Total
		from ContentAggregator.dbo.FactKeywordRecord fkr '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on fkr.SiteID = ts.SiteID '
	END
	
	SET @SQLString = @SQLString + '
		inner join @TempKeyword tk on fkr.KeywordID = tk.KeywordID 
		inner join ContentAggregator.dbo.Channel c on fkr.ChannelID = c.ChannelID
		where fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID
		group by c.ChannelID, c.Name '
	
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;	
END
GO

if OBJECT_ID ( 'GetTotalChannelsByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalChannelsByTime
GO
/*
* Description: get channel and its count by time
* History
-------------------------------------------------------------
9/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalChannelsByTime 
	@Keyword = '19',
	@Site = '1,2,3,4,5,14,38,47,48,49,51,54,55,60,61,62,63,64,66,69,71,72,75',
	@StartDate = '2011-10-11',
	@EndDate = '2011-10-11'
*/
CREATE PROCEDURE GetTotalChannelsByTime
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '								
	SET NOCOUNT ON	
	-- create temp keyword	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END		
	
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate);
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate);
	'		
	SET @SQLString = @SQLString + '	
		select leftside.DimTimeID,leftside.Date, leftside.ChannelID, leftside.Name, ISNULL(rightside.Total, 0) Total
	from (select dt.DimTimeID, dt.date, c.ChannelID, c.Name
		from ContentAggregator.dbo.DimTime dt, ContentAggregator.dbo.Channel c
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID) leftside
	left join
		(select fkr.DimTimeID, c.ChannelID, SUM(fkr.Total) Total
		from ContentAggregator.dbo.FactKeywordRecord fkr
		inner join @TempKeyword tk on fkr.KeywordID = tk.KeywordID '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on fkr.SiteID = ts.SiteID '
	END
	SET @SQLString = @SQLString + '
		inner join ContentAggregator.dbo.Channel c on fkr.ChannelID = c.ChannelID
		where fkr.DimTimeID >= @StartTimeID and fkr.DimTimeID <= @EndTimeID
		group by fkr.DimTimeID, c.ChannelID) rightside
	on leftside.DimTimeID = rightside.DimTimeID and leftside.ChannelID = rightside.ChannelID '
	
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;	
END
GO

if OBJECT_ID ( 'GetTotalSites', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalSites
GO
/*
* Description: get site and its count
* History
-------------------------------------------------------------
9/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalSites 
	@Keyword = '1,2,3',
	@Site = '1,3,4',
	@StartDate = '4/1/2011',
	@EndDate = '4/20/2011'
*/
CREATE PROCEDURE GetTotalSites
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '								
	SET NOCOUNT ON	
	-- create temp keyword	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END		
	
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate);
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate);
	'
	SET @SQLString = @SQLString + '	
		select s.SiteID, s.Name, Sum(r.Total) Total
		from ContentAggregator.dbo.FactKeywordRecord r '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on r.SiteID = ts.SiteID '
	END
	
	SET @SQLString = @SQLString + '	
		inner join ContentAggregator.dbo.Site s on r.SiteID = s.SiteID
		inner join @TempKeyword tk on r.KeywordID = tk.KeywordID and r.DimTimeID >= @StartTimeID and r.DimTimeID <= @EndTimeID		
		group by s.SiteID, s.Name '
	
	print @SQLString
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;	
END
GO


if OBJECT_ID ( 'GetTotalRecordsByTime', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTotalRecordsByTime
GO
/*
* Description: get site and its count
* History
-------------------------------------------------------------
9/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTotalRecordsByTime 
	@Keyword = '19',
	@Site = null,
	@StartDate = '9/1/2011',
	@EndDate = '12/20/2011'
*/
CREATE PROCEDURE GetTotalRecordsByTime
	@Keyword varchar(1024),
	@Site varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	DECLARE @SQLString nvarchar(max);
	DECLARE @ParmDefinition nvarchar(1024);	
	
	SET @SQLString = '								
	SET NOCOUNT ON	
	-- create temp keyword	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		GUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ '',''
	SET @Pos = CHARINDEX('','', @Keyword, 1)

	IF REPLACE(@Keyword, '','', '''') <> ''''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, GUID) select keywordID, guid from ContentAggregator.dbo.Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX('','', @Keyword, 1)

		END
	END		
	
	-- create temp keyword id	
	DECLARE @TempSite table
	(
		SiteID int,
		GUID uniqueidentifier
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
				INSERT INTO @TempSite(SiteID, GUID) select SiteID, guid from ContentAggregator.dbo.Site where SiteID = CAST(@SiteID AS int)
			END
			SET @Site = RIGHT(@Site, LEN(@Site) - @Pos)
			SET @Pos = CHARINDEX('','', @Site, 1)

		END
	END;
	
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate);
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate);
	'		
	SET @SQLString = @SQLString + '
		select leftside.DimTimeID, leftside.Date, ISNULL(rightside.Total, 0) Total
		from
			(select dt.DimTimeID, dt.Date
			from DimTime dt
			where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID ) leftside
		left join	
			(select fkr.DimTimeID, SUM(fkr.Total) Total
			from ContentAggregator.dbo.FactKeywordRecord fkr with(nolock)			
			inner join @TempKeyword tk on fkr.KeywordID = tk.KeywordID '
	IF @Site is not null
	BEGIN
		SET @SQLString = @SQLString + '
			inner join @TempSite ts on fkr.SiteID = ts.SiteID '
	END
	SET @SQLString = @SQLString + '		
			where fkr.DimTimeID >= @StartTimeID  and fkr.DimTimeID <= @EndTimeID		
			group by fkr.DimTimeID) rightside 
		on leftside.DimTimeID = rightside.DimTimeID'
	
	print @SQLString
	SET @ParmDefinition = '
			@Keyword varchar(1024),
			@Site varchar(1024),
			@StartDate date,
			@EndDate date';
	
	EXECUTE sp_executesql @SQLString, @ParmDefinition,
					  		@Keyword,
							@Site,
							@StartDate ,
							@EndDate ;	
END
GO

if OBJECT_ID ( 'GetGeneralMentions', 'P' ) IS NOT NULL
	DROP PROCEDURE GetGeneralMentions
GO
/*
* Description: get sentiment keyword and it's sentiment count.
* Parameters:
** @Type: negative, postive. Type of sentiment keyword
* History
-------------------------------------------------------------
5/1/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetGeneralMentions 
	@Keyword = '1,2,3',
	@Type = 1,
	@StartDate = '4/1/2011',
	@EndDate = '4/20/2011'
*/
CREATE PROCEDURE GetGeneralMentions
	@Keyword varchar(1024),
	@Type int,
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END			
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
	
	select sk.SentimentKeywordID, sk.Word, sum(fsk.Total) 'Total'
	from FactSentimentKeyword fsk, @TempKeywordID tk, SentimentKeyword sk
	where fsk.KeywordID = tk.KeywordID and sk.Type = @Type and fsk.SentimentKeywordID = sk.SentimentKeywordID and fsk.DimTimeID >= @StartTimeID and fsk.DimTimeID <= @EndTimeID
	group by sk.SentimentKeywordID, sk.Word
	order by Total desc
END
GO

if OBJECT_ID ( 'GetChannelGrowth', 'P' ) IS NOT NULL
	DROP PROCEDURE GetChannelGrowth
GO
/*
* Description: get channel growth
* Parameters:
* History
-------------------------------------------------------------
5/1/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetChannelGrowth 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/20/2011'
*/
CREATE PROCEDURE GetChannelGrowth
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END			
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
	
	select mainleftsite.Date, mainleftsite.Growth, SUM(mainrightsite.Growth) AS Accummulate
	from (select dt.DimTimeID, dt.Date, ISNULL(mainData.Growth,0) Growth
			from DimTime dt 
				left join  (select leftsite.DimTimeID, COUNT(*) as Growth
						from (select SiteID, min(DimTimeID) as DimTimeID
									from dbo.FactKeywordRecord fkr left join @TempKeywordID tk on fkr.KeywordID = tk.KeywordID
									where tk.KeywordID is not null and DimTimeID <= @EndTimeID and DimTimeID >= @StartTimeID
									group by siteid) leftsite
						group by leftsite.DimTimeID) mainData on mainData.DimTimeID = dt.DimTimeID
			where dt.DimTimeID between @StartTimeID and @EndTimeID) as mainleftsite
		cross join (select rightsite.DimTimeID, COUNT(*) as Growth
							from (select SiteID, min(DimTimeID) as DimTimeID
										from dbo.FactKeywordRecord fkr left join @TempKeywordID tk on fkr.KeywordID = tk.KeywordID
										where tk.KeywordID is not null and DimTimeID <= @EndTimeID and DimTimeID >= @StartTimeID
										group by siteid) rightsite
							group by rightsite.DimTimeID) as mainrightsite
	where mainleftsite.DimTimeID >= mainrightsite.DimTimeID
	group by mainleftsite.Date, mainleftsite.Growth
	order by mainleftsite.Date asc
END
GO

if OBJECT_ID ( 'GetVoiceGrowth', 'P' ) IS NOT NULL
	DROP PROCEDURE GetVoiceGrowth
GO
/*
* Description: get voice growth
* Parameters:
* History
-------------------------------------------------------------
5/1/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetVoiceGrowth 
	@Keyword = '1,2,3',
	@StartDate = '4/1/2011',
	@EndDate = '4/20/2011'
*/
CREATE PROCEDURE GetVoiceGrowth
	@Keyword varchar(1024),
    @StartDate date,
    @EndDate date
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeywordID table
	(
		KeywordID int
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeywordID (KeywordID) VALUES (CAST(@KeywordID AS int)) --Use Appropriate conversion
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END					
	
	declare @StartTimeID int
	declare @EndTimeID int
	
	set @StartTimeID = (select DimTimeID from DimTime where [DATE] = @StartDate)
	set @EndTimeID = (select DimTimeID from DimTime where [DATE] = @EndDate)
	
	select mainleftauthor.Date, mainleftauthor.Growth, SUM(mainrightauthor.Growth) AS Accummulate
	from (select dt.date, dt.DimTimeID, ISNULL(mainData.Growth, 0) as Growth
		from DimTime dt 
			left join  (select leftauthor.dimtimeid, COUNT(*) as Growth
					from (select Author, min(DimTimeID) as DimTimeID
								from FactKeywordAuthor left join @TempKeywordID temp on FactKeywordAuthor.KeywordID = temp.KeywordID
								where temp.KeywordID is not null and DimTimeID <= @EndTimeID and DimTimeID >= @StartTimeID
								group by Author) leftauthor
					group by leftauthor.dimtimeid) mainData on mainData.DimTimeID = dt.DimTimeID
		where dt.DimTimeID between @StartTimeID and @EndTimeID) as mainleftauthor
	cross join (select rightauthor.dimtimeid, COUNT(*) as Growth
						from (select Author, min(DimTimeID) as DimTimeID
									from FactKeywordAuthor left join @TempKeywordID temp on FactKeywordAuthor.KeywordID = temp.KeywordID
									where temp.KeywordID is not null and DimTimeID <= @EndTimeID and DimTimeID >= @StartTimeID
									group by Author) rightauthor
						group by rightauthor.dimtimeid) as mainrightauthor
	where mainleftauthor.DimTimeID >= mainrightauthor.DimTimeID
	group by mainleftauthor.Date, mainleftauthor.Growth
	order by mainleftauthor.Date asc
END
GO

if OBJECT_ID ( 'GetHotTopics', 'P' ) IS NOT NULL
	DROP PROCEDURE GetHotTopics
GO
/*
* Description: get records that have the most comment
* Parameters:
* Columns
	NumOfComments: number of subrecord of this record
	NumOfAuthors:
	Tags: list of tag of this record
* History
-------------------------------------------------------------
8/17/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetHotTopics 
	@StartDate = '1/1/2011',
	@EndDate = '10/20/2011',
	@FromRecord =0,
    @ToRecord =50
*/
CREATE PROCEDURE GetHotTopics
    @StartDate date,
    @EndDate date,
    @FromRecord int,
    @ToRecord int
AS
BEGIN
	with hottopics as(
		select ROW_NUMBER() OVER(order by COUNT(sr.SubRecordID) desc) AS 'RowNumber', r.RecordID, r.Title, r.URL, r.PublishedDate, s.URL as SiteURL, COUNT(sr.SubRecordID) NoOfComments, COUNT(distinct sr.Author) as NoOfAuthors
		from DataHunter.dbo.Record r 
		left join DataHunter.dbo.SubRecord sr on r.RecordID = sr.RecordID
		left join ContentAggregator.dbo.Site s on r.SiteGUID = s.GUID		
		where r.PublishedDate >= @StartDate and r.PublishedDate <= @EndDate and (r.IsDeleted = 0 or r.IsDeleted is null)
		group by r.RecordID, r.Title, r.URL, r.PublishedDate, s.URL
	)
	select tp.RowNumber, tp.RecordID, tp.Title, tp.URL, tp.NoOfComments, tp.NoOfAuthors, tp.PublishedDate, tp.SiteURL, (select COUNT(1) from hottopics) as TotalRecord,
		ISNULL((select distinct t.word + ',' as [data()] 
				from DataHunter.dbo.FactRecordTag frt
				inner join ContentAggregator.dbo.Tag t on frt.TagGUID = t.GUID
				where frt.RecordID = tp.RecordID
				for xml path('')),'') Tags,
		ISNULL((select distinct c.Name + ',' as [data()] 
				from DataHunter.dbo.FactRecordTag frt
				inner join ContentAggregator.dbo.Tag t on frt.TagGUID = t.GUID
				inner join ContentAggregator.dbo.CategoryTag ct on t.TagID = ct.TagID
				inner join ContentAggregator.dbo.Category c on ct.CategoryID = c.CategoryID and c.IsDeleted = 0
				where frt.RecordID = tp.RecordID
				for xml path('')),'') Categories
	from hottopics tp
	where RowNumber > @FromRecord and RowNumber <= @ToRecord		
END
GO


if OBJECT_ID ( 'GetTagCloud', 'P' ) IS NOT NULL
	DROP PROCEDURE GetTagCloud
GO
/*
* Description: get data for tag cloud
* Parameters:
	TagGroup: a string contain many taggroup id
* History
-------------------------------------------------------------
8/20/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetTagCloud
	@Keyword = '1,2,3,4,5,6,7',
	@TagGroup = '1',
	@StartDate = '4/1/2011',
	@EndDate = '7/20/2011'
*/
CREATE PROCEDURE GetTagCloud
	@Keyword varchar(1024),
    @TagGroup varchar(512),
    @StartDate date,
    @EndDate date  
AS
BEGIN
	SET NOCOUNT ON
	-- create temp keyword id	
	DECLARE @TempKeyword table
	(
		KeywordID int,
		KeywordGUID uniqueidentifier
	)
	DECLARE @KeywordID varchar(10), @Pos int

	SET @Keyword = LTRIM(RTRIM(@Keyword))+ ','
	SET @Pos = CHARINDEX(',', @Keyword, 1)

	IF REPLACE(@Keyword, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @KeywordID = LTRIM(RTRIM(LEFT(@Keyword, @Pos - 1)))
			IF @KeywordID <> ''
			BEGIN
				INSERT INTO @TempKeyword (KeywordID, KeywordGUID)  select KeywordID, GUID from Keyword where KeywordID = CAST(@KeywordID AS int)
			END
			SET @Keyword = RIGHT(@Keyword, LEN(@Keyword) - @Pos)
			SET @Pos = CHARINDEX(',', @Keyword, 1)

		END
	END	;	
	
	DECLARE @TempTagGroupID table
	(
		TagGroupID int
	)
	DECLARE @TagGroupID varchar(10)

	SET @TagGroup = LTRIM(RTRIM(@TagGroup))+ ','
	SET @Pos = CHARINDEX(',', @TagGroup, 1)

	IF REPLACE(@TagGroup, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @TagGroupID = LTRIM(RTRIM(LEFT(@TagGroup, @Pos - 1)))
			IF @TagGroupID <> ''
			BEGIN
				INSERT INTO @TempTagGroupID (TagGroupID) VALUES (CAST(@TagGroupID AS int))
			END
			SET @TagGroup = RIGHT(@TagGroup, LEN(@TagGroup) - @Pos)
			SET @Pos = CHARINDEX(',', @TagGroup, 1)

		END
	END	
	
	select t.TagID, t.Word, COUNT(r.RecordID) 'Weight'
	from Tag t
	inner join @TempTagGroupID ttg on t.TagGroupID = ttg.TagGroupID
	inner join ContentCrawler.dbo.FactRecordTag frt on t.GUID = frt.TagGUID
	inner join ContentCrawler.dbo.Record r on frt.RecordID = r.RecordID and r.PublishedDate >= @StartDate and r.PublishedDate <= @EndDate	
	inner join @TempKeyword tk on r.KeywordGUID = tk.KeywordGUID
	group by t.TagID, t.Word		
END


if OBJECT_ID ( 'GetFollowingTopics', 'P' ) IS NOT NULL
	DROP PROCEDURE GetFollowingTopics
GO
/*
* Description: get records that their IsFollowed is true
* Parameters:
	
* History
-------------------------------------------------------------
10/09/2011	|	Vu Do	|	Add
-------------------------------------------------------------
* Sample:
EXEC GetFollowingTopics
	@Keyword = '1',	
	@StartDate = '4/1/2011',
	@EndDate = '11/20/2011'
*/
CREATE PROCEDURE GetFollowingTopics
	@Keyword varchar(1024),    
    @StartDate date,
    @EndDate date  
AS
BEGIN
	SET NOCOUNT ON;
	declare @keywordGUID uniqueidentifier
	set @keywordGUID = (select GUID from ContentAggregator.dbo.Keyword where KeywordID = @Keyword)
	
	select r.RecordID, r.Title, r.URL,
	(select COUNT(*) from ContentCrawler.dbo.SubRecord sr where sr.RecordID = r.RecordID and (sr.IsDeleted = 0 or sr.IsDeleted is null)) NoOfNewComments,
	(select COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = r.RecordID and fr.Sentiment = 4 and fr.ActiveIndicator = 1) NoOfVeryPositive,
	(select COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = r.RecordID and fr.Sentiment = 1 and fr.ActiveIndicator = 1) NoOfPositive,
	(select COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = r.RecordID and fr.Sentiment = 3 and fr.ActiveIndicator = 1) NoOfNeutral,
	(select COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = r.RecordID and fr.Sentiment = 2 and fr.ActiveIndicator = 1) NoOfNegative,
	(select COUNT(*) from ContentCrawler.dbo.FactRecord fr where fr.RecordID = r.RecordID and fr.Sentiment = 5 and fr.ActiveIndicator = 1) NoOfVeryNegative
	from ContentCrawler.dbo.Record r
	where r.IsFollowed = 1 and r.KeywordGUID = @keywordGUID
	
END