use Security
GO

insert into aspnet_Applications (ApplicationName, LoweredApplicationName, ApplicationId, Description)
values ('/','/',N'C021FEED-3053-4036-9681-D1DF343B8E7B', null)
GO

INSERT [dbo].[aspnet_Roles] ([ApplicationId], [RoleId], [RoleName], [LoweredRoleName], [Description]) VALUES (N'C021FEED-3053-4036-9681-D1DF343B8E7B', N'1c23c820-0a5d-4c96-9f78-62e6b53868c9', N'Administrator', N'administrator', NULL)
INSERT [dbo].[aspnet_Roles] ([ApplicationId], [RoleId], [RoleName], [LoweredRoleName], [Description]) VALUES (N'C021FEED-3053-4036-9681-D1DF343B8E7B', N'69549240-ee08-4f91-a333-b648a0bc5375', N'Brand User', N'brand user', NULL)
INSERT [dbo].[aspnet_Roles] ([ApplicationId], [RoleId], [RoleName], [LoweredRoleName], [Description]) VALUES (N'C021FEED-3053-4036-9681-D1DF343B8E7B', N'45ae4c1e-3b72-4fd6-ab9d-945a3d7cc9cb', N'Content Support', N'content support', NULL)
INSERT [dbo].[aspnet_Roles] ([ApplicationId], [RoleId], [RoleName], [LoweredRoleName], [Description]) VALUES (N'5545842D-8263-4928-B499-F20230F5C95C', N'294254D3-4229-4BC9-AEE4-99914569C0A4', N'Manager', N'manager', NULL)
GO
INSERT [dbo].[aspnet_Users] ([ApplicationId], [UserId], [UserName], [LoweredUserName], [MobileAlias], [IsAnonymous], [LastActivityDate]) VALUES (N'C021FEED-3053-4036-9681-D1DF343B8E7B', N'61578401-9e0a-463c-8afd-d8b44744d0d2', N'admin', N'admin', NULL, 0, CAST(0x00009F1000EE5EF7 AS DateTime))
GO
INSERT [dbo].[aspnet_UsersInRoles] ([UserId], [RoleId]) VALUES (N'61578401-9e0a-463c-8afd-d8b44744d0d2', N'1c23c820-0a5d-4c96-9f78-62e6b53868c9')

GO
INSERT [dbo].[aspnet_Membership] ([ApplicationId], [UserId], [Password], [PasswordFormat], [PasswordSalt], [MobilePIN], [Email], [LoweredEmail], [PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowStart], [Comment]) VALUES (N'C021FEED-3053-4036-9681-D1DF343B8E7B', N'61578401-9e0a-463c-8afd-d8b44744d0d2', N'Sak+MHx4l5vFzEWqgoVQeIjTKGY=', 1, N'2DctE1crhLRBw59Tc5z8WA==', NULL, N'haivu@hotmail.com', N'haivu@hotmail.com', NULL, NULL, 1, 0, CAST(0x00009E7400B56134 AS DateTime), CAST(0x00009F1000EE5EF7 AS DateTime), CAST(0x00009E7400B56134 AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)

USE ContentAggregator
GO
INSERT INTO UserDetail (GUID, UserName, CustomerID, FullName, Email, InsertedDate, UpdatedDate, IsActive)
values (NEWID(), N'admin', 0, N'Admin','', GETDATE(), GETDATE(), 1 )
GO
