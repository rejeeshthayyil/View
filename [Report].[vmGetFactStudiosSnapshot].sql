USE [Onlinestore]
GO

/****** Object:  View [Report].[vmGetFactStudiosSnapshot]    Script Date: 20/11/2023 21:18:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--select * from Report.FactStudiosSnapshot

CREATE view [Report].[vmGetFactStudiosSnapshot]
AS
WITH cte_main_studio_data
as(
select 
 ss.OptionID
,ss.ShootDateId
,ss.ProductID
,ss.SKU
,ss.StudioId
,ss.ShootTypeId
,ss.ShootTimeId
,ss.LifecycleStatusid
,ss.UserId
,ss.OverrideReasonCodeId
,ss.RejectionReasonCodeId
,ss.EventTypeId
,CASE
	when COUNT(DISTINCT ss.[VideoShotYN])=1
		then Max( ss.[VideoShotYN])
		else null
	end as [VideoShotYN],

CASE
	when COUNT(DISTINCT isnull (ss.[VideoShotYN],-1))=1
		then Max( ss.[VideoShotYN])
		else null
	end as [ShotYN],
	MAX(SS.LastUpdatedTimeStamp) as LastUpdatedTimeStamp_UTC,
	dateadd(minute, datepart(tz, max(ss.LastUpdatedTimeStamp) AT TIME ZONE 'GMT STANDARD TIME'), MAX(SS.LastUpdatedTimeStamp)) as 
	LastUpdatedTimeStamp,
	ss.ShootNotes,
	ss.RejectioinComments,
	ss.ModelName as model
	
	from Report.FactStudiosSnapshot ss
	left join Report.dimstudio st on ss.studioid=st.studioid
	where ss.goalid is not null
	and st.studioName <> 'Brand Image'
	group by
	ss.OptionID
	,ss.ShootDateId
	,ss.ProductID
	,ss.SKU
	,ss.StudioId
	,ss.ShootTypeId
	,ss.ShootTimeId
	,ss.LifecycleStatusid
	,ss.UserId
	,ss.OverrideReasonCodeId
	,ss.RejectionReasonCodeId
	,ss.EventTypeId
	,ss.shootNotes
	,ss.RejectioinComments
	,ss.ModelName
	,ss.EventTimeStamp
	)
	--======================================done==============================================

	select DISTINCT SS.LastUpdatedTimeStamp,
	dt.StandardDate,
	ss.ProductID,
	ss.SKU,
	studio.StudioName as Studio,
	stime.ShootTimeName as [ Shoot Time],

	case when stype.ShootTypeNameForReports = 'NonModelAccessories'
	then 'Still life'

	when stype.ShootTypeNameForReports = 'NonModelClothing'
	then 'Clothing Flats'

	when stype.ShootTypeNameForReports = 'ModelFootwear'
	then 'Footwear'


	when stype.ShootTypeNameForReports = 'ModelAtHome'
	then 'MAH'

	when stype.ShootTypeNameForReports = 'StylistsAtHome'
	then 'SAH'

	else 

	pcat.HierarchTag

	end as [Product Type],

	case 
		when ss.[shotYN]=0 --not shot
		or ss.VideoShotYN IS NOT NULL
		THEN RRC.Reason -- shoot issue to be display
	
	when (ss.shotYN !=0
	 or ss.shotYN is null --shot
	 )

	 and ss.VideoShotYN =0 --overriden

	 then 'overrid'
	 else null
	 end as [ Video not shoot reason],
	 
	 case 
	 when ss.VideoShotYN= 1
	 then 'Y'
	  when ss.VideoShotYN= 0
	 then 'N'

	 else null
	 end as  [Video Y/N],

	 case 
	 when ss.shotYN =1
	 then 'Y'

	 when ss.shotYN =0
	 then 'N'

	 else null
	 end as [shot Y/N],

	 ss.OptionID,
	 p.productTitle as Description,
	 o.ColourGroup + '('+ o.WebsiteColour + ')'  as Colour,
	 case
		when ss.lifecycleStatusId =1 
		then null
		else lfs.LifeCycleStatusName
		end as [Reshoot/agile Zen],
		p. Gender as Gender,
		p.ProductType as pimProducType,
		stype.ShootTypeNameForReports As [Shoot Type],
		pp.segment,
		pp.[Production End Use] as EndUse,
		pp.[Shop by fit/Range] asRange,
		ss.Model,
		o.stylingGuide as [StylingGuide Y/N],
		ss.shootnotes as ShootOpsComments,
		SKU AS[WareHouse SKU],
		p.Brand,
		pp.[Retail Buying Divion],
		rrc.Reason as ShootIssue,
		rrc.reasonSubCategory as ShootOutCome,
		case
			when ss.rejectionReasonCodeId between 9 and 16 
			then RTRIM(LTRIM(SUBSTRING(SS.RejectioinComments,charindex('Studio',ss.RejectioinComments)+ LEN('STUDIO:'),(charindex('Comment:',
			ss.RejectioinComments)-len('Comment:'))-Charindex('Studio:', ss.RejectioinComments))))
			else ''
			end as [StsudioSwapMovingTo],
			case
			when ss.rejectionReasonCodeId between 9 and 16 
			then RTRIM(LTRIM(SUBSTRING(SS.RejectioinComments,charindex('comment:',ss.RejectioinComments)+ LEN('comment:'),
			len(ss.RejectioinComments)- charindex('comment:',ss.RejectioinComments)+ LEN('comment:')-1))) 
			else ss.RejectioinComments
			end as Studiocomments,

			stime.shoottimename+ convert(varchar(8),  ss.shootdateId) + studio.studioname as [unique - studio space],
			p.gender + case
				when stype.ShootTypeNameForReports = 'NonModelAccessories'
					then 'Still life'

				when stype.ShootTypeNameForReports = 'NonModelClothing'
					then 'Clothing Flats'

				when stype.ShootTypeNameForReports = 'ModelFootwear'
					then 'Footwear'


				when stype.ShootTypeNameForReports = 'ModelAtHome'
					then 'MAH'

				when stype.ShootTypeNameForReports = 'StylistsAtHome'
					then 'SAH'

				else pcat.HierarchTag
				end + stype.ShootTypeNameForReports +
				
				 case 
					when ss.shotYN =1
						then 'Y'

					when ss.shotYN =0
						then 'N'

					else null
					end  as [GenderProduct typeshoot typeshot Y/N],
				p.gender + stype.ShootTypeNameForReports +case
				when ss.lifecycleStatusId =1 
					then null
				else lfs.LifeCycleStatusName
				end +
				case 
				when ss.shotYN =1
						then 'Y'

					when ss.shotYN =0
						then 'N'

					else null
					end as [GenderShoot TypeReshoot/Agile Zenshot Y/N],
					case 
						when ss.shotYN =0
							then p.gender + stype.ShootTypeNameForReports+rrc.Reason
							else null
							end as [GenderShoot TypeShootIssue],
					case
						when ss.VideoShotYN =null
						then null
						else  p.gender + stype.ShootTypeNameForReports+ case
						 when ss.shotYN =1
							 then 'Y'

						when ss.shotYN =0
							then 'N'

						end + case
						when ss.[shotYN]=0 --notshot
							then rrc.reason --shoot issue to be displyed
						when ss.[shotYN]=0 --not shot
						and ss.VideoShotYN =0 --overriden
						THEN ' overriden' --displye override
						else''
						end
						end as [GenderShoot TypeVideo Y/Nvideo not shoot Reason],
						case
							when ss.[shotYN]=0 -- when shoot is rejected
								then p.gender + stype.ShootTypeNameForReports+rrc.ReasonsubCategory
							else null
							end as [GenderShoot TypeShootOutCome]



	from cte_main_studio_data as ss
	inner join Report.DimProduct p on ss.productid=p.productId
	inner join report.vmProductInfo pp on ss.productid=p.productId
	inner join Report.DimOption o on ss.optionid=o.OptionId
	inner join report.DimShootType stype on ss.shoottypeid=stype.LastUpdatedTimeStamp
	inner join Report.DimStudio studio on ss.studioId=studio.StudioId
	inner join Report.DimDate dt on ss.ShootDateId=dt.DateId
	inner join Report.DimShootTime stime on ss.ShootTimeId=stime.ShootTimeId
	inner join Report.DimLifecycleStatus lfs on ss.LifecycleStatusid=lfs.LifecycleStatusid
	inner join Report.DimUser u on ss.UserId=u.UserId
	inner join Report.DimReasonCode rrc on ss.RejectionReasonCodeId=rrc.ReasonId
	inner join Report.DimEventType etype on ss.EventTypeId=etype.EventTypeId
	inner join Report.DimProductCategory pcat on p.productType =pcat.ProductType
GO


