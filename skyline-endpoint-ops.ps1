#########################################
#                                       #
#   Author: Michael Hempel              #
#   Email:  mhempel@xmsoft.de           #
#                                       #
#########################################

# Set PowerCli Configurations
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -Scope Session -confirm:$false 

#Clear Screen
Clear-Host

# Read config file and assign variables

$configfile = "$PSScriptRoot/skyline_ops.json"
$config = Get-Content $configfile -raw | ConvertFrom-Json

$VarSkylineCLI = $config.SkylineCLI
$VarvCenter = $config.vcsa
$VarvCenterUser = $config.SkylineVCUser
$VarvCenterUserPass = $config.SkylineVCUserPass
$VarCollector = $config.Collector
$VarCollectorUser = $config.CollectorUser
$VarCollectorPassword = $config.CollectorUserPass
$VarvROPsUser = $config.vROPsUser
$VarvROPsPassword = $config.vROPsUserPassword
$VarNSXTUser = $config.NSXTUser
$VarNSXTPassword = $config.NSXTPassword
$VarvCenterFilter = $config.vCenterFilter
$VarvROPsFilter = $config.vROPsFilter
$VarNSXTFilter = $config.NSXTFilter
$VarLCMFilter = $config.LCMFilter

#My-Logger Function
Function My-Logger {
    param(
    [Parameter(Mandatory=$true)][String]$message,
    [Parameter(Mandatory=$true)][String]$color
    )

    #hh = 12h Format / HH = 24h Format
	$timeStamp = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"

	#Orig - White + Green
    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor $color " $message"
}

#My-SeparationLine Function
Function My-SeparationLine{
	Write-Host "--------------------------------------------------------------------------------------------------------------"
}

#My-EmtpyLine Function
Function My-EmptyLine{
	Write-Host "  "
}

Function Execute-SkylineCLI {
    param(
    [Parameter(Mandatory=$true)][String]$action,
    [Parameter(Mandatory=$false)][String]$p
    )
    switch ($action) {
        {($_ -match 'add') -or ($_ -match 'update')} { 
            Switch ($p)
                {
                    {$_ -match $VarvCenterFilter} { 
                        $eptype = "VSPHERE" 
                        $epuser = $VarvCenterUser
                        $eppassword = $VarvCenterUserPass
                    }
                    {$_ -match $VarvROPsFilter} { 
                        $eptype = "VROPS" 
                        $epuser = $VarvROPsUser
                        $eppassword = $VarvROPsPassword
                    }
                    {$_ -match $VarNSXTFilter} { 
                        $eptype = "NSX_T" 
                        $epuser = $VarNSXTUser
                        $eppassword = $VarNSXTPassword
                    }
                    {$_ -match $VarLCMFilter} { 
                        $eptype = "LCM" 
                        $epuser = $VarLCMUser
                        $eppassword = $VarLCMPassword
                    }
                }
            
                $Command = "$VarSkylineCLI --action=$action --username $VarCollectorUser --password $VarCollectorPassword --collector $VarCollector --insecure=true --eptype=$eptype --epuser=$epuser --eppassword=$eppassword --ep=$p"
                #Write-Host $command
                $result = (& Invoke-Expression $Command | Out-String)
            }
        {$_ -match 'monitor_slack'} {
            $Command = "$VarSkylineCLI --action=$action --username $VarCollectorUser --password $VarCollectorPassword --collector $VarCollector --insecure=true --output=true"
            $result = (& Invoke-Expression $Command | Out-String)
        }
    }        
    $result = $result.Trim()
    return $result
}

# Start Preparation and deployment
My-SeparationLine
My-Logger -color "Green" -message "Connect to vCenter $VarvCenter"

#Connect vCenter
$connection = Connect-VIServer -server $VarvCenter -User $VarvCenterUser -Password $VarvCenterUserPass 

$VarFoundEndpoints = @($VarvCenter)

My-Logger -color "Green" -message "Get endpoints from vCenter $VarvCenter"

$vROPsVM = Get-VM -Name "$VarvROPsFilter*" | Select-Object -ExpandProperty Name 
if ($vROPsVM) {
    $VarFoundEndpoints += $vROPsVM
}
$NSXTVM = Get-VM -Name "$VarNSXTFilter*" | Select-Object -ExpandProperty Name 
if ($NSXTVM) {
    $VarFoundEndpoints += $NSXTVM
}
$LCMVM = Get-VM -Name "$VarLCMFilter*" | Select-Object -ExpandProperty Name 
if ($LCMVM) {
    $VarFoundEndpoints += $LCMVM
}

#$VarFoundEndpoints
My-Logger -color "Green" -message "Get endpoints from Skyline Collector $VarCollector"

$endpoints = Execute-SkylineCLI -action "monitor_slack"
$endpointarray = $endpoints -split "`n"
$endpointarray = $endpointarray.Split('',[System.StringSplitOptions]::RemoveEmptyEntries)
#$endpointarray
$i=0

$hash = @{}
foreach ($a in $endpointarray) {
    $ep,$state = $a.Split('|')
    #Write-Host "$i $ep $state"
    $hash.Add($ep,$state)
    $i++
}
#Write-Host $hash

My-Logger -color "Green" -message "Compare Endpoints in Skyline Collector vs. found Endpoints"
foreach ($p in $VarFoundEndpoints){
    #Write-Host $p
    if ($hash.ContainsKey($p)) {
        My-Logger -color "Green" -message "Found $p in Skyline Collector $VarCollector"
        My-Logger -color "Green" -message "Check status of $p in Skyline Collector $VarCollector"
        if ($hash[$p] -ne "UPLOAD_SUCCESSFUL") {
            My-Logger -color "Red" -message "Endpoint status of $p is NOT OK"
            My-Logger -color "Yellow" -message "Update Endpoint $p in Skyline Collector $VarCollector"
            $result = Execute-SkylineCLI -action "update" -p $p
            My-Logger -color "Green" -message "$result"
        } else {
            My-Logger -color "Green" -message "Endpoint status of $p is OK"
        }
    }else {
            My-Logger -color "Red" -message "$p not found in Skyline Collector $VarCollector"
            My-Logger -color "Yellow" -message "Add Endpoint $p in Skyline Collector $VarCollector"
            $result = Execute-SkylineCLI -action "add" -p $p
            My-Logger -color "Green" -message "$result"
        }
}


My-Logger -color "Green" -message "Disconnect from $VarvCenter"
Disconnect-VIServer -Server $VarvCenter -Confirm:$false -Force:$true
My-SeparationLine