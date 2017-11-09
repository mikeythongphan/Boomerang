USE ContentAggregator
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Keyword]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Keyword]
END
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Keyword](
	[KeywordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL DEFAULT (newid()),	
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[Word] [nvarchar](512) NOT NULL,
	[WordWithoutAccent] [nvarchar](512) NULL,		
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_Keyword_IsActive]  DEFAULT ((1)),
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,	
	[IsDeleted] [bit] NOT NULL DEFAULT (0),	
 CONSTRAINT [PK_Keyword] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Site]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Site]
END
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Site](
	[SiteID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL DEFAULT (newid()),
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL  DEFAULT (getdate()),
	[IsActive] [bit] NOT NULL DEFAULT ((1)),
	[SiteTypeID] [int] NOT NULL,
	[SiteCategoryID] [int] NOT NULL,
	[URL] [varchar](1024) NOT NULL,
	[URLName] [varchar](1024) NOT NULL,
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL,	
	[Duration] [int] NULL,
	[IsDeleted] [bit] NOT NULL DEFAULT ((0)),
 CONSTRAINT [PK_SITEID] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SiteType]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[SiteType]
END
GO

CREATE TABLE [dbo].[SiteType](
	[SiteTypeID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL DEFAULT (newid()),
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[Name] [nvarchar](1024) NOT NULL,
	[Description] [nvarchar](1024) NOT NULL,
 CONSTRAINT [PK_SiteType] PRIMARY KEY CLUSTERED 
(
	[SiteTypeID] ASC
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

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Word]') AND type in (N'U'))
DROP TABLE [dbo].[Word]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Word](
	[WordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL DEFAULT (newid()),
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[WordWithAccent] [nvarchar](512) NOT NULL,			
	[WordWithoutAccent] [nvarchar](512) NULL,
	[KeywordID] [int] NOT NULL,		
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
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SubKeyword](
	[SubKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[KeywordID] [int] NOT NULL,	
	[Word] [nvarchar](512) NOT NULL,
	[WordWithoutAccent] [nvarchar](512) NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] NOT NULL default(0),
 CONSTRAINT [PK_SubKeyword] PRIMARY KEY CLUSTERED 
(
	[SubKeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
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
	[ParentID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,	
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_TagGroup] PRIMARY KEY CLUSTERED 
(
	[TagGroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TagGroupKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[TagGroupKeyword]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[TagGroupKeyword](
	[TagGroupKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[KeywordID] [int] NOT NULL,
	[TagGroupID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),	
	[IsDeleted] [bit] NOT NULL default(0),
 CONSTRAINT [PK_TagKeywordKeyword] PRIMARY KEY CLUSTERED 
(
	[TagGroupKeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
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
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_Tag] PRIMARY KEY CLUSTERED 
(
	[TagID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserDetail]') AND type in (N'U'))
DROP TABLE [dbo].[UserDetail]
GO
/*
* Description: 
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[UserDetail](
	[UserDetailID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[UserName] [nvarchar](128) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[FullName] [nvarchar](128) NOT NULL,
	[Email] [nvarchar](128) NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] NOT NULL default(0),
 CONSTRAINT [PK_UserDetail] PRIMARY KEY CLUSTERED 
(
	[UserDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


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
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),	
	[IsDeleted] [bit] NOT NULL default(0),
	[Code] [varchar](64) NOT NULL,
 CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerBrand]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerBrand]
GO
/*
* Description:
* Column:		
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[CustomerBrand](
	[CustomerBrandID] [int] IDENTITY(1,1) NOT NULL,
	[BrandID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] NOT NULL default(0),
 CONSTRAINT [PK_CustomerBrand] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC,
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Brand]') AND type in (N'U'))
DROP TABLE [dbo].[Brand]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Brand](
	[BrandID] [int] IDENTITY(1,1) NOT NULL,	
	[GUID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[CustomerID] [int] NOT NULL,
	[BehaviorGroupID] [int] NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),	
	[IsDeleted] [bit] NOT NULL DEFAULT (0)
 CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BrandKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[BrandKeyword]
GO
/*
* Description: 
* Column:	
	Type: Brand, or competitor
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[BrandKeyword](
	[BrandKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[BrandID] [int] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[Type] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] NOT NULL DEFAULT(0),
 CONSTRAINT [PK_BrandKeyword] PRIMARY KEY CLUSTERED 
(
	[BrandKeywordID] ASC	
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BrandUser]') AND type in (N'U'))
DROP TABLE [dbo].[BrandUser]
GO
/*
* Description: 
* Column:		
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[BrandUser](
	[BrandUserID] [int] IDENTITY(1,1) NOT NULL,
	[BrandID] [int] NOT NULL,
	[UserDetailID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] NOT NULL default(0),
 CONSTRAINT [PK_BrandUser] PRIMARY KEY CLUSTERED 
(
	[BrandUserID] ASC	
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND type in (N'U'))
DROP TABLE [dbo].[Projects]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Projects](
	[ProjectId] [int] IDENTITY(1,1) NOT NULL,
	[ProjectName] [nvarchar](500) NOT NULL,
	[TypeId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,	
	[MainContractId] [int] NOT NULL,		
	[IsDeleted] [bit] NOT NULL default(0),
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[UserUpdate] [uniqueidentifier] NOT NULL,
	[Description] [nchar](1000) NULL,
 CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED 
(
	[ProjectId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProjectType]') AND type in (N'U'))
DROP TABLE [dbo].[ProjectType]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[ProjectType](
	[ProjectTypeId] [int] IDENTITY(1,1) NOT NULL,
	[TypeName] [nvarchar](500) NOT NULL,	
	[IsDeleted] [bit] NOT NULL default(0),
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[UserUpdate] [uniqueidentifier] NOT NULL,
	[Descriptions] [nvarchar](1000) NULL,
 CONSTRAINT [PK_ProjectType] PRIMARY KEY CLUSTERED 
(
	[ProjectTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProjectUser]') AND type in (N'U'))
DROP TABLE [dbo].[ProjectUser]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[ProjectUser](
	[ProjectUserID] [int] IDENTITY(1,1) NOT NULL,
	[ProjectID] [int] NOT NULL,
	[UserID] [int] NOT NULL,		
	[IsDeleted] [bit] NOT NULL default(0),	
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),	
 CONSTRAINT [PK_ProjectUserID] PRIMARY KEY CLUSTERED 
(
	[ProjectUserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProjectBrand]') AND type in (N'U'))
DROP TABLE [dbo].[ProjectBrand]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[ProjectBrand](
	[ProjectBrandID] [int] IDENTITY(1,1) NOT NULL,
	[ProjectID] [int] NOT NULL,
	[BrandID] [int] NOT NULL,		
	[Description] [nvarchar](500) NULL,
	[InsertedDate] [datetime] NULL default(getdate()),
	[UpdatedDate] [datetime] NULL default(getdate()),
	[UserName] [nvarchar](50) NULL,
	[IsDelete] [bit] NOT NULL default(0),
 CONSTRAINT [PK_ProjectBrand] PRIMARY KEY CLUSTERED 
(
	[ProjectBrandID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Contacts]') AND type in (N'U'))
DROP TABLE [dbo].[Contacts]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Contacts](
	[ContactId] [int] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Address] [nvarchar](500) NOT NULL,
	[PhoneNumber] [nvarchar](50) NOT NULL,
	[CellPhone] [nvarchar](50) NOT NULL,
	[Email] [nvarchar](100) NOT NULL,
	[Fax] [nvarchar](50) NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[UserUpdate] [nvarchar](50) NOT NULL,
	[Descriptions] [nvarchar](500) NULL,	
	[IsDelete] [bit] NOT NULL default(0),
 CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED 
(
	[ContactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Profile]') AND type in (N'U'))
DROP TABLE [dbo].[Profile]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Profile](
	[ProfileID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Level1Name] [nvarchar](1024) NULL,
	[Level1Phone] [varchar](1024) NULL,
	[Level1Email] [varchar](1024) NULL,
	[Level2Name] [nvarchar](1024) NULL,
	[Level2Phone] [varchar](1024) NULL,
	[Level2Email] [varchar](1024) NULL,
	[Level3Name] [nvarchar](1024) NULL,
	[Level3Phone] [varchar](1024) NULL,
	[Level3Email] [varchar](1024) NULL,
	[AccountManagerName] [nvarchar](1024) NULL,
	[AccountManagerPhone] [varchar](1024) NULL,
	[AccountManagerEmail] [varchar](1024) NULL,
	[BrandID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Profile] PRIMARY KEY CLUSTERED 
(
	[ProfileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Emotions]') AND type in (N'U'))
DROP TABLE [dbo].[Emotions]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Emotions](
	[EmotionID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[ParentId] [int] NULL,
	[GroupId] [int] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](1024) NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] NOT NULL default(0),
 CONSTRAINT [PK_Emotions] PRIMARY KEY CLUSTERED 
(
	[EmotionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EmotionGroups]') AND type in (N'U'))
DROP TABLE [dbo].[EmotionGroups]
GO
/*
* Description: 
* Column:	
	Type: 1-Emotion, 2-Behavior
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[EmotionGroups](
	[EmotionGroupID] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [nvarchar](100) NOT NULL,
	[Type] [int] NOT NULL,
	[Descriptions] [nvarchar](500) NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] NOT NULL default(0),	
 CONSTRAINT [PK_EmotionGroups] PRIMARY KEY CLUSTERED 
(
	[EmotionGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EmotionKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[EmotionKeyword]
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[EmotionKeyword](
	[EmotionKeywordID] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Word] [nvarchar](256) NOT NULL,
	[WordWithoutAccent] [nvarchar](256) NULL,
	[Type] [int] NOT NULL,
	[EmotionID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] NOT NULL default(0),
 CONSTRAINT [PK_EmotionKeyword] PRIMARY KEY CLUSTERED 
(
	[EmotionKeywordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


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

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FanPage]') AND type in (N'U'))
DROP TABLE [dbo].[FanPage]
GO
/*
* Description:
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FanPage](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL default(newid()),
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[PageId] [nvarchar](512) NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[LatestUpdatedDate] [datetime] NULL,
 CONSTRAINT [PK_FanPage] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FanPageKeyword]') AND type in (N'U'))
DROP TABLE [dbo].[FanPageKeyword]
GO
/*
* Description:
* Column:
	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FanPageKeyword](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL default(newid()),
	[KeywordID] [int] NOT NULL,
	[FanPageID] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[IsDeleted] [bit] not null default(0),	
 CONSTRAINT [PK_FanPageKeyword] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


USE ContentCrawler
GO

ALTER DATABASE ContentCrawler
ADD FILEGROUP FactDataFG;
GO

ALTER DATABASE ContentCrawler
ADD FILE 
(
    NAME = FactData,
    FILENAME = 'E:\Database\FactData.ndf',
    SIZE = 5MB,
    MAXSIZE = 50GB,
    FILEGROWTH = 5MB
)
TO FILEGROUP FactDataFG;

DROP PARTITION FUNCTION [KeywordGUIDPartitionFunction]
GO
CREATE PARTITION FUNCTION [KeywordGUIDPartitionFunction](uniqueidentifier) AS RANGE LEFT FOR VALUES ()
GO
DROP PARTITION SCHEME [KeywordGUIDPartitionScheme]
GO
CREATE PARTITION SCHEME [KeywordGUIDPartitionScheme] AS PARTITION [KeywordGUIDPartitionFunction] ALL TO ([PRIMARY])
GO

-- create new filegroup for keyword
declare @keywordGUID Uniqueidentifier;
declare @keywordID int;
declare @fg nvarchar(100);
set @keywordID = 11
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


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Record]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[Record]
END
GO
/*
* Description:
* Columns:	
	IsReviewed:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[Record](
	[RecordID] [int] IDENTITY(1,1) NOT NULL,
	[RecordGUID] [uniqueidentifier] NOT NULL,
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](1024) NOT NULL,
	[URL] [varchar](1024) NOT NULL,	
	[Author] [nvarchar](256) NOT NULL,
	[PublishedDate] [datetime] NOT NULL ,
	[MinPublishedDate] [datetime] NULL,
	[MaxPublishedDate] [datetime] NULL,
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[IsReviewed] [bit] NOT NULL DEFAULT(0),
	[IsDeleted] [bit] NOT NULL DEFAULT(0),	
	[Irrelevant] [bit] NULL,
	[Score] [float] null,
	[CreatedBy] [int] NOT NULL default(0),
	[UpdatedBy] [int] NOT NULL default(0),	
 CONSTRAINT [PK_Record] PRIMARY KEY NONCLUSTERED 
(
	[RecordID] ASC	
)
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)ON [PRIMARY] 
GO

CREATE CLUSTERED INDEX [KeywordGUID_PublishedDate_RecordID_Index] ON [dbo].[Record]
(
	[KeywordGUID] ASC,
	[PublishedDate] ASC,
	[RecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [KeywordGUIDPartitionScheme] (KeywordGUID)
GO

CREATE NONCLUSTERED INDEX [RecordGUID] ON [dbo].[Record]
(
	[RecordGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [KeywordGUIDURLIndex] ON [dbo].[Record]
(
	[KeywordGUID] ASC,
	[URL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [KeywordGUIDPartitionScheme] (KeywordGUID) 
GO

CREATE NONCLUSTERED INDEX [KeywordGUID_IsReviewed_IsDeleted_Index] ON [dbo].[Record]
(
	[KeywordGUID] ASC,
	[IsReviewed] ASC,
	[IsDeleted] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [KeywordGUIDPartitionScheme] (KeywordGUID) 
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SubRecord]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[SubRecord]
END
GO
/*
* Description:
* Columns:	
	IsReviewed:	
	SentimentID: behavior, each comment only has one behavior
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[SubRecord](
	[SubRecordID] [int] IDENTITY(1,1) NOT NULL,	
	[SubRecordGUID] [uniqueidentifier] NOT NULL,	
	[KeywordGUID] [uniqueidentifier] NOT NULL,
	[SiteGUID] [uniqueidentifier] NOT NULL,
	[RecordID] [int] NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[URL] [nvarchar](1024) NOT NULL,
	[Author] [nvarchar](256) NOT NULL,
	[PublishedDate] [datetime] NOT NULL ,		
	[IsReviewed] [bit] NOT NULL DEFAULT(0),	
	[IsDeleted] [bit] NOT NULL DEFAULT(0),	
	[Irrelevant] [bit] NULL,
	[IsApproved] [bit] NOT NULL default(0),
	[SentimentID] [int] NULL,
	[CreatedBy] [int] NOT NULL default(0),
	[UpdatedBy] [int] NOT NULL default(0),	
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
 CONSTRAINT [PK_SubRecord] PRIMARY KEY NONCLUSTERED 
(
	[SubRecordID] ASC	
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
) ON [PRIMARY] 
GO

CREATE CLUSTERED INDEX [KeywordGUID_Index] ON [dbo].[SubRecord]
(
	[KeywordGUID] ASC,
	[SubRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [KeywordGUIDPartitionScheme] (KeywordGUID)
GO

CREATE NONCLUSTERED INDEX [RecordID_SubRecordID_Index] ON [dbo].[SubRecord]
(
	[RecordID] ASC,
	[SubRecordID] ASC
)INCLUDE ([PublishedDate])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [KeywordGUIDPartitionScheme] (KeywordGUID) 

GO
CREATE NONCLUSTERED INDEX [RecordID_IsReviewed_IsDeleted_PublishedDate_Index] ON [dbo].[SubRecord]
(
	[RecordID] ASC,
	[IsReviewed] ASC,
	[IsDeleted] ASC,
	[PublishedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [KeywordGUIDPartitionScheme] (KeywordGUID) 
GO

CREATE NONCLUSTERED INDEX [KeywordGUID_IsDeleted_PublishedDate_Index] ON [dbo].[SubRecord]
(
	[KeywordGUID] ASC,
	[IsDeleted] ASC,
	[PublishedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [KeywordGUIDPartitionScheme] (KeywordGUID) 
GO

CREATE NONCLUSTERED INDEX [KeywordGUID_SiteGUID_IsDeleted_PublishedDate_Index] ON [dbo].[SubRecord]
(
	[KeywordGUID] ASC,
	[SiteGUID] ASC,
	[IsDeleted] ASC,
	[PublishedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [KeywordGUIDPartitionScheme] (KeywordGUID) 
GO

-- full text index
CREATE FULLTEXT CATALOG [ft] WITH ACCENT_SENSITIVITY = OFF AS DEFAULT
GO
CREATE FULLTEXT INDEX ON Record ( Title Language 1066) KEY INDEX PK_Record ON ft
GO
CREATE FULLTEXT INDEX ON SubRecord (Content Language 1066) KEY INDEX PK_SubRecord ON ft


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BriefContent]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[BriefContent]
END
GO
/*
* Description:
* Columns:
* History
-------------------------------------------------------------

-------------------------------------------------------------
*/
CREATE TABLE [dbo].[BriefContent](
	[BriefContentID] [int] IDENTITY(1,1) NOT NULL,
	[RecordID] [int] NOT NULL,
	[SubRecordID] [int] NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[Sentiment] [smallint] NOT NULL DEFAULT(0),
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[IsDeleted] [bit] NOT NULL DEFAULT(0)
 CONSTRAINT [PK_BriefContentID] PRIMARY KEY CLUSTERED 
(
	[BriefContentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
) ON [FactDataFG]
GO

CREATE NONCLUSTERED INDEX [SubRecodID_IsDeleted] ON [dbo].[BriefContent]
(
	[SubRecordID] ASC,
	[IsDeleted] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [FactDataFG]
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
	[BriefContentID] [int] NOT NULL,
	[SubRecordID] [int] NOT NULL,
	[TagGroupGUID] [uniqueidentifier] NOT NULL,
	[TagGUID] [uniqueidentifier] NOT NULL,
	[InsertedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[UpdatedDate] [datetime] NOT NULL DEFAULT (getdate()),
	[IsDeleted] [bit] NOT NULL DEFAULT(0),	
	[UserID] [int] NOT NULL,
 CONSTRAINT [PK_BriefContentTag] PRIMARY KEY CLUSTERED 
(
	[BriefContentTagID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
) ON [FactDataFG]
GO


-- rebuild indexes
USE [ContentCrawler]
GO
ALTER INDEX [PK_Record] ON [dbo].[Record] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [RecordGUID] ON [dbo].[Record] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [KeywordGUID_PublishedDate_RecordID_Index] ON [dbo].[Record] REORGANIZE WITH ( LOB_COMPACTION = ON )GO
GO
ALTER INDEX [KeywordGUIDURLIndex] ON [dbo].[Record] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [KeywordGUID_IsReviewed_IsDeleted_Index] ON [dbo].[Record] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO


USE [ContentCrawler]
GO
ALTER INDEX [PK_SubRecord] ON [dbo].[SubRecord] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [RecordID] ON [dbo].[SubRecord] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [KeywordGUID_SiteGUID_IsDeleted_PublishedDate_Index] ON [dbo].[SubRecord] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO

USE [ContentCrawler]
GO
ALTER INDEX [PK_BriefContentTag] ON [dbo].[BriefContentTag] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [PK_BriefContentID] ON [dbo].[BriefContent] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [SubRecodID_IsDeleted] ON [dbo].[BriefContent] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO

USE [WareHouse]
GO
ALTER INDEX [PK_DIMTIME] ON [dbo].[DimTime] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [DimTimeID_KeywordID_SiteID] ON [dbo].[FactKeywordAuthor] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [PK_FactKeywordAuthor] ON [dbo].[FactKeywordAuthor] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [PK_FactKeywordSite] ON [dbo].[FactKeywordSite] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
ALTER INDEX [PK_FactKeywordSiteEmotion] ON [dbo].[FactKeywordSiteEmotion] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO


USE WareHouse
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ETLDashboardAudit]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[ETLDashboardAudit]
END
GO
/*
* Description: sum the total reviewed comments
* Column:
	Total: 
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[ETLDashboardAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ETLStartDate] [datetime] NOT NULL,
	[ETLEndDate] [datetime] NOT NULL,
	[Status] [char](10) NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[BriefContentID] [int] NOT NULL,
 CONSTRAINT [PK_ETLDashboardAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactKeywordSite]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactKeywordSite]
END
GO
/*
* Description: sum the total reviewed comments
* Column:
	Total: 
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactKeywordSite](
	[SiteID] [int] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[DimTimeID] [int] NOT NULL,
	[Total] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
 CONSTRAINT [PK_FactKeywordSite] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC,
	[KeywordID] ASC,
	[DimTimeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactKeywordAuthor]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactKeywordAuthor]
END
GO
/*
* Description: count author of reviewed comment
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactKeywordAuthor](
	[KeywordID] [int] NOT NULL,
	[SiteID] [int] NOT NULL,
	[DimTimeID] [int] NOT NULL,
	[Author] [nvarchar](512) NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
	[Total] [int] NOT NULL,
	CONSTRAINT [PK_FactKeywordAuthor] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC,
	[SiteID] ASC,	
	[DimTimeID] ASC,
	[Author] ASC	
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactKeywordSiteEmotion]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[FactKeywordSiteEmotion]
END
GO
/*
* Description: 
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
CREATE TABLE [dbo].[FactKeywordSiteEmotion](
	[SiteID] [int] NOT NULL,
	[KeywordID] [int] NOT NULL,
	[DimTimeID] [int] NOT NULL,
	[Sentiment] [int] NOT NULL,
	[Total] [int] NOT NULL,
	[InsertedDate] [datetime] NOT NULL default(getdate()),
	[UpdatedDate] [datetime] NOT NULL default(getdate()),
 CONSTRAINT [PK_FactKeywordSiteEmotion] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC,
	[KeywordID] ASC,
	[DimTimeID] ASC,
	[Sentiment] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimTime]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[DimTime]
END
GO
/*
* Description: 
* Column:
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--indexes
CREATE NONCLUSTERED INDEX [DimTimeID_KeywordID_SiteID] ON [dbo].[FactKeywordAuthor]
(
	[DimTimeID] ASC,
	[KeywordID] ASC,
	[SiteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [PRIMARY]
GO


/* store keyword info, used as a queue to copy data*/
USE DataCopyLog
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KeywordCopyInfo]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[KeywordCopyInfo]
END
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
create table KeywordCopyInfo
(	
	KeywordID [int] NOT NULL,	
	LatestCopyRecordID [int] NOT NULL,
	LatestCopySubRecordID [int] NOT NULL,	
	IsRunning [bit] NOT NULL,
	RunningDate [datetime] NULL,
	InsertedDate [datetime] NOT NULL,
	UpdatedDate [datetime] NOT NULL,
CONSTRAINT [PK_KeywordID] PRIMARY KEY CLUSTERED 
(
	[KeywordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KeywordCopyLog]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[KeywordCopyLog]
END
GO
/*
* Description: 
* Column:
	Status: 1-active, 0-inactive
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
create table KeywordCopyLog
(	
	[KeywordCopyLogID] [int] NOT NULL identity(1,1),
	KeywordID [int] NOT NULL,
	FromRecordID [int] NOT NULL,
	ToRecordID [int] NOT NULL,
	FromSubRecordID [int] NOT NULL,
	ToSubRecordID [int] NOT NULL,
	Records [int] NOT NULL,
	SubRecords [int] NOT NULL,
	StartDate [datetime] NULL,
	EndDate [datetime] NULL,
	[Status] [varchar](50) NULL,
	InsertedDate [datetime] NOT NULL,
	UpdatedDate [datetime] NOT NULL,
	Logs [nvarchar](max) NULL,
CONSTRAINT [PK_KeywordCopyLogID] PRIMARY KEY CLUSTERED 
(
	[KeywordCopyLogID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RecordCopyLog]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[RecordCopyLog]
END
GO
/*
* Description: 
* Column:	
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
create table RecordCopyLog
(
	RecordCopyLogID [int] NOT NULL identity(1,1),
	KeywordID [int] NOT NULL,	
	RecordID [int] NOT NULL,
	DHRecordID [int] NOT NULL,
	SubRecords [int] NOT NULL,
	PublishedDate [datetime] NOT NULL,
	InsertedDate [datetime] NOT NULL,
	UpdatedDate [datetime] NOT NULL,
	Logs [nvarchar](max) NULL,
CONSTRAINT [PK_RecordCopyLogID] PRIMARY KEY CLUSTERED 
(
	[RecordCopyLogID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExistedRecordCopyQueue]') AND type in (N'U'))
BEGIN
DROP TABLE [dbo].[ExistedRecordCopyQueue]
END
GO
/*
* Description: 
* Column:	
	Status: 1: available, 2: running, 3: executed successfully, 4: fail
* History
-------------------------------------------------------------
-------------------------------------------------------------
*/
create table ExistedRecordCopyQueue
(	
	ExistedRecordCopyQueueID [int] identity(1,1) NOT NULL,	
	FromSubRecordID [int] NOT NULL,
	ToSubRecordID [int] NOT NULL,	
	Status [int] NOT NULL,
	RunningDate [datetime] NULL,
	InsertedDate [datetime] NOT NULL,
	UpdatedDate [datetime] NOT NULL,
	SubRecords [int] NULL,
	Logs [nvarchar](max) NULL,
CONSTRAINT [PK_ExistedRecordCopyQueueID] PRIMARY KEY CLUSTERED 
(
	[ExistedRecordCopyQueueID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF OBJECT_ID ('KeywordInserted_CopyData', 'TR') IS NOT NULL
--   DROP TRIGGER KeywordInserted_CopyData;
--GO
--CREATE TRIGGER KeywordInserted_CopyData ON ContentAggregator.dbo.Keyword
--FOR INSERT
--AS
--	INSERT INTO [DataCopy].dbo.KeywordCopyInfo (KeywordID, LastestCopyRecordID, LastestCopySubRecordID, IsRunning, RunningDate, InsertedDate, UpdatedDate)        
--    SELECT ins.[KeywordID], 0, 0, 0, null, getdate(), GETDATE()
--    FROM inserted ins

--GO
