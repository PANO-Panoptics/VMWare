# PowerCli from VMware
Install-Module -Name VMware.PowerCLI

Set-PowerCLIConfiguration -InvalidCertificateAction Prompt -Confirm:$false
$Connection = Connect-VIServer clr-vcs01

# Hosts
$VMhosts = Get-VMHost
$VMhosts | Get-View | ft vm

# Datastores
(($Datastore = Get-Datastore | Sort-Object freespacegb -Descending)[0] | Get-View)

# VMs
Get-VM uk1-devops01 | fl # basic 
Get-VM uk1-devops01 | Get-View  # more info

$VM = Get-VM uk1-devops01 | Get-View
$VM.Config  # Shows information about the Virtual Machine Guest (UUID, Operating System

$VM.Summary

$VM.Runtime # boot time, PowerState, Memory Max memory Usage, VM tools mounted

$VM.Summary.Guest # VMWare Tools running, IP address, name

$VM.Summary.Config # Ram allocation, Number of CPU, Datastore Path, Number of Disks




#*************************************************************************************************************
#      Script Name	:   DataStoreFreeSpace-Percentage.ps1
#      Purpose		:   Get the report of datastores which has less than 20% free space.
#				
#      Date		    :   24-11-2016	# - Initial version
#
#      Author		:   www.VMwareArena.com
#
#*************************************************************************************************************

$VCServer = Read-Host 'Enter VC Server name'
$vcUSERNAME = Read-Host 'Enter user name'
$vcPassword = Read-Host 'Enter password' -AsSecureString
$vccredential = New-Object System.Management.Automation.PSCredential ($vcusername, $vcPassword)


#$LogFile = "DataStoreInfo_" + (Get-Date -UFormat "%d-%b-%Y-%H-%M") + ".csv" 

Write-Host "Connecting to $VCServer..." -Foregroundcolor "Yellow" -NoNewLine
$connection = Connect-VIServer -Server $VCServer -Cred $vccredential -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null
If($? -Eq $True)

{
	Write-Host "Connected" -Foregroundcolor "Green" 
	$Results = @()
	$Result = Get-Datastore | Select @{N="DataStoreName";E={$_.Name}},@{N="Percentage Free Space(%)";E={[math]::Round(($_.FreeSpaceGB)/($_.CapacityGB)*100,2)}} | Where {$_."Percentage(<20%)" -le 20}
	$Result | Export-Csv -NoTypeInformation $LogFile
}
Else
{
	Write-Host "Error in Connecting to $VIServer; Try Again with correct user name & password!" -Foregroundcolor "Red" 
}
Disconnect-VIServer * -Confirm:$false
#
#-------------------------------------------------------------------------------------------------------------
