@echo off
cls
color 71
rem ===========================================================
:MENU
echo  ########################################################
echo  #                                                      #
echo  #                    CONNECTION                        #
echo  #             BaiXiongMao [172.16.100.34]              #
echo  #                                                      #
echo  ########################################################
echo.

rem ===========================================================
echo --)  Remove previous network disks association
net use w: /d /y
net use x: /d /y
net use y: /d /y
net use z: /d /y
echo.

rem ===========================================================
echo --)  connection check

REM Put all ping results in temp directory for analysis
ping -n 4 172.16.100.34 > %temp%\pingg.txt

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
echo      (W) = DEV
echo      (X) = DOCS
echo      (Y) = DIVERS
echo      (Z) = DIVERS2
echo.
echo.
net use w: \\172.16.100.34\DEV /user:scan /persistent:no
net use x: \\172.16.100.34\DOCS /user:scan /persistent:no
net use y: \\172.16.100.34\DIVERS /user:scan /persistent:no
net use z: \\172.16.100.34\DIVERS2 /user:scan /persistent:no

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
echo 2. Check that current network location is not set as 'public' in network settings
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

