Import-Module VMware.PowerCLI

# Connect to the UK ESX Environment
$VsphereServer = "clr-vcs01"
Set-PowerCLIConfiguration -InvalidCertificateAction Prompt -Confirm:$false
$Connection = Connect-VIServer $VsphereServer
$Connection

# Create VM from Sctach 
Get-VirtualPortGroup | ft -auto #Group-Object name # Network
Get-Datastore
Get-Cluster # use -ResourcePool in New-VM command
New-VM -VM -WhatIf # VM to Close
# -VMhost if you need to specify the actual host and -resourcepool to specify the Cluster


$OldVmName = "UK1-Mail01"
$FolderOfOldVm = Get-Folder -id (Get-VM $OldVmName).FolderId

$VMName = "UK1-Test2"
New-VM -Name $VMName -ResourcePool "MM-IN Stretched Cluster" -Datastore "vsanDatastore" -DiskGB 40 -MemoryGB 4 -NumCpu 2 -NetworkName "CLR_Production_VLAN300" -Location $FolderOfOldVm 

# Create VM from Template
$IP = "10.2.200.50"
$Subnet = "255.255.0.0"
$gateway = "10.2.1.1"
$PrimaryDNS = "10.2.1.20"
$SecondaryDNS = "10.2.1.21"

$OSSpecTemplate = "UK1-DevOps01"

# get current OS Spec so that we can use it in a new spec with the updated IP adddress
$NewOSSpec = Get-OSCustomizationSpec -Name $OSSpecTemplate | New-OSCustomizationSpec -Name $VMName -Type NonPersistent # persistent = stored on server, nonpersistent = not stored on server

# customize new Customisation template
Get-OSCustomizationSpec $NewOSSpec | 
    Get-OSCustomizationNicMapping |
        Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $IP -SubnetMask $subnet -DefaultGateway $gateway -Dns $PrimaryDNS,$SecondaryDNS

$VMTemplate = Get-Template "Win2019-Template-Sep19"

New-VM -name $VMName -Template $VMTemplate -OSCustomizationSpec $NewOSSpec -ResourcePool "MM-IN Stretched Cluster"-Datastore "vsanDatastore" -Location $FolderOfOldVm -Confirm:$true -RunAsync
Get-VM $VMName | Start-VM -RunAsync
# get Tasks if you are running in Async mode
get-task

#Cleanup the temporary Spec. System will do this outside of the session, but this will allow the scripts to be reused within a session.
Remove-OSCustomizationSpec -customizationSpec (Get-OSCustomizationSpec -name $NewOSSpec) -Confirm:$true 


get-vmhost
# Clone a Template
#New-Template -VM "Win2012VM" -Name "Server2012R2Template" -Datastore "TestDatastore" -Location "TestLocation"


Get-OSCustomizationSpec $custspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $ipaddr -SubnetMask $subnet -DefaultGateway $gateway -DNS $pdns,$sdns –ErrorAction Stop
    New-VM -Name $vmname -Template $template -Datastore $datastore -ResourcePool $cluster -ErrorAction stop 
    Set-VM $vmname -NumCpu $numcpu -MemoryMB $memory  -OSCustomizationSpec $custspec -Confirm:$false -ErrorAction Stop
    New-HardDisk -VM $vmname -CapacityKB $disk -StorageFormat $disktype -Confirm:$false -ErrorAction  Stop
    Get-VM -Name $vmname | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $vlan -Confirm:$false –ErrorAction Stop
    Start-VM -VM $vmname –ErrorAction Stop



    ForEach ($cluster in get-cluster){get-cluster "$cluster" | Get-VMHost | select -first 1 | get-datastore | where {$_.name -like "?_*"} | Select Name,FreeSpaceMB,CapacityMB,@{N="Number of VMs";E={@($_ | Get-VM).Count}},@{N="VMs";E={@($_ | Get-VM | ForEach-Object {$_.Name})}},@{N="VM Size";E={@($_ | Get-VM | ForEach-Object {$_.UsedSpaceGB})}} | Export-Csv D:\sjoerd\datastore-$cluster-overview.csv}