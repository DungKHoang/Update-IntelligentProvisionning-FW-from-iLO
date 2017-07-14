## -------------------------------------------------------------------------------------------------------------
## 
##
##      Description: Update Intelligent provisioning thru iLO
##
## DISCLAIMER
## The sample scripts are not supported under any HP standard support program or service.
## The sample scripts are provided AS IS without warranty of any kind. 
## HP further disclaims all implied warranties including, without limitation, any implied 
## warranties of merchantability or of fitness for a particular purpose. 
##
##    
## Scenario
##     	Use iLO to update Intelligent Provisioning on servers
##	
## Prerequisites
##
##     - Install HPilo Cmdlets on your computer: http://h20564.www2.hpe.com/hpsc/swd/public/detail?swItemId=MTX_6d64cb45d4c649ceb8e9cc93b5
##     - Have a web site to host the IP iSO file ( Virtual directory in a web site)
##     - Set the MIME type to iso/iso
##     - On a Windows client, download HP iLOCmdlets
##     - Have a CSV file with iLO,user,password
##  	
##
## Input parameters:
##         iLOServerCSV                       = path to the CSV file containing Server ILO/user/password
##
## History: 
##         August-2016: v1.0 - Initial release
##
##
## Contact: 	Aric.Bernard@hpe.com
##		Dung.HoangKhac@hpe.com
##
## -------------------------------------------------------------------------------------------------------------
Param (
        [string]$iLOServerCSV ="C:\HPiLOCmdlets\iLOServer.CSV",
        [string]$ImageURL = "http://10.254.1.3/HPE_IP/Gen9/HPIP240B.2016_0514.6.iso",
        [string]$VirtualDevice = "CDROM"    # either FLOPPY or CDROM
        )




## -------------------------------------------------------------------------------------------------------------
##
##                 Main entry
##
## -------------------------------------------------------------------------------------------------------------

# ------------- Load HPiLOcmdlets
$iLOModule = get-module -listavailable | where name -like "*HPilo*"
if ($iLOModule)
{
    $iLOModuleLoaded = get-module | where name -like "*HPilo*"     #-- Is already loaded?
    if (-not $iLOmoduleLoaded)
    {
        IMPORT-Module $iLOModule
    }

}
else
{
    Write-Host "No HPiLOcmdlets module found. Please download it from the HP web site and install it"
    return
}



# ----------------------------
# Check input file

if ( -not $iLOServerCSV)
{
    write-host "No file specified in -iLOServerCSV ."
    return
}

if ( -not (Test-path $iLOServerCSV) )
{
    write-host "File $iLOServerCSV does not exist."
    return
}



# ----------------------------
#   Process the input file

# Read the CSV Users file
$tempFile = [IO.Path]::GetTempFileName()
type $iLOServerCSV | where { ($_ -notlike ",,,,*") -and ( $_ -notlike "#*") -and ($_ -notlike ",,,#*") } > $tempfile   # Skip blank line

    
$ListofServers = import-csv $tempfile

 
foreach ($s in $ListofServers)
{
    $serverIP   = $s.iLO
    $user       = $s.User
    $password   = $s.Password

    if ( $serverIP )
    {
        write-host "`n -------------------------------------------------------------------------"
        write-host "`n Collecting information for server iLO --> $serverIP"

        # ------------------
        # Validate whether this IP address is an iLO
        $ThisiLO = Find-HPiLO $ServerIP 
        if ( $ThisiLO)
        { 
            write-host "Found iLO ---> $ServerIP"
            # -----------
            # Collect iLO Version

            $script:iLOVersion = $ThisiLO.PN.Split('(')[1].Split(')')[0] -replace(' ','')  # Built the string "iLO4" or "iLO3"

            if ( $script:iLOVersion -eq "iLO4")
            {
                # -----------
                # Get server power status and shutdown server if necessary

                $PowerStat = get-HPiLOHostPower -Server $serverIP -Username $user -Password $password
                if ($PowerStat.STATUS_TYPE -eq "OK")
                {
                    if ($PowerStat.HOST_POWER -ne "OFF")
                    {
                        write-host "`n Force shutdown of server --> $ServerIP"
                        Set-HPiLOHostPower -Server $serverIP -Username $user -Password $password -HostPower "Off"
                        sleep 30
                    }

                    # -----------
                    # Configure Boot to CD

                    write-host "`n Configure boot Order to boot from CD/DVD for server --> $ServerIP"
                    $result = Set-HPiLOOneTimeBootOrder -Server $ServerIP -Username $user -Password $password -Device $VirtualDevice

                    if ($result.STATUS_TYPE -eq "ERROR")
                    {
                        write-host -foreground Cyan "`n Error Setting one-time boot order --> Message is $($result.STATUS_MESSAGE) "
                }
                    else
                    {
                        # -----------
                        # Configure Virtual CD/DVD to point to the URL Image

                        write-host "`n Configure virtual media to point to Image URL for server --> $ServerIP"
                        $result = Mount-HPiLOVirtualMedia -Server $ServerIP -Username $user -Password $password -Device $VirtualDevice -ImageURL $ImageURL

                        if ($result.STATUS_TYPE -eq "ERROR")
                        {
                                write-host -foreground Cyan "`n Error mounting virtual media --> Message is $($result.STATUS_MESSAGE) "
                        }
                        else
                        {
                                # ----------------------------
                                # Connect virtual media now

                                write-host "`n Connect virtual media to  server --> $ServerIP"
                                Set-HPiLOVMStatus -Server $ServerIP -Username $user -Password $password -VMBootOption "BOOT_ONCE" -device $VirtualDevice
                                Set-HPiLOVMStatus -Server $ServerIP -Username $user -Password $password -VMBootOption "CONNECT" -device $VirtualDevice
                    
                                # ----------------------------
                                # Power on server

                                write-host "`n Power On server --> $ServerIP"
                                Set-HPiLOHostPower -Server $serverIP -Username $user -Password $password -HostPower "On"

                        }
                    }


            }
                else
                {
                    write-host -foreground Yellow "Error connecting to the iLO to reset power. Check Error Message here -->  $($PowerStat.STATUS_MESSAGE) "
                }

            }
            else
            {
                write-host "`n Server --> $serverIP is not iLO4 - No Intelligent provisioning "
            }

        }

        else
        {
            write-host "`n Error collecting information for ilo --> $ServerIP. Check credential and/or IP address."
        }


        
    }

    else
    {
        write-host "This IP address $ServerIP is not an iLO or is not reachable "
    }
    
}
