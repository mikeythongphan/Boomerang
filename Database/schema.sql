IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'ContentAggregator')
DROP DATABASE [ContentAggregator]
GO
CREATE DATABASE [ContentAggregator] ON  PRIMARY 
( NAME = N'ContentAggregator', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLSERVER2008R2\MSSQL\DATA\ContentAggregator.mdf' , SIZE = 9216KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'ContentAggregator_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLSERVER2008R2\MSSQL\DATA\ContentAggregator_log.ldf' , SIZE = 92864KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'ContentCrawler')
DROP DATABASE [ContentCrawler]
GO
CREATE DATABASE [ContentCrawler] ON  PRIMARY 
( NAME = N'ContentCrawler', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLSERVER2008R2\MSSQL\DATA\ContentCrawler.mdf' , SIZE = 9216KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'ContentCrawler_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLSERVER2008R2\MSSQL\DATA\ContentCrawler_log.ldf' , SIZE = 92864KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'CrawlerSchedule')
DROP DATABASE [CrawlerSchedule]
GO
CREATE DATABASE [CrawlerSchedule] ON  PRIMARY 
( NAME = N'CrawlerSchedule', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLSERVER2008R2\MSSQL\DATA\CrawlerSchedule.mdf' , SIZE = 9216KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'CrawlerSchedule_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLSERVER2008R2\MSSQL\DATA\CrawlerSchedule_log.ldf' , SIZE = 92864KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'DataHunter')
DROP DATABASE [DataHunter]
GO
CREATE DATABASE [DataHunter] ON  PRIMARY 
( NAME = N'DataHunter', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLSERVER2008R2\MSSQL\DATA\DataHunter.mdf' , SIZE = 9216KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'DataHunter_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLSERVER2008R2\MSSQL\DATA\DataHunter_log.ldf' , SIZE = 92864KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

USE [ContentAggregator]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SiteType]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[SiteType]
END
GO

CREATE TABLE [dbo].[SiteType](
	[SiteTypeID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SiteType_GUID]  DEFAULT (newid()),
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_SiteType_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_SiteType_UpdatedDate]  DEFAULT (getdate()),
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL,
 CONSTRAINT [PK_SiteType] PRIMARY KEY CLUSTERED 
(
	[SiteTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SiteAccount]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[SiteAccount]
END
GO

CREATE TABLE [dbo].[SiteAccount](
	[SiteAccountID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SiteAccount_GUID]  DEFAULT (newid()),
	[Username] [varchar](128) NOT NULL,
	[Password] [varchar](128) NOT NULL,
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_SiteAccount_Enabled]  DEFAULT ((1)),
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_SiteAccount_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_SiteAccount_UpdatedDate]  DEFAULT (getdate()),
	[SiteID] [int] NOT NULL,
 CONSTRAINT [PK_SITEACCOUNT] PRIMARY KEY CLUSTERED 
(
	[SiteAccountID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Site]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Site]
END
GO
/*
* Description: 
* Column:
	Available: have xml definition
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Site](
	[SiteID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Site_GUID]  DEFAULT (newid()),
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Site_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Site_UpdatedDate]  DEFAULT (getdate()),
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_Site_IsActive]  DEFAULT ((1)),
	[Type] [int] NOT NULL,
	[SiteCategoryID] [int] NOT NULL,
	[URL] [varchar](1024) NOT NULL,
	[URLName] [varchar](1024) NOT NULL,
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL,
	[Available] [bit] NOT NULL CONSTRAINT [DF_Site_Availaible]  DEFAULT ((0)),
	[IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Site_Deleted]  DEFAULT ((0)),
 CONSTRAINT [PK_SITEID] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SiteCategory]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[SiteCategory]
END
GO
/*
* Description:
	Type of site content, ex: for kid, teen, car fan, musical, ...
	It is different from SiteType
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SiteCategory](
	[SiteCategoryID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SiteCategory_GUID]  DEFAULT (newid()),
	[Name] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_SiteCategory_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_SiteCategory_UpdatedDate]  DEFAULT (getdate())	
 CONSTRAINT [PK_SiteCategory] PRIMARY KEY CLUSTERED 
(
	[SiteCategoryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KeywordSiteType]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[KeywordSiteType]
END
GO

CREATE TABLE [dbo].[KeywordSiteType](
	[KeywordID] [int] NOT NULL,
	[SiteTypeID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_KeywordSiteType_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_KeywordSiteType_UpdatedDate]  DEFAULT (getdate()),
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_KeywordSiteType_Enabled]  DEFAULT ((1)),
 CONSTRAINT [PK_KEYWORDSITETYPE] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC,
	[SiteTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KeywordSite]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[KeywordSite]
END
GO

CREATE TABLE [dbo].[KeywordSite](
	[KeywordID] [int] NOT NULL,
	[SiteID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_KeywordSite_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_KeywordSite_UpdatedDate]  DEFAULT (getdate()),
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_KeywordSite_Status]  DEFAULT ((1)),
 CONSTRAINT [PK_KEYWORDSITE] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC,
	[SiteID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Keyword]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Keyword]
END
GO
/*
* Description: 
* Column:
	IsCagegory
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Keyword](
	[KeywordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Keyword_GUID]  DEFAULT (newid()),
	[CategoryID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Keyword_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Keyword_UpdatedDate]  DEFAULT (getdate()),
	[Word] [nvarchar](512) NOT NULL,
	[WordWithoutAccent] [nvarchar](512) NULL,
	[InSchedule] [bit] NOT NULL CONSTRAINT [DF_Keyword_Schedule]  DEFAULT ((1)),
	[ImmediateRun] [bit] NOT NULL CONSTRAINT [DF_Keyword_ImmediateRun]  DEFAULT ((1)),
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_Keyword_IsActive]  DEFAULT ((1)),
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Order] [int] NOT NULL CONSTRAINT [DF_Keyword_Order]  DEFAULT ((0)),
	[IsDeleted] [bit] NOT NULL DEFAULT (0),
	[IsBrand] [bit] NOT NULL DEFAULT(1),
 CONSTRAINT [PK_Keyword] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Word]') AND type in (N'U'))
DROP TABLE [dbo].[Word]
GO
/*
* Description: 
* Column:
	Order: priority that spider service will get data
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Word](
	[WordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Word_GUID]  DEFAULT (newid()),
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Word_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Word_UpdatedDate]  DEFAULT (getdate()),
	[WordWithAccent] [nvarchar](512) NOT NULL,			
	[WordWithoutAccent] [nvarchar](512) NULL,
	[KeywordID] [int] NOT NULL,
	[Order] [int] NOT NULL CONSTRAINT [DF_Word_Order]  DEFAULT ((0)),
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_Word_IsActive]  DEFAULT ((1)),
	[IsDeleted] [bit] NOT NULL DEFAULT (0),
 CONSTRAINT [PK_Word] PRIMARY KEY CLUSTERED 
(
	[WordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SubKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[SubKeyword]
GO
/*
* Description: subkeyword only belongs to brand keyword. It is similar to tag
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SubKeyword](
	[SubKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SubKeyword_GUID]  DEFAULT (newid()),
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_SubKeyword_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_SubKeyword_UpdatedDate]  DEFAULT (getdate()),
	[Word] [nvarchar](512) NOT NULL,			
	[WordWithoutAccent] [nvarchar](512) NULL,
	[KeywordID] [int] NOT NULL,	
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_SubKeyword_IsActive]  DEFAULT ((1)),
 CONSTRAINT [PK_SubKeyword] PRIMARY KEY CLUSTERED 
(
	[SubKeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactKeywordRecord]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactKeywordRecord]
END
GO
/*
* Description: contain sentiment values by keyword, site,date
	It is used to report
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactKeywordRecord](
	[SiteID] [int] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[ChannelID] [int] NOT NULL,
	[DimTimeID] [int] NOT NULL,
	[Total] [int] NOT NULL,
	[Positive] [int] NOT NULL,
	[Negative] [int] NOT NULL,
	[Neutral] [int] NOT NULL,
	[VeryPositive] [int] NOT NULL,
	[VeryNegative] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_FactKeywordRecord_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_FactKeywordRecord_UpdatedDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_FACTKEYWORDRECORD] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC,
	[KeywordID] ASC,
	[ChannelID] ASC,
	[DimTimeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactKeywordAuthor]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactKeywordAuthor]
END
GO

CREATE TABLE [dbo].[FactKeywordAuthor](
	[KeywordID] [int] NOT NULL,
	[SiteID] [int] NOT NULL,
	[ChannelID] [int] NOT NULL,
	[DimTimeID] [int] NOT NULL,
	[Author] [nvarchar](256) NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_FactKeywordAuthor_InsertedDte]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_FactKeywordAuthor_UpdatedDate]  DEFAULT (getdate()),
	[Total] [int] not null,
 CONSTRAINT [PK_FACTKEYWORDAUTHOR] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC,
	[SiteID] ASC,
	[ChannelID] ASC,
	[DimTimeID] ASC,
	[Author] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactKeywordTagRecord]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactKeywordTagRecord]
END
GO

CREATE TABLE [dbo].[FactKeywordTagRecord](
	[KeywordID] [int] NOT NULL,
	[TagID] [int] NOT NULL,	
	[SiteID] [int] NOT NULL,	
	[DimTimeID] [int] NOT NULL,
	[Total] [int] NOT NULL,	
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_FactKeywordTagRecord_InsertedDte]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_FactKeywordTagRecord_UpdatedDate]  DEFAULT (getdate()),	
 CONSTRAINT [PK_FACTKEYWORDTAGRECORD] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC,		
	[TagID] ASC,
	[DimTimeID] ASC,
	[SiteID] ASC	
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactSentimentKeyword]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactSentimentKeyword]
END
GO
CREATE TABLE [dbo].[FactSentimentKeyword](
	[SentimentKeywordID] [int] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[DimTimeID] [int] NOT NULL,
	[SiteID] [int] NOT NULL,
	[Total] [int] NOT NULL,	
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_FactSentimentKeyword_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_FactSentimentKeyword_UpdatedDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_FactSentimentKeyword] PRIMARY KEY CLUSTERED 
(
	[SentimentKeywordID] ASC,
	[KeywordID] ASC,
	[DimTimeID] ASC,
	[SiteID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Channel_Parent]') AND parent_object_id = OBJECT_ID(N'[dbo].[Channel]'))
BEGIN
ALTER TABLE [dbo].[Channel] DROP CONSTRAINT [FK_Channel_Parent]
END
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Channel]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Channel]
END
GO
GO
CREATE TABLE [dbo].[Channel](
	[ChannelID] [int] NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Channel_GUID]  DEFAULT (newid()),
	[ParentID] [int] NULL,
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Channel_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Channel_UpdatedDate]  DEFAULT (getdate()),
	[IsDeleted] [bit] NOT NULL DEFAULT (0),
 CONSTRAINT [PK_Channel] PRIMARY KEY CLUSTERED 
(
	[ChannelID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Category]') AND type in (N'U'))
DROP TABLE [dbo].[Category]
GO
/*
* Description:
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Category](
	[CategoryID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Category_GUID]  DEFAULT (newid()),
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL CONSTRAINT [DF_Category_Description]  DEFAULT (''),
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Category_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Category_UpdatedDate]  DEFAULT (getdate()),
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_Category_IsActive]  DEFAULT ((1)),
	[IsDeleted] [bit] NOT NULL DEFAULT (0),
 CONSTRAINT [PK_CATEGORY] PRIMARY KEY CLUSTERED 
(
	[CategoryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CategoryTag]') AND type in (N'U'))
DROP TABLE [dbo].[CategoryTag]
GO
/*
* Description: mapping between category and tag (many to many)
* Column:
* History
-------------------------------------------------------------
8/19/2011		| Vu Do		| add
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[CategoryTag](
	[CategoryTagID] [int] IDENTITY(1,1) NOT NULL,	
	[CategoryID] [int] NOT NULL,
	[TagID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_CategoryTag_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_CategoryTag_UpdatedDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_CATEGORYTAG] PRIMARY KEY CLUSTERED 
(
	[CategoryTagID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KeywordCategory]') AND type in (N'U'))
DROP TABLE [dbo].[KeywordCategory]
GO
/*
* Description: mapping between keyword and category (many to many)
* Column:
* History
-------------------------------------------------------------
8/19/2011		| Vu Do		| add
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[KeywordCategory](
	[KeywordCategoryID] [int] IDENTITY(1,1) NOT NULL,	
	[CategoryID] [int] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_KeywordCategory_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_KeywordCategory_UpdatedDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_KEYWORDCATEGORY] PRIMARY KEY CLUSTERED 
(
	[KeywordCategoryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TagGroup]') AND type in (N'U'))
DROP TABLE [dbo].[TagGroup]
GO
/*
* Description: group tags into a group, to easy manage
* Column:
	Type: 1- general, 2-others. General tag groups are used by category function
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[TagGroup](
	[TagGroupID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[Type] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,	
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_TagGroup] PRIMARY KEY CLUSTERED 
(
	[TagGroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Tag]') AND type in (N'U'))
DROP TABLE [dbo].[Tag]
GO
/*
* Description: 
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Tag](
	[TagID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Word] [nvarchar](256) NOT NULL,
	[WordWithoutAccent] [nvarchar](256) NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[TagGroupID] [int] NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_Tag] PRIMARY KEY CLUSTERED 
(
	[TagID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [TagGUIDIndex] ON [dbo].[Tag] 
(
	[GUID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TagGroupKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[TagGroupKeyword]
GO
/*
* Description: one keyword has many tag group
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[TagGroupKeyword](	
	[TagGroupKeywordID] [int] IDENTITY(1,1) NOT NULL,	
	[KeywordID] [int] NOT NULL,	
	[TagGroupID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,	
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_TagKeywordKeyword] PRIMARY KEY CLUSTERED 
(	
	[TagGroupKeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SentimentKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[SentimentKeyword]
GO
/*
* Description: 
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SentimentKeyword](
	[SentimentKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Word] [nvarchar] (256) NOT NULL,
	[WordWithoutAccent] [nvarchar] (256) NULL,
	[Type] [int] NOT NULL,
	[SentimentGroupID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_SentimentKeyword] PRIMARY KEY CLUSTERED 
(
	[SentimentKeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SentimentGroup]') AND type in (N'U'))
DROP TABLE [dbo].[SentimentGroup]
GO
/*
* Description: 
* Column:
	Type: 1-common, 2-others. Used by system to control how to apply sentiment keyword.
		Common: all keyword group can map to
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SentimentGroup](
	[SentimentGroupID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,	
	[Type] [int] NOT NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_SentimentGroup] PRIMARY KEY CLUSTERED 
(
	[SentimentGroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EmotionKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[EmotionKeyword]
GO
/*
* Description: a keyword that associated with an emotion
* Column:
	type: emotion type
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[EmotionKeyword](
	[EmotionKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Word] [nvarchar] (256) NOT NULL,
	[WordWithoutAccent] [nvarchar] (256) NULL,
	[Type] [int] NOT NULL,
	[EmotionGroupID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_EmotionKeyword] PRIMARY KEY CLUSTERED 
(
	[EmotionKeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EmotionGroup]') AND type in (N'U'))
DROP TABLE [dbo].[EmotionGroup]
GO
/*
* Description: group of emotion keywords
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[EmotionGroup](
	[EmotionGroupID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](1024) NULL,	
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,	
	[IsDeleted] [bit] NOT NULL DEFAULT (0),
	[IsReviewed] [bit] NULL,
 CONSTRAINT [PK_EmotionGroup] PRIMARY KEY CLUSTERED 
(
	[EmotionGroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EmotionGroupEmotion]') AND type in (N'U'))
DROP TABLE [dbo].[EmotionGroupEmotion]
GO
/*
* Description: mapping between emotion and emotion group, 
	emotion group has one or more emotions. keyword belong to this group have to have one of these emotion
* Column:	
	EmotionGroupID: id of emotion group
	Type: emotion id in table Type
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[EmotionGroupEmotion](
	[EmotionGroupEmotionID] [int] IDENTITY(1,1) NOT NULL,
	[EmotionGroupID] [int] NOT NULL,
	[Type] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,		
 CONSTRAINT [PK_EmotionGroupEmotion] PRIMARY KEY CLUSTERED 
(
	[EmotionGroupEmotionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND type in (N'U'))
DROP TABLE [dbo].[Customer]
GO
/*
* Description: store information of customer
* Column:	
	code: used to authenticate customer in API
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Customer](
	[CustomerID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT (0),
	[Code] [varchar](64) NOT NULL,
 CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerBrand]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerBrand]
GO
CREATE TABLE [dbo].[CustomerBrand](
	[CustomerBrandID] [int] IDENTITY(1,1) NOT NULL,
	[BrandID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_CustomerBrand] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC,
	[CustomerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserDetail]') AND type in (N'U'))
DROP TABLE [dbo].[UserDetail]
GO
CREATE TABLE [dbo].[UserDetail](
	[UserDetailID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[UserName] [nvarchar](128) NOT NULL,	
	[CustomerID] [int] NOT NULL,
	[FullName] [nvarchar] (128) NOT NULL,
	[Email] [nvarchar] (128) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_UserDetail] PRIMARY KEY CLUSTERED 
(
	[UserDetailID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[UserKeyword]
GO
CREATE TABLE [dbo].[UserKeyword](
	[UserKeywordID] [int] IDENTITY(1,1) NOT NULL,	
	[KeywordID] [int] NOT NULL,	
	[UserDetailID] [int] NOT NULL,	
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_UserKeyword] PRIMARY KEY CLUSTERED 
(
	[UserKeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Brand]') AND type in (N'U'))
DROP TABLE [dbo].[Brand]
GO
CREATE TABLE [dbo].[Brand](
	[BrandID] [int] IDENTITY(1,1) NOT NULL,	
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BrandUser]') AND type in (N'U'))
DROP TABLE [dbo].[BrandUser]
GO
CREATE TABLE [dbo].[BrandUser](
	[BrandUserID] [int] IDENTITY(1,1) NOT NULL,
	[BrandID] [int] NOT NULL,	
	[UserDetailID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_BrandUser] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC,
	[UserDetailID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/*
* Type: 1-Brand, 2-Competitor
*/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BrandKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[BrandKeyword]
GO
CREATE TABLE [dbo].[BrandKeyword](
	[BrandKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[BrandID] [int] NOT NULL,	
	[KeywordID] [int] NOT NULL,
	[Type] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,	
 CONSTRAINT [PK_BrandKeyword] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC,
	[KeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimTime]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[DimTime]
END
GO
CREATE TABLE [dbo].[DimTime](
	[DimTimeID] [int] IDENTITY(1,1) NOT NULL,
	[Date] [date] NOT NULL,
	[Quarter] [smallint] NOT NULL,
	[Year] [int] NOT NULL,
	[Month] [smallint] NOT NULL,
	[Week] [smallint] NOT NULL,
	[DayOfMonth] [smallint] NOT NULL,
	[StartDateOfMonth] [datetime] NOT NULL,
	[EndDateOfMonth] [datetime] NOT NULL,
 CONSTRAINT [PK_DIMTIME] PRIMARY KEY CLUSTERED 
(
	[DimTimeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Menu]') AND type in (N'U'))
DROP TABLE [dbo].[Menu]
GO
/*
* Description: 
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Menu](
	[MenuID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,	
	[Description] [nvarchar](512) NULL,
	[Controller] [varchar](128) NULL,
	[Action] [varchar](128) NULL,
	[View] [varchar](128) NULL,
	[ParentID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Menu_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Menu_UpdatedDate]  DEFAULT (getdate())
 CONSTRAINT [PK_Menu] PRIMARY KEY CLUSTERED 
(
	[MenuID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerMenu]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerMenu]
GO
/*
* Description:	
* Column:
	Order: positition on menu. From top to bottom
	CustomerID: =0, default menu for all customer
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[CustomerMenu](
	[CustomerMenuID] [int] IDENTITY(1,1) NOT NULL,	
	[MenuID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[Order] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_CustomerMenu_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_CustomerMenu_UpdatedDate]  DEFAULT (getdate())
 CONSTRAINT [PK_CustomerMenu] PRIMARY KEY CLUSTERED 
(
	[CustomerMenuID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Type]') AND type in (N'U'))
DROP TABLE [dbo].[Type]
GO
/*
* Description:
	Comprise all type in the system
	Sentiment: Positive:1, Negative: 2, Neutral: 3
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Type](
	[TypeID] [int] NOT NULL,	
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](512) NOT NULL,
	[ParentID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Type_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Type_UpdatedDate]  DEFAULT (getdate())
 CONSTRAINT [PK_Type] PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TargetFilter]') AND type in (N'U'))
DROP TABLE [dbo].[TargetFilter]
GO
/*
* Description:
	It groups a number of website.
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[TargetFilter](
	[TargetFilterID] [int] IDENTITY(1,1) NOT NULL,	
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](512) NOT NULL,	
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_TargetFilter_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_TargetFilter_UpdatedDate]  DEFAULT (getdate()),
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_TargetFilter] PRIMARY KEY CLUSTERED 
(
	[TargetFilterID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TargetFilterAttribute]') AND type in (N'U'))
DROP TABLE [dbo].[TargetFilterAttribute]
GO
/*
* Description:
	Mapping between TargetFilter and Site
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[TargetFilterAttribute](
	[TargetFilterAttributeID] [int] IDENTITY(1,1) NOT NULL,	
	[TargetFilterID] [int] NOT NULL,
	[SiteID] [int] NOT NULL,
	[ChannelID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_TargetFilterAttribute_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_TargetFilterAttribute_UpdatedDate]  DEFAULT (getdate())
 CONSTRAINT [PK_TargetFilterAttribute] PRIMARY KEY CLUSTERED 
(
	[TargetFilterAttributeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Config]') AND type in (N'U'))
DROP TABLE [dbo].[Config]
GO
/*
* Description:
	Store configuration values of system
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Config](
	[ConfigID] [int] IDENTITY(1,1) NOT NULL,	
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [varchar](128) NOT NULL,
	[Value] [int] NOT NULL,	
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate())
 CONSTRAINT [PK_Config] PRIMARY KEY CLUSTERED 
(
	[ConfigID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SystemConfig]') AND type in (N'U'))
DROP TABLE [dbo].[SystemConfig]
GO
/*
* Description:
	Store systen configuration in global
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SystemConfig](
	[SystemConfigID] [int] IDENTITY(1,1) NOT NULL,	
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [varchar](128) NOT NULL,
	[Value] [nvarchar] (256) NOT NULL,
	[Description] [nvarchar] (256) NULL,	
	[ParentID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate())
 CONSTRAINT [PK_SystemConfig] PRIMARY KEY CLUSTERED 
(
	[SystemConfigID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Profile]') AND type in (N'U'))
DROP TABLE [dbo].[Profile]
GO
/*
* Description:
	Information of user contact: phone, email, name
	Used to send email
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Profile](
	[ProfileID] [int] IDENTITY(1,1) NOT NULL,	
	[GUID] [uniqueidentifier] NOT NULL,
	[Level1Name] [nvarchar](128) NULL,	
	[Level1Phone] [varchar](128) NULL,	
	[Level1Email] [varchar](128) NULL,	
	[Level2Name] [nvarchar](128) NULL,	
	[Level2Phone] [varchar](128) NULL,	
	[Level2Email] [varchar](128) NULL,
	[Level3Name] [nvarchar](128) NULL,	
	[Level3Phone] [varchar](128) NULL,	
	[Level3Email] [varchar](128) NULL,	
	[AccountManagerName] [nvarchar](128) NULL,	
	[AccountManagerPhone] [varchar](128) NULL,	
	[AccountManagerEmail] [varchar](128) NULL,	
	[BrandID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate())
 CONSTRAINT [PK_Profile] PRIMARY KEY CLUSTERED 
(
	[ProfileID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Label]') AND type in (N'U'))
DROP TABLE [dbo].[Label]
GO
/*
* Description: similar with Tag, but customer will tag it
	Used in emotion frontend:
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Label](
	[LabelID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
	[GUID] [uniqueidentifier] NOT NULL,
	[Word] [nvarchar](256) NOT NULL,
	[WordWithoutAccent] [nvarchar](256) NULL,	
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[LabelGroupID] [int] NULL,
	[CustomerID] [int] NOT NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
)
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NegativeKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[NegativeKeyword]
GO
/*
* Description: used by copy service, when a record contain these keyword, it will send an email
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[NegativeKeyword](
	[NegativeKeywordID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
	[GUID] [uniqueidentifier] NOT NULL,
	[Word] [nvarchar](256) NOT NULL,
	[WordWithoutAccent] [nvarchar](256) NULL,	
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
)
GO


-- ContentCrawler database
USE [ContentCrawler]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SubRecord]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[SubRecord]
END
GO
/*
* Description:
* Columns:
	IsAnalyzed: true, sentiment service has analyzed it
	IsTagged: true, tagging service has analyzed it 
	Matching: true, does this record contain keyword
	IsTaggedSubKeyword: true, record is tagged by subkeyword	
	IsApproved: Are briefrecord pproved by manager
* History
-------------------------------------------------------------
7/18/2011	| Vu Do		| Add Matching column
8/11/2011	| Vu Do		| Add IsTaggedSubKeyword column
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SubRecord](
	[SubRecordID] [int] IDENTITY(1,1) NOT NULL,
	[SubRecordGUID] [uniqueidentifier] NOT NULL,
	[RecordID] [int] NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[URL] [nvarchar](1024) NOT NULL,
	[Author] [nvarchar](256) NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_SubRecord_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_SubRecord_UpdatedDate]  DEFAULT (getdate()),
	[PublishedDate] [datetime] NOT NULL ,
	[IsTagged] [bit] NULL,
	[IsAnalyzed] [bit] NULL,
	[IsTaggedSubKeyword] [bit] NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT(0),
	[Matching] [tinyint] NULL,
	[Irrelevant] [bit] NULL,
	[CreatedBy] [nvarchar](256) NOT NULL default('auto'),
	[UpdatedBy] [nvarchar](256) NOT NULL default('auto'),
	[SubKeywordGUID] [uniqueidentifier] NULL,
	[IsApproved] [bit] not null default(0),
 CONSTRAINT [PK_SubRecord] PRIMARY KEY CLUSTERED 
(
	[SubRecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [PublishedDate Index] ON [dbo].[SubRecord] 
(
	[PublishedDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [RecordIDIndex] ON [dbo].[SubRecord] 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [URLIndex] ON [dbo].[SubRecord] 
(
	[URL] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [RecordID_URL_Index] ON [dbo].[SubRecord] 
(
	[RecordID] ASC,
	[URL] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [SubRecord_Active_Index] ON [dbo].[SubRecord] 
(
	[RecordID] ASC,
	[IsDeleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Record]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Record]
END
GO
/*
* Description:
* Columns:
	IsAnalyzed: true, sentiment service has analyzed it
	IsTagged: true, tagging service has analyzed it 
	Matching: true, does this record contain keyword
	IsTaggedSubKeyword: true, record is tagged by subkeyword,
	SubKeywordGUID: reference to subkeyword id
* History
-------------------------------------------------------------
7/18/2011	| Vu Do		| Add Matching column
8/11/2011	| Vu Do		| Add IsTaggedSubKeyword column
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Record](
	[RecordID] [int] IDENTITY(1,1) NOT NULL,
	[RecordGUID] [uniqueidentifier] NOT NULL,
	[URL] [varchar](1024) NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[WordGUID] [uniqueidentifier] NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[ChannelGUID] [uniqueidentifier] NOT NULL,
	[Author] [nvarchar](256) NOT NULL,
	[PublishedDate] [datetime] NOT NULL ,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Record_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Record_UpdatedDate]  DEFAULT (getdate()),
	[Abstract] [nvarchar](4000) NULL,
	[ContentTypeID] [int] NOT NULL,
	[Category] [nvarchar](512) NOT NULL,
	[Title] [nvarchar](512) NOT NULL,
	[IsTagged] [bit] NULL,
	[TagType] [int] NULL,
	[IsAnalyzed] [bit] NULL,
	[IsTaggedSubKeyword] [bit] NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT(0),
	[Matching] [tinyint] NULL,
	[IsFollowed] [bit] NULL,
	[IsDirty] [bit] not null default(0),
	[Irrelevant] [bit] NULL,
	[CreatedBy] [nvarchar](256) NOT NULL default('auto'),
	[UpdatedBy] [int] NOT NULL,
	[SubKeywordGUID] [uniqueidentifier] NULL,
	[IsApproved] [bit] not null default(0),
 CONSTRAINT [PK_Record] PRIMARY KEY CLUSTERED 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [PublishedDate Index] ON [dbo].[Record] 
(
	[PublishedDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [URLIndex] ON [dbo].[Record] 
(
	[URL] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [KeywordGUIDIndex] ON [dbo].[Record] 
(
	[KeywordGUID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [KeywordGUID_PublishedDate_IsDeleted_Index] ON [dbo].[Record] 
(
	[KeywordGUID] ASC,
	[PublishedDate] ASC,
	[IsDeleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [KeywordGUID_SubKeywordGUID_URL_Index] ON [dbo].[Record] 
(
	[KeywordGUID] ASC,
	[SubKeywordGUID] ASC,
	[URL] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RecordBriefContent]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[RecordBriefContent]
END
GO
/*
* Description:
* Columns:
* History
-------------------------------------------------------------

-------------------------------------------------------------
*/
CREATE TABLE [dbo].[RecordBriefContent](
	[RecordBriefContentID] [int] IDENTITY(1,1) NOT NULL,
	[RecordID] [int] NOT NULL,	
	[Content] [nvarchar](max) NOT NULL,
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[IsDeleted] [bit] NOT NULL DEFAULT(0),
	[IsSubRecord] [bit] not null default(0),
	[EmotionID] [int] NULL,
	[UserID] [int] NOT NULL,
 CONSTRAINT [PK_RecordBriefContent] PRIMARY KEY CLUSTERED 
(
	[RecordBriefContentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [RecordID IsSubRecord IsDeleted] ON [dbo].[RecordBriefContent]
(
	[IsSubRecord] ASC,
	[IsDeleted] ASC,
	[RecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BriefContentTag]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[BriefContentTag]
END
GO
/*
* Description: store brief content tag
* Columns:
* History
-------------------------------------------------------------

-------------------------------------------------------------
*/
CREATE TABLE [dbo].[BriefContentTag](
	[BriefContentTagID] [int] IDENTITY(1,1) NOT NULL,
	[RecordBriefContentID] [int] NOT NULL,
	[RecordID] [int] NOT NULL,
	[TagGroupGUID] [uniqueidentifier] NOT NULL,
	[TagGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[IsDeleted] [bit] NOT NULL DEFAULT(0),
	[IsSubRecord] [bit] not null default(0),
	[UserID] [int] NOT NULL,
 CONSTRAINT [PK_BriefContentTag] PRIMARY KEY CLUSTERED 
(
	[BriefContentTagID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [BriefContentTag RecordID Index] ON [dbo].[BriefContentTag] 
(
	[RecordBriefContentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactRecord]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactRecord]
END
GO
/*
* Description: 
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactRecord](
	[FactRecordID] [int] IDENTITY(1,1) NOT NULL,
	[RecordID] [int] NOT NULL,
	[Sentiment] [smallint] NOT NULL CONSTRAINT [DF_FactRecord_Sentiment]  DEFAULT ((0)),
	[Owner] [varchar](256) NOT NULL,
	[IsSubRecord] [bit] NOT NULL CONSTRAINT [DF_FactRecord_IsSubRecord]  DEFAULT ((0)),
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_FactRecord_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_FactRecord_UpdatedDate]  DEFAULT (getdate()),
	[SubRecordID] [int] null,
	[ActiveIndicator] [bit] null,	
	[SentimentOwner] [varchar](128) null,
	[NumOfPositive] [int] NULL,
	[NumOfNegative] [int] NULL,	
 CONSTRAINT [PK_FactRecord] PRIMARY KEY CLUSTERED 
(
	[FactRecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [RecordIDIndex] ON [dbo].[FactRecord] 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Record_Tag_Active_Index] ON [dbo].[FactRecord] 
(
	[RecordID] ASC,
	[IsSubRecord] ASC,
	[ActiveIndicator] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [SubRecord_Tag_Active_Index] ON [dbo].[FactRecord] 
(
	[SubRecordID] ASC,
	[IsSubRecord] ASC,
	[ActiveIndicator] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ContentType]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[ContentType]
END
GO
CREATE TABLE [dbo].[ContentType](
	[ContentTypeID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_ContentType_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_ContentType_UpdatedDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_CONTENTTYPE] PRIMARY KEY CLUSTERED 
(
	[ContentTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactRecordTag]') AND type in (N'U'))
DROP TABLE [dbo].[FactRecordTag]
GO
/*
* Description: 
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactRecordTag](
	[FactRecordTagID] [int] IDENTITY(1,1) NOT NULL,
	[TagGUID] [uniqueidentifier] NOT NULL,
	[RecordID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Status] [bit] NOT NULL,
	[IsSubRecord] [bit] NULL,
	[IsDeleted] [bit] NOT NULL CONSTRAINT [DF_FactRecordTag_IsDeleted]  DEFAULT ((0)),
 CONSTRAINT [PK_FactRecordTag] PRIMARY KEY CLUSTERED 
(
	[FactRecordTagID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [RecordIDIndex] ON [dbo].[FactRecordTag] 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [RecordID_IsSubRecord_IsDeleted] ON [dbo].[FactRecordTag] 
(
	[RecordID] ASC,
	[IsSubRecord] ASC,
	[IsDeleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactRecordLabel]') AND type in (N'U'))
DROP TABLE [dbo].[FactRecordLabel]
GO
/*
* Description: mapping between record and label.
	Insert a row when customer tags it
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactRecordLabel](
	[FactRecordLabelID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
	[LabelGUID] [uniqueidentifier] NOT NULL,
	[RecordID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,	
	[IsSubRecord] [bit] NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT ((0)),
)
CREATE NONCLUSTERED INDEX [RecordIDLabelIndex] ON [dbo].[FactRecordLabel] 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactRecordSubKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[FactRecordSubKeyword]
GO
/*
* Description: mapping between subkeyword and record (subrecord)
* Column:
* History
-------------------------------------------------------------
8/9/2011	Vu			Add
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactRecordSubKeyword](
	[FactRecordSubKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[SubKeywordGUID] [uniqueidentifier] NOT NULL,
	[RecordID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsSubRecord] [bit] NULL,
	[IsDeleted] [bit] NOT NULL CONSTRAINT [DF_FactRecordSubKeyword_IsDeleted]  DEFAULT ((0)),
 CONSTRAINT [PK_FactRecordSubKeyword] PRIMARY KEY CLUSTERED 
(
	[FactRecordSubKeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [RecordIDIndex] ON [dbo].[FactRecordSubKeyword] 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RecordSentimentKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[RecordSentimentKeyword]
GO


/*
* Description: mapping between sentiment keyword and record (subrecord)
* Column:
	Total: number of occurences of sentiment keyword in record's content
	ActiveIndicator: 
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[RecordSentimentKeyword](
	[RecordSentimentKeywordID] int IDENTITY(1,1) NOT NULL,
	[RecordID] [int] NOT NULL,
	[SentimentKeywordGUID] [uniqueidentifier] NOT NULL,	
	[IsSubRecord] [bit] NOT NULL CONSTRAINT [DF_RecordSentimentKeyword_IsSubRecord]  DEFAULT ((0)),
	[SubRecordID] [int] null,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Total] [int] NULL,
	[ActiveIndicator] [bit] null
 CONSTRAINT [PK_RecordSentimentKeyword] PRIMARY KEY CLUSTERED 
(
	[RecordSentimentKeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [RecordIDIndex] ON [dbo].[RecordSentimentKeyword] 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactRecordEmotion]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactRecordEmotion]
END
GO
/*
* Description: 
	
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactRecordEmotion](
	[FactRecordEmotionID] [int] IDENTITY(1,1) NOT NULL,
	[RecordID] [int] NOT NULL,
	[Acceptance] [bit] NULL,
	[Fear] [bit] NULL,
	[Supprise] [bit]NULL,
	[Sadness] [bit] NULL,
	[Disgust] [bit] NULL,
	[Anger] [bit] NULL,
	[Anticipation] [bit] NULL,
	[Joy] [bit] NULL,
	[Score] [float] NULL,
	[ImpressionRate] [float] NULL,		
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[Owner] [nvarchar] (128),
	[IsDeleted] [bit] not null default(0),
	[IsSubRecord] [bit] not null default(0),
 CONSTRAINT [PK_FactRecordEmotion] PRIMARY KEY CLUSTERED 
(
	[FactRecordEmotionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


CREATE NONCLUSTERED INDEX [RecordIDFaceEmotionIndex] ON [dbo].[FactRecord] 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SubRecordStatus]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[SubRecordStatus]
END
GO
/*
* Description: 
	status of subrecord: open 101, pending 102, done 103
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SubRecordStatus](
	[SubRecordStatusID] [int] IDENTITY(1,1) NOT NULL,
	[SubRecordID] [int] NOT NULL,
	[Status] [int] NOT NULL,	
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
 CONSTRAINT [PK_SubRecordStatus] PRIMARY KEY CLUSTERED 
(
	[SubRecordStatusID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AlertMessage]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[AlertMessage]
END
GO
/*
* Description: 
	As a queue, used to store email, sms message
* Column:
	Type: 1: email, 2: sms, 3: both
	Status: 1: Available, 2: Sent, 3: Failed
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[AlertMessage](
	[AlertMessageID] [int] IDENTITY(1,1) NOT NULL,
	[Content] [nvarchar] (max) NOT NULL,
	[Subject] [nvarchar] (max) NULL,
	[Email] [varchar] (2048) NULL,
	[CC] [varchar] (2048) NULL,
	[SMSContent] [nvarchar] (1024) NULL,
	[Phone] [varchar] (2048) NULL,
	[Type] [int] NOT NULL,
	[Status] [int] NOT NULL,	
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
 CONSTRAINT [PK_AlertMessage] PRIMARY KEY CLUSTERED 
(
	[AlertMessageID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

-- CrawlerSchedule database
USE [CrawlerSchedule]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Task]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Task]
END
GO
CREATE TABLE [dbo].[Task](
	[TaskID] [int] IDENTITY(1,1) NOT NULL,	
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_Task_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Task_UpdatedDate]  DEFAULT (getdate()),
	[RunningDate] [datetime] NULL,
	[Running] [bit] NOT NULL CONSTRAINT [DF_Task_Running]  DEFAULT ((0)),
	[Word] [nvarchar](512) NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[WordGUID] [uniqueidentifier] NOT NULL,
	[Completed] [bit] NOT NULL CONSTRAINT [DF_Task_Completed]  DEFAULT ((0)),
	[MachineIP] [varchar](64) NOT NULL,
	[SiteType] [int] NOT NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Order] [int] NOT NULL CONSTRAINT [DF_Task_Order]  DEFAULT ((0)),
	[Succeeded] [bit] NOT NULL CONSTRAINT [DF_Task_Succeeded]  DEFAULT ((0)),
 CONSTRAINT [PK_Task] PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ScheduleTask]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[ScheduleTask]
END
GO

CREATE TABLE [dbo].[ScheduleTask](
	[ScheduleTaskID] [int] IDENTITY(1,1) NOT NULL,
	[WordGUID] [uniqueidentifier] NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,	
	[Word] [nvarchar](512) NOT NULL,
	[InsertedDate] [datetime] NOT NULL CONSTRAINT [DF_ScheduleTask_InsertedDate]  DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_ScheduleTask_UpdatedDate]  DEFAULT (getdate()),
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[LatestDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_ScheduleTask_Status]  DEFAULT ((1)),
	[Order] [int] NOT NULL CONSTRAINT [DF_ScheduleTask_Order]  DEFAULT ((0)),
 CONSTRAINT [PK_SCHEDULETASK] PRIMARY KEY CLUSTERED 
(
	[ScheduleTaskID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

/****** Object:  Table [dbo].[Queue]    Script Date: 06/17/2012 23:15:33 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Queue]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Queue]
END
GO

CREATE TABLE [dbo].[Queue](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[URL] [nvarchar](1024) NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[ChannelGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[IsCompleted] [bit] NOT NULL,
	[Order] [int] NOT NULL,
	[PublishedDate] [datetime] NOT NULL,
	[LatestPageUrl] [nvarchar](1024) NULL,
	[IsRunning] [bit] NULL,
 CONSTRAINT [PK_Queue] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

-- datahunter
USE [MediaBotData]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Record]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Record]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Record](
	[RecordID] [int] IDENTITY(1,1) NOT NULL,
	[RecordGUID] [uniqueidentifier] NOT NULL,
	[URL] [nvarchar](1024) NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[Author] [nvarchar](256) NOT NULL,
	[PublishedDate] [datetime] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[Title] [nvarchar](512) NOT NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_Record] PRIMARY KEY NONCLUSTERED 
(
	[RecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [RecordShreddingInSiteGUIDSchema]([SiteGUID])

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SubRecord]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[SubRecord]
END
GO

/*
* Description:
* Columns:
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SubRecord](
	[SubRecordID] [int] IDENTITY(1,1) NOT NULL,
	[SubRecordGUID] [uniqueidentifier] NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[URL] [nvarchar](1024) NOT NULL,
	[Author] [nvarchar](256) NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[PublishedDate] [datetime] NOT NULL,
	[IsDeleted] [bit] NULL,
	[RecordID] [int] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_SubRecord] PRIMARY KEY NONCLUSTERED 
(
	[SubRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [SubRecordShreddingInSiteGUIDSchema]([SiteGUID])

GO
ALTER TABLE [dbo].[SubRecord]  WITH CHECK ADD  CONSTRAINT [FK_Record_SubRecord] FOREIGN KEY([RecordID])
REFERENCES [dbo].[Record] ([RecordID])
GO
ALTER TABLE [dbo].[SubRecord] CHECK CONSTRAINT [FK_Record_SubRecord]
GO



--create full text index
CREATE FULLTEXT CATALOG [ft] WITH ACCENT_SENSITIVITY = OFF AS DEFAULT
GO
CREATE FULLTEXT INDEX ON Record ( Title Language 1066) KEY INDEX PK_Record ON ft
GO
CREATE FULLTEXT INDEX ON SubRecord (Content Language 1066) KEY INDEX PK_SubRecord ON ft

--database audit
use ContentAudit
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Audit]') AND type in (N'U'))
DROP TABLE [dbo].[Audit]
GO
/*
* Description:	
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Audit](
	[AuditID] [int] IDENTITY(1,1) NOT NULL,		
	[UserID] [varchar](128) NOT NULL,
	[Action] [int] NOT NULL,	
	[When] [datetime] NOT NULL DEFAULT (getdate()),
	[Table] [nvarchar](256) NULL,
	[Column] [nvarchar](256) NULL,
	[Value] [nvarchar](256) NULL,
	[Note] [nvarchar](256) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate())
 CONSTRAINT [PK_Audit] PRIMARY KEY CLUSTERED 
(
	[AuditID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TaggingAudit]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[TaggingAudit]
END
GO
/*
* Description: store brief content tag
* Columns:
* History
-------------------------------------------------------------

-------------------------------------------------------------
*/
CREATE TABLE [dbo].[TaggingAudit](
	[TaggingAuditID] [int] IDENTITY(1,1) NOT NULL,
	[RecordBriefContentID] [int] NOT NULL,
	[RecordID] [int] NOT NULL,
	[TagGroupGUID] [uniqueidentifier] NOT NULL,
	[TagGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[IsDeleted] [bit] NOT NULL DEFAULT(0),
	[IsSubRecord] [bit] not null default(0),
	[UserID] [int] not null,
 CONSTRAINT [PK_TaggingAudit] PRIMARY KEY CLUSTERED 
(
	[TaggingAuditID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO