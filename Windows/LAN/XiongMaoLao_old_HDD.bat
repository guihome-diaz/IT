@echo off
cls
color 71
rem ===========================================================
rem Affichage
rem ===========================================================
:MENU
echo  ###########################################################
echo  #                                                         #
echo  #                    CONNECTION                           #
echo  #             XiongMaoLao HDD [172.16.100.41]             #
echo  #                                                         #
echo  ###########################################################
echo.

rem ===========================================================
echo --)  Remove previous network disks association
net use o: /d /y
echo.

rem ===========================================================
echo --)  connection check

REM Put all ping results in temp directory for analysis
ping -n 4 172.16.100.41 > %temp%\pingg.txt

REM tests if server is available or not
find "Perdu = 4" %temp%\pingg.txt > nul
if not %ERRORLEVEL%==0 goto TEST2
goto NOPINGG

:TEST2
find "Lost = 4" %temp%\pingg.txt > nul
if not %ERRORLEVEL%==0 goto TEST3
goto NOPINGG

:TEST3
find "inconnu" %temp%\pingg.txt > nul
if not %ERRORLEVEL%==0 goto CONNECTION_OK
goto NOPINGG

rem ===========================================================
:CONNECTION_OK
echo.
echo --)  Server is UP
echo      (O) = PUBLIC
echo.
echo.
net use o: \\172.16.100.41\PUBLIC /persistent:no
echo.
pause
goto EXIT

rem ===========================================================
:NOPINGG
color FC
cls
echo.
echo  ###########################################################
echo  #                      ! FAILURE !                  	    #
echo  #                server is not reachable                  #
echo  ###########################################################
echo.
echo.
echo 1. Check your network connection
echo 2. Check that current network location is not set as PUBLIC in network settings
echo 3. Ensure that the remote server is up (check the IP@ earlier on)
echo 4. Ensure that the network is using IP v4
echo 5. Ensure that the remote server accepts your network IP@ (subnet, vlan)
echo 6. Edit the script and check credentials
echo.
echo Tutorial: https://www.rizonesoft.com/solve-network-scan-to-folder-not-working/
echo.
echo.
pause
goto EXIT

:EXIT
cls
color 07
