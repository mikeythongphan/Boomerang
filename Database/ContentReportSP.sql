/*
	contain store procedures of backend report
*/

if OBJECT_ID ( 'ContentReport_GetRecordsByDate', 'P' ) IS NOT NULL
	DROP PROCEDURE ContentReport_GetRecordsByDate
GO
/*
* Description: 
* Params
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC ContentReport_GetRecordsByDate 
	@KeywordID = 27,
	@StartDate = '2/11/2012',
	@EndDate = '4/3/2012'
*/
CREATE PROCEDURE ContentReport_GetRecordsByDate
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
	
	select CONVERT(varchar(56), leftside.Date) Date, ISNULL(rightside.Total,0) Total
	from 
		(select dt.Date
		from ContentAggregator.dbo.DimTime dt
		where dt.DimTimeID >= @StartTimeID and dt.DimTimeID <= @EndTimeID
		) leftside
	left join (select CONVERT(date, r.PublishedDate) PublishedDate, 
			COUNT(1) Total
		from ContentCrawler.dbo.Record r 
		left join ContentCrawler.dbo.FactRecordEmotion fre on r.RecordID = fre.RecordID
		
		where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate
		and (r.IsFollowed = 1 or fre.Acceptance = 1 or fre.Fear = 1 or fre.Supprise = 1 or fre.Sadness = 1 or fre.Disgust = 1 or fre.Anger = 1 or fre.Anticipation = 1 or fre.Joy = 1 or 
					exists (select * from ContentCrawler.dbo.FactRecordTag frt where frt.RecordID = r.RecordID))
		group by CONVERT(date, r.PublishedDate)
	) rightside on leftside.Date = rightside.PublishedDate
	order by leftside.Date	
END
GO


if OBJECT_ID ( 'ContentReport_GetSentiments', 'P' ) IS NOT NULL
	DROP PROCEDURE ContentReport_GetSentiments
GO
/*
* Description: 
* Params
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC ContentReport_GetSentiments 
	@KeywordID = 18,
	@StartDate = '1/11/2011',
	@EndDate = '11/20/2011'
*/
CREATE PROCEDURE ContentReport_GetSentiments
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime    
AS
BEGIN
	declare @sdid int
	set @sdid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
	declare @keywordGUID uniqueidentifier
	set @keywordGUID = (select kw.GUID from ContentAggregator.dbo.Keyword kw where kw.KeywordID =  @KeywordID)
	
	select RSentiment.Sentiment, t.Name, count(*) Total
	from (
		select fr.Sentiment
		from ContentCrawler.dbo.Record r
		inner join ContentCrawler.dbo.FactRecord fr on r.RecordID = fr.RecordID and fr.IsSubRecord = 0
		where r.KeywordGUID = @keywordGUID and PublishedDate between @StartDate and @EndDate

		union all

		select fr.Sentiment
		from ContentCrawler.dbo.SubRecord sr 
		inner join ContentCrawler.dbo.FactRecord fr on sr.SubRecordid = fr.RecordID and fr.IsSubRecord = 1
		inner join ContentCrawler.dbo.Record r on sr.RecordID = r.RecordID
		where r.KeywordGUID = @keywordGUID and sr.PublishedDate between @StartDate and @EndDate
	) RSentiment
	
	inner join ContentAggregator.dbo.Type t on t.TypeID = RSentiment.Sentiment
	group by RSentiment.Sentiment, t.Name
END
GO


if OBJECT_ID ( 'ContentReport_GetSiteTypeRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE ContentReport_GetSiteTypeRecords
GO
/*
* Description: 
* Params
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC ContentReport_GetSiteTypeRecords 
	@KeywordID = 21,
	@StartDate = '1/11/2011',
	@EndDate = '11/20/2011'
*/
CREATE PROCEDURE ContentReport_GetSiteTypeRecords
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime    
AS
BEGIN
	declare @sdid int
	set @sdid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
		
	select st.SiteTypeID, st.Name, SUM(fkr.Total) Total
	from ContentAggregator.dbo.FactKeywordRecord fkr
	inner join ContentAggregator.dbo.Site s on s.SiteID = fkr.SiteID
	inner join ContentAggregator.dbo.SiteType st on s.Type = st.SiteTypeID
	where fkr.KeywordID = @KeywordID and fkr.DimTimeID between @sdid and @edid
	group by st.SiteTypeID, st.Name
END
GO


if OBJECT_ID ( 'ContentReport_GetSiteRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE ContentReport_GetSiteRecords
GO
/*
* Description: 
* Params
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC ContentReport_GetSiteRecords 
	@KeywordID = 21,
	@StartDate = '1/11/2011',
	@EndDate = '11/20/2011'
*/
CREATE PROCEDURE ContentReport_GetSiteRecords
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime    
AS
BEGIN
	declare @sdid int
	set @sdid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
		
	select s.Name, s.URLName, SUM(Total) Total
	from ContentAggregator.dbo.FactKeywordRecord  fkr
	inner join ContentAggregator.dbo.Site s on s.SiteID = fkr.SiteID
	where fkr.KeywordID = @KeywordID and fkr.DimTimeID between @sdid and @edid
	group by s.Name, s.URLName
	order by Total desc
END
GO


if OBJECT_ID ( 'ContentReport_GetSiteRecordsSubRecords', 'P' ) IS NOT NULL
	DROP PROCEDURE ContentReport_GetSiteRecordsSubRecords
GO
/*
* Description: 
* Params
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC ContentReport_GetSiteRecordsSubRecords 
	@KeywordID = 18,
	@StartDate = '1/1/2012',
	@EndDate = '1/7/2012'
*/
CREATE PROCEDURE ContentReport_GetSiteRecordsSubRecords
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime    
AS
BEGIN
	declare @KeywordGUID uniqueidentifier
	set @KeywordGUID = (select kw.GUID from ContentAggregator.dbo.Keyword kw where kw.KeywordID = @KeywordID)
	declare @sdid int
	set @sdid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
		
	select s.Name, s.URLName, count( distinct r.RecordID) Records,	
		COUNT(distinct sr.SubRecordID) SubRecords
	from ContentAggregator.dbo.Site s
	left join ContentCrawler.dbo.Record r on s.GUID = r.SiteGUID
	left join ContentCrawler.dbo.SubRecord sr on r.RecordID = sr.RecordID
	where r.KeywordGUID = @KeywordGUID and r.PublishedDate between @StartDate and @EndDate
	group by s.Name, s.URLName
	having COUNT(1) > 0
	order by Records desc
END
GO



if OBJECT_ID ( 'ContentReport_GetAuthorByDate', 'P' ) IS NOT NULL
	DROP PROCEDURE ContentReport_GetAuthorByDate
GO
/*
* Description: 
* Params
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC ContentReport_GetAuthorByDate 
	@KeywordID = 21,
	@StartDate = '1/11/2011',
	@EndDate = '11/20/2011'
*/
CREATE PROCEDURE ContentReport_GetAuthorByDate
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime    
AS
BEGIN
	declare @sdid int
	set @sdid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
		
	select fka.Author, CONVERT(nvarchar, dt.Date, 101) [Date]
	from ContentAggregator.dbo.FactKeywordAuthor fka 
	inner join ContentAggregator.dbo.DimTime dt on fka.DimTimeID = dt.DimTimeID
	where fka.KeywordID = @KeywordID and fka.DimTimeID between @sdid and @edid 
	group by fka.Author, dt.Date
	order by dt.Date
END
GO



if OBJECT_ID ( 'ContentReport_GetSiteRecordsByDate', 'P' ) IS NOT NULL
	DROP PROCEDURE ContentReport_GetSiteRecordsByDate
GO
/*
* Description: 
* Params
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
* Sample:
EXEC ContentReport_GetSiteRecordsByDate 
	@KeywordID = 21,
	@StartDate = '1/11/2011',
	@EndDate = '11/20/2011'
*/
CREATE PROCEDURE ContentReport_GetSiteRecordsByDate
	@KeywordID int,
    @StartDate datetime,
    @EndDate datetime    
AS
BEGIN
	declare @sdid int
	set @sdid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @StartDate)
	declare @edid int
	set @edid = (select dt.DimTimeID from ContentAggregator.dbo.DimTime dt where dt.Date =  @EndDate)
		
	select s.Name, s.URLName, CONVERT(nvarchar,dt.Date,101) [Date], SUM(fkr.Total) Total
	from ContentAggregator.dbo.FactKeywordRecord fkr
	inner join ContentAggregator.dbo.Site s on s.SiteID = fkr.SiteID
	inner join ContentAggregator.dbo.DimTime dt on fkr.DimTimeID = dt.DimTimeID
	where fkr.KeywordID = @KeywordID and fkr.DimTimeID between @sdid and @edid
	group by s.Name, s.URLName, dt.Date
	order by dt.Date
END
GO

select Site.Name, SUM(Total)
from dbo.FactKeywordRecord inner join Site on site.SiteID = FactKeywordRecord.SiteID
	inner join sitetype on site.Type = SiteType.SiteTypeID
where Keywordid = 21 and FactKeywordRecord.DimTimeID between 307 and 332 
	and site.Type = 1
group by Site.Name
order by SUM(total) desc




