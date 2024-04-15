USE [master]
GO

CREATE DATABASE Appraisal360DB
GO

USE [Appraisal360DB]
GO

-- CREATE TABLE Customers([CustomerID] int NOT NULL, [CustomerName] varchar(30) NOT NULL)
-- GO

-- INSERT INTO Customers (CustomerID, CustomerName) VALUES (30, 'CANNON TOOLS'),
--                                                         (90, 'INTERNATIONAL BANK'),
--                                                         (130, 'SUN DIAL CITRUS')

-- change DB recovery model to FULL and take full backup
ALTER DATABASE [Appraisal360DB] SET RECOVERY FULL ;
GO

BACKUP DATABASE [Appraisal360DB] TO DISK = N'/var/opt/mssql/backup/Appraisal360DB.bak'
WITH NOFORMAT, NOINIT, NAME = N'Appraisal360DB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10
GO

USE [master]
GO

-- create logins for AG
CREATE LOGIN ag_login WITH PASSWORD = 'AGPa5SMord357y35th' ;
CREATE USER ag_user FOR LOGIN ag_login;

-- create a master key and certificate
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'AGPa5SMord357y35th' ;
GO
CREATE CERTIFICATE ag_certificate WITH SUBJECT = 'ag_certificate' ;

-- Copy to the same directory on secondary replicas
BACKUP CERTIFICATE ag_certificate
TO FILE = '/var/opt/mssql/ag_certificate.cert'
WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/ag_certificate.key',
    ENCRYPTION BY PASSWORD = 'AGPa5SMord357y35th'
);
GO


-- Create AG endpoint on port 5022
CREATE ENDPOINT [AG_endpoint]
STATE = STARTED
AS TCP (
    LISTENER_PORT = 5022,
    LISTENER_IP = ALL
)
FOR DATA_MIRRORING(
    ROLE = ALL,
    AUTHENTICATION = CERTIFICATE ag_certificate,
    ENCRYPTION = REQUIRED ALGORITHM AES
)


-- Create AG primary replica
CREATE AVAILABILITY GROUP [K8sAG]
WITH (
    CLUSTER_TYPE = NONE,
    REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 2 
)
FOR REPLICA ON 
    N'appraisal-instance1' WITH(
        ENDPOINT_URL = N'tcp://appraisal-instance1:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        SEEDING_MODE = AUTOMATIC,
        FAILOVER_MODE = MANUAL,
        SECONDARY_ROLE (
            ALLOW_CONNECTIONS = ALL,   
            READ_ONLY_ROUTING_URL = N'tcp://appraisal-instance1:1433'
        ),
         PRIMARY_ROLE (
            ALLOW_CONNECTIONS = READ_WRITE,   
            READ_ONLY_ROUTING_LIST = (N'appraisal-instance3', N'appraisal-instance2'),
            READ_WRITE_ROUTING_URL = N'tcp://appraisal-instance1:1433'
        ),
         SESSION_TIMEOUT = 10  
    ),
    N'appraisal-instance2' WITH(
        ENDPOINT_URL = N'tcp://appraisal-instance2:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        SEEDING_MODE = AUTOMATIC,
        FAILOVER_MODE = MANUAL,
        SECONDARY_ROLE (
            ALLOW_CONNECTIONS = ALL,   
            READ_ONLY_ROUTING_URL = N'tcp://appraisal-instance2:1433'
        ),
         PRIMARY_ROLE (
            ALLOW_CONNECTIONS = READ_WRITE,   
            READ_ONLY_ROUTING_LIST = (N'appraisal-instance1', N'appraisal-instance3'),
            READ_WRITE_ROUTING_URL = N'tcp://appraisal-instance2:1433'
        ),
         SESSION_TIMEOUT = 10  
    ),
    N'appraisal-instance3' WITH(
        ENDPOINT_URL = N'tcp://appraisal-instance3:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        SEEDING_MODE = AUTOMATIC,
        FAILOVER_MODE = MANUAL,
        SECONDARY_ROLE (
            ALLOW_CONNECTIONS = ALL,   
            READ_ONLY_ROUTING_URL = N'tcp://appraisal-instance3:1433'
        ),
         PRIMARY_ROLE (
            ALLOW_CONNECTIONS = READ_WRITE,   
            READ_ONLY_ROUTING_LIST = (N'appraisal-instance1', N'appraisal-instance2'),
            READ_WRITE_ROUTING_URL = N'tcp://appraisal-instance3:1433'
        ),
         SESSION_TIMEOUT = 10  
    )

-- Add database to AG
USE [master]
GO

ALTER AVAILABILITY GROUP [K8sAG] ADD DATABASE [Appraisal360DB]
GO



sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'max server memory', 4096;
GO
RECONFIGURE;
GO