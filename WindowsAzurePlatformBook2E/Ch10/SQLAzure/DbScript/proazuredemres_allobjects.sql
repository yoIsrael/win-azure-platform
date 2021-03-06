
CREATE TABLE [dbo].[PricingLocations](
	[LocationId] [int] NOT NULL PRIMARY KEY CLUSTERED ,
	[Description] [varchar](100) NOT NULL)
	GO
CREATE TABLE [dbo].[PricingCalendar_kWh](
	[PricingId] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED ,
	[PricingStartDate] [datetime] NOT NULL,
	[PricingEndDate] [datetime] NOT NULL,
	[PricePerkWh] [float] NOT NULL,
	[LocationId] [int] NOT NULL)
GO

CREATE PROCEDURE [dbo].[InsertPricingLocations]
	@locationId int,
	@description varchar(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  INSERT INTO PricingLocations(LocationId, [Description]) VALUES (@locationId, @description);
   
END
GO

CREATE TABLE [dbo].[Gateways](
	[GatewayNumber] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED ,
	[GatewayId] [varchar](50) NOT NULL,
	[LastCommunication] [datetime] NULL,
	[LocationId] [int] NOT NULL,
	[WebAddress] [varchar](100) NOT NULL)
GO
CREATE TABLE [dbo].[EnergyMeterValues](
	[RecordId] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED ,
	[GatewayNumber] [int] NOT NULL,
	[GatewayId] [varchar](50) NOT NULL,
	[kWhValue] [float] NOT NULL,
	[kWhFieldRecordedTime] [datetime] NOT NULL,
	[kWhServerTime] [datetime] NOT NULL,
	[Cost] [float] NOT NULL)
 
GO
CREATE PROCEDURE [dbo].[InsertPricingCalendar_kWh]
	@pricingStartDate datetime,
	@pricingEndDate datetime,
	@pricePerkWh float,
	@locationId int
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO PricingCalendar_kWh(PricingStartDate, PricingEndDate, PricePerkWh, LocationId)
  VALUES (@pricingStartDate, @pricingEndDate, @pricePerkWh, @locationId);
   
    
END
GO

CREATE PROCEDURE [dbo].[InsertGateway]
	@gatewayId varchar(50),
	@locationId int,
	@webAddress varchar(100)
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO Gateways(GatewayId, LocationId, WebAddress, LastCommunication) VALUES (@gatewayId, @locationId, @webAddress, getdate());
   
END
GO

CREATE PROCEDURE [dbo].[InsertEnergyMeterValues]
	@gatewayId varchar(50),
	@kWhValue float,
	@kWhFieldRecoredTime datetime,
	@kWhServerTime datetime
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @gatewayNumber int
  DECLARE @cost float
  DECLARE @locationId int
  
  SELECT @gatewayNumber = GatewayNumber, @locationId=LocationId FROM Gateways WHERE GatewayId = @gatewayId;
  
  SELECT @cost=PricePerkWh FROM PricingCalendar_kWh WHERE LocationId = @locationId;
  
  SET @cost = @cost * @kWhValue;
  
  INSERT INTO EnergyMeterValues(GatewayNumber, GatewayId, kWhValue, kWhFieldRecordedTime, kWhServerTime, Cost) 
  VALUES (@gatewayNumber, @gatewayId, @kWhValue, @kWhFieldRecoredTime, @kWhServerTime, @cost);
   
    
END
GO
CREATE PROCEDURE [dbo].[UpdateGatewayLastCommunication]
	@gatewayId varchar(50),
	@locationId int,
	@webAddress varchar(100)
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE Gateways SET LastCommunication = getdate() WHERE GatewayId = @gatewayId
   
END
GO
CREATE PROCEDURE AddSampleData
@NumRows int
AS
DECLARE @counter int
DECLARE @locationId int
DECLARE @locationIdStr varchar(50)
DECLARE @desc varchar(50)
DECLARE @pricingStartDate datetime
DECLARE @pricingEndDate datetime
DECLARE @pricekWh float
DECLARE @gatewayUrl varchar(100)
DECLARE @gatewayId varchar(50)
DECLARE @kWhValue float
DECLARE @now datetime


SELECT @counter = 1
WHILE (@counter < @NumRows)
BEGIN

SET @locationId = 10000 + @counter;
SET @locationIdStr = CAST(@locationId as varchar);
SET @desc =  @locationIdStr + '-' + CAST(@counter as nvarchar)+'-description';
SET @pricingStartDate = DATEADD(m, 2, getdate());
SET @pricingEndDate = DATEADD(m, 3, getdate());
SET @pricekWh = CAST(@counter as float)* 0.00052;
SET @gatewayId = 'MyGateway' + @locationIdStr;
SET @gatewayUrl = 'sb://proazure.servicebus.windows.net/gateways/' + @locationIdStr + '/' + @gatewayId;
SET @kWhValue = @pricekWh * 5.2;
SET @now = getdate();

   EXEC InsertPricingLocations @locationId, @desc;
   EXEC InsertPricingCalendar_kWh @pricingStartDate, @pricingEndDate, @pricekWh, @locationId;
   EXEC InsertGateway @gatewayId, @locationId, @gatewayUrl;
   EXEC InsertEnergyMeterValues @gatewayId, @kWhValue, @now, @now;

   SELECT @counter = @counter + 1;
   
END
GO
CREATE PROCEDURE DROPSAMPLEDATA
AS
BEGIN
 DELETE FROM EnergyMeterValues;
 DELETE FROM Gateways;
 DELETE FROM PricingCalendar_kWh;
 DELETE FROM PricingLocations;

END

GO
/****** Object:  ForeignKey [FK_PricingCalendar_kWh_PricingLocations]    Script Date: 08/27/2009 16:36:11 ******/
ALTER TABLE [dbo].[PricingCalendar_kWh]  WITH CHECK ADD  CONSTRAINT [FK_PricingCalendar_kWh_PricingLocations] FOREIGN KEY([LocationId])
REFERENCES [dbo].[PricingLocations] ([LocationId])
GO
ALTER TABLE [dbo].[PricingCalendar_kWh] CHECK CONSTRAINT [FK_PricingCalendar_kWh_PricingLocations]
GO
/****** Object:  ForeignKey [FK_Gateways_PricingLocations]    Script Date: 08/27/2009 16:36:13 ******/
ALTER TABLE [dbo].[Gateways]  WITH CHECK ADD  CONSTRAINT [FK_Gateways_PricingLocations] FOREIGN KEY([LocationId])
REFERENCES [dbo].[PricingLocations] ([LocationId])
GO
ALTER TABLE [dbo].[Gateways] CHECK CONSTRAINT [FK_Gateways_PricingLocations]
GO
/****** Object:  ForeignKey [FK_EnergyMeterValues_Gateways]    Script Date: 08/27/2009 16:36:13 ******/
ALTER TABLE [dbo].[EnergyMeterValues]  WITH CHECK ADD  CONSTRAINT [FK_EnergyMeterValues_Gateways] FOREIGN KEY([GatewayNumber])
REFERENCES [dbo].[Gateways] ([GatewayNumber])
GO
ALTER TABLE [dbo].[EnergyMeterValues] CHECK CONSTRAINT [FK_EnergyMeterValues_Gateways]
GO

CREATE PROCEDURE [dbo].[GetEnergyCostByGatewayId]
	@gatewayId varchar(50)
	
AS
BEGIN
  SET NOCOUNT ON;
  SELECT  PricingCalendar_kWh.PricePerkWh 
  FROM Gateways 
  INNER JOIN PricingLocations ON Gateways.LocationId = PricingLocations.LocationId 
  INNER JOIN PricingCalendar_kWh ON PricingLocations.LocationId = PricingCalendar_kWh.LocationId
  WHERE (Gateways.GatewayId = @gatewayId);
  
      
END
GO