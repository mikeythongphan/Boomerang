Use ContentCrawler
GO

-- create new filegroup for keyword
declare @keywordGUID Uniqueidentifier;
declare @keywordID int;
declare @fg nvarchar(100);
set @keywordID = 54
set @keywordGUID = (select [GUID] from ContentAggregator.dbo.Keyword where KeywordID = @keywordID) 
set @fg = 'ContentCrawlerKeyword' + CONVERT(nvarchar(5), @keywordID);
declare @sql nvarchar(4000);
set @sql = '
ALTER DATABASE ContentCrawler
ADD FILEGROUP ' + @fg + ' 
ALTER DATABASE ContentCrawler 
ADD FILE 
(
    NAME = ' + @fg + ',
    FILENAME = ''E:\Database\' + @fg + '.ndf'',
    SIZE = 5MB,
    MAXSIZE = 15000MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP ' + @fg
print @sql
exec ( @sql)


set @sql = '
ALTER PARTITION SCHEME KeywordGUIDPartitionScheme NEXT USED ' + @fg + '
ALTER PARTITION FUNCTION KeywordGUIDPartitionFunction ()
SPLIT RANGE (''' + CONVERT(nvarchar(512), @keywordGUID) + ''') ';
print @sql
exec ( @sql)

