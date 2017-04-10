# Build sql server 2014 express image listening on static port 1433,
# with support for data internal-to-container or on host
#
# May be customized for any other sql server edition
#
# IMAGE USAGE:
#   detached, data in container:
#     docker run -d -p <hostport>:1433 <imagename>
#   detached, data on host:
#     docker run -d -p <hostport>:1433 -v <hostsqldir>:c:\sql <imagename>
#
#   interactive, data in container:
#     docker run -it -p <hostport>:1433 <imagename> "powershell ./start"
#   interactive, data on host:
#     docker run -it -p <hostport>:1433 -v <hostsqldir>:c:\sql <imagename> "powershell ./start"
#
#   example: build image then run, teardown two SxX multiple sql server containers with
#   persistent data volumes on host (detached)
#     docker build -t sqlexpress .
#     docker run --name sql -d -p 1433:1433 -v c:\sql:c:\sql  sqlexpress
#     docker run --name sql2 -d -p 1434:1433 -v c:\sql2:c:\sql sqlexpress
#     docker stop sql
#     docker stop sql2
#     docker rm -f sql
#     docker rm -f sql2
#
# PRECONDITIONS:
#   Docker context folder must contain the following dependencies:
#     Set-SqlExpressStaticTcpPort.ps1
#     Move-dirs-and-stop-service.ps1
#     start.ps1

# .NET 3.5 required for SQL Server
FROM docker.io/microsoft/dotnet35:windowsservercore

ENV sqlinstance SQL2012
ENV sqlsapassword P@ssw0rd
ENV sql c:\\sql
ENV sqldata c:\\sql\\data
ENV sqlbackup c:\\sql\\backup


/x:/setup.exe /QUIETSIMPLE /ACTION=install /FEATURES=SQL /INSTANCENAME=%sqlinstance% \
/TCPENABLED=1 /IACCEPTSQLSERVERLICENSETERMS /SQLSVCACCOUNT="NT Authority\System"  \
/SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /AGTSVCACCOUNT="NT Authority\System" \
/SECURITYMODE=SQL /SAPWD=%sqlsapassword% /INSTALLSQLDATADIR=%sqldata% /SQLBACKUPDIR=%sqlbackup% 
/SQLTEMPDBDIR="C:\SQL\TempDB\\" /SQLUSERDBDIR="C:\SQL\SQLData\\" /SQLUSERDBLOGDIR=%sqldata%

COPY . /install
WORKDIR /install 
powershell /install/Set-SqlExpressStaticTcpPort %sqlinstance% \
&& powershell /install/Move-dirs-and-stop-service %sqlinstance% %sql% %sqldata% %sqlbackup%
EXPOSE 1433
CMD powershell /install/start detached %sqlinstance% %sqldata% %sqlbackup%
