DECLARE @KeywordGUID uniqueidentifier = '1c06e0d6-5c7f-48db-b2dd-1d0e15c84f13';

;with tbl1 as (
	select distinct rd.RecordID
	from ContentCrawler.dbo.Record rd with(nolock)
		left join ContentCrawler.dbo.SubRecord sr with(nolock)
			on sr.RecordID=rd.RecordID
	where
			rd.KeywordGUID=@KeywordGUID
			and rd.PublishedDate>='2013-05-23 00:00:00' and rd.PublishedDate <='2013-05-24 23:59:59'
			and rd.CreatedBy=0
	group by rd.RecordID
	having count(distinct sr.SubRecordID)=0
)
	select distinct rd.RecordID,rd.RecordGUID
	from ContentCrawler.dbo.Record rd with(nolock)
		join tbl1 t1 on t1.RecordID=rd.RecordID
	where
			rd.KeywordGUID=@KeywordGUID
			--and rd.recordguid='40C71C16-898F-41CA-B464-D9959BBBCD58'
------------------------------------------------------------------------------------------------------------------------------------------------			
;with tbl1 as 
(
	SELECT distinct '22.132.37.22' as 'ServerIP',s.UrlName, rd.SiteGUID
	from MediaBotData.dbo.Record rd with(nolock)
			join [221.132.35.146].contentaggregator.dbo.site s on s.GUID=rd.SiteGUID	
)

select *
from tbl1 t
order by t.ServerIP, t.UrlName
------------------------------------------------------------------------------------------------------------------------------------------------			
declare @Url nvarchar(1024);
declare @SiteGUID uniqueidentifier='5A2721F7-1337-4992-BC7F-9D85653C7FCD';
set @Url=N'http://www.tinhte.vn/threads/qc-infographics-zalo-dat-2-trieu-nguoi-dung-va-huong-den-moc-5-trieu.2095272/'
DECLARE @KeywordGUID uniqueidentifier = 'ff338a69-86fc-4d2f-8f9f-9c6b41d98987';

DECLARE @IsReviewed bit=0;
DECLARE @IsDeleted bit=0;
DECLARE @CreatedBy int=0;
DECLARE @UpdatedBy int=0;

INSERT INTO [221.132.35.146].[ContentCrawler].[dbo].[Record] 
							( [RecordGUID], [KeywordGUID], [SiteGUID], [Title]
								,[URL], [Author], [PublishedDate], [InsertedDate]
								,[UpdatedDate], [IsReviewed], [IsDeleted]
								, [CreatedBy], [UpdatedBy]
							)

SELECT [RecordGUID], @KeywordGUID, [SiteGUID], [Title]
      ,[URL], [Author], [PublishedDate], [InsertedDate]
      ,[UpdatedDate], @IsReviewed,@IsDeleted
	  , @CreatedBy, @UpdatedBy
from Record rd with(nolock)
where rd.SiteGUID= @SiteGUID
		and rd.URL = @Url
------------------------------------------------------------------------------------------------------------------------------------------------			
DECLARE @KeywordGUID uniqueidentifier = '1c06e0d6-5c7f-48db-b2dd-1d0e15c84f13';

DECLARE @IsReviewed bit=0;
DECLARE @IsDeleted bit=0;
DECLARE @CreatedBy int=0;
DECLARE @UpdatedBy int=0;

--INSERT INTO [221.132.35.146].[ContentCrawler].[dbo].[Record] 
--							( [RecordGUID], [KeywordGUID], [SiteGUID], [Title]
--								,[URL], [Author], [PublishedDate], [InsertedDate]
--								,[UpdatedDate], [IsReviewed], [IsDeleted]
--								, [CreatedBy], [UpdatedBy]
--							)

SELECT [RecordGUID], @KeywordGUID, [SiteGUID], [Title]
      ,[URL], [Author], [PublishedDate], [InsertedDate]
      ,[UpdatedDate], @IsReviewed,@IsDeleted
	  , @CreatedBy, @UpdatedBy
from Record rd with(nolock)
where PublishedDate >= '2013-05-15 00:00:00' and PublishedDate <= '2013-05-27 23:00:00' 
		and insertedDate >= '2013-05-26 14:00:00'
		and (
			siteGUID = '5A2721F7-1337-4992-BC7F-9D85653C7FCD' 
			or SiteGUID = 'DFFC358B-93E7-48E1-AD27-F607C0BF69FB' 
			or SiteGUID = '2D374D89-396B-4652-B00B-05A78689FA49'
		)
		and (
				title like N'%Đi?n tho?i Nokia%'
				or title like N'%Đi?n tho?i Lumia%'
				or title like N'%Đi?n tho?i Asha%'
				or title like N'%Nokia 610%'
				or title like N'%Nokia 620%'
				or title like N'%Nokia 710%'
				or title like N'%Nokia 800%'
				or title like N'%Nokia 820%'
				or title like N'%Nokia 900%'

				or title like N'%Nokia 920%'
				or title like N'%Đi?n tho?i 610%'
				or title like N'%Đi?n tho?i 620%'
				or title like N'%Đi?n tho?i 710%'
				or title like N'%Đi?n tho?i 800%'
				or title like N'%Đi?n tho?i 820%'
				or title like N'%Đi?n tho?i 900%'
				or title like N'%Đi?n tho?i 920%'
				or title like N'%Dt lau meo%'
				or title like N'%Dt lua mi%'
				or title like N'%Nokia 808%'
				or title like N'%Nokia N9%'
				or title like N'%Nokia N8%'
				or title like N'%Nokia 700%'
				or title like N'%Nokia 603%'
				or title like N'%Nokia 500%'
				or title like N'%Nokia C5%'
				or title like N'%Đi?n tho?i 808%'
				or title like N'%Đi?n tho?i N9%'
				or title like N'%Đi?n tho?i N8%'
				or title like N'%Đi?n tho?i 700%'
				or title like N'%Đi?n tho?i 603%'
				or title like N'%Đi?n tho?i 500%'
				or title like N'%Đi?n tho?i C5%'
				or title like N'%S?c không dây%'
				or title like N'%920 chính h?ng dính nhi?u l?i%'
				or title like N'%Lu920%'
		)
		--and RecordGUID='E7AAC083-939B-473E-A882-A393F8B980D8'
		order by Title

------------------------------------------------------------------------------------------------------------------------------------------------			
DECLARE @KeywordGUID uniqueidentifier = '1c06e0d6-5c7f-48db-b2dd-1d0e15c84f13';
DECLARE @StartDate datetime='2013-05-25 00:00:00';--yyyy/MM/dd
DECLARE @EndDate datetime='2013-05-30 23:59:59'; --yyyy/MM/dd
DECLARE @InsertedDateRecord datetime='2013-05-29 00:00:00';

DECLARE @InsertedDate datetime= convert( nvarchar(50), DATEADD(DD,0,CONVERT(datetime,CONVERT(VARCHAR(10), dateadd(dd,0,GETDATE()), 111)+' 5:5:5')));
DECLARE @IsReviewed bit=0;
DECLARE @IsDeleted bit=0;
DECLARE @CreatedBy int=0;
DECLARE @UpdatedBy int=0;

----INSERT INTO TBL_CheckCopy_SubRecord
--INSERT INTO [MediaBotData].[dbo].[CheckCopy_SubRecord]
--           ([SubRecordID],[Content],[RecordID])
--SELECT [SubRecordID],[Content],[RecordID]
--FROM [MediaBotData].[dbo].[SubRecord] 
--WHERE insertedDate >= @InsertedDateRecord
--		--and PublishedDate >= @StartDate and PublishedDate <= @EndDate
--		and (
--			siteGUID = '5A2721F7-1337-4992-BC7F-9D85653C7FCD' 
--			or SiteGUID = 'DFFC358B-93E7-48E1-AD27-F607C0BF69FB' 
--			or SiteGUID = '2D374D89-396B-4652-B00B-05A78689FA49'
--		)


--select to copy
;with tbl1 as
(
	select [SubRecordID],[RecordID]
	from [MediaBotData].[dbo].[CheckCopy_SubRecord]
	where Content like '%nokia%'
			or Content like N'%Điện thoại%'
			or Content like N'%Dt lau%'
			or Content like N'%Sạc không dây%'
			or Content like N'%920 chính hãng dính nhiều lỗi%'
			or Content like N'%Lu920%'
		
)

INSERT INTO [221.132.35.146].[ContentCrawler].[dbo].[Record] 
							( [RecordGUID], [KeywordGUID], [SiteGUID], [Title]
								,[URL], [Author], [PublishedDate], [InsertedDate]
								,[UpdatedDate], [IsReviewed], [IsDeleted]
								, [CreatedBy], [UpdatedBy]
							)
SELECT [RecordGUID], @KeywordGUID, [SiteGUID], [Title]
      ,[URL], [Author], [PublishedDate], @InsertedDate
      ,[UpdatedDate], @IsReviewed,@IsDeleted
	  , @CreatedBy, @UpdatedBy
from Record rd with(nolock)
		join (select distinct recordID from tbl1) t on t.RecordID=rd.RecordID
where  (
			siteGUID = '5A2721F7-1337-4992-BC7F-9D85653C7FCD' 
			or SiteGUID = 'DFFC358B-93E7-48E1-AD27-F607C0BF69FB' 
			or SiteGUID = '2D374D89-396B-4652-B00B-05A78689FA49'
		)
		and rd.RecordGUID not in(
									select rdt.RecordGUID
									from [221.132.35.146].[ContentCrawler].[dbo].record rdt
									where rdt.KeywordGUID=@KeywordGUID
											and rdt.RecordGUID= rd.RecordGUID
								)
------------------------------------------------------------------------------------------------------------------------------------------------										