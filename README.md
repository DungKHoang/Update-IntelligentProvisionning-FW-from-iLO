# Update Intelligent provisioning thru iLO

This PowerShell script updates Intelligent Provisioning Firmware for servers through iLO
through iLO

## Libraries
The script leverages the follwoing PowerShell libraries:
* OneView PowerShell library : https://github.com/HewlettPackard/POSH-HPOneView/releases
* HPiLO cmdlets: http://h20564.www2.hpe.com/hpsc/swd/public/detail?swItemId=MTX_6d64cb45d4c649ceb8e9cc93b5



## Prerequisites
* Install HPiLO Cmdlets on your computer
* Have a web site to host the IP iSO file ( Virtual directory in a web site)
* Set the MIME type to iso/iso
* On a Windows client, download HP iLOCmdlets
* Have a CSV file with iLO,user,password



## Syntax


```
    .\Update-IntelligenProvisionning.ps1 -iLOServerCSV c:\iLO.CSV -ImageURL "http://10.254.1.3/HPE_IP/Gen9/HPIP240B.2016_0514.6.iso" -VirtualDevice CDROM

```

