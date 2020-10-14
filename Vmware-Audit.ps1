<#
 - Audit Hosts and versinos of vmware

#>



# Install module PowerCli from VMware
Install-Module -Name VMware.PowerCLI

# Connect to VMware environment
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

$Now = Get-Date -Format "ddMMyyhhmmss"
$Sites = "UK", "US1", "US2",  "SG", "NL", "BRZ", "CPT"
foreach ($Site  in $Sites[3])
{

    switch ($Site) {
    "UK" {$Connection_UK = Connect-VIServer clr-vcs01 -User "Clarionevents\Daveyj" }
    "US1" {$Connection_US1 = Connect-VIServer 10.70.4.200 -User "Clarionevents\Daveyj"}
    "US2" {$Connection_US2 = Connect-VIServer 10.71.4.200 -User "Clarionevents\Daveyj"}
    "SG" {$Connection_SG = Connect-VIServer sg-vc-02.clarionevents.local -User "Administrator@vsphere.local"}
    "NL" {$Connection_NL = Connect-VIServer nl-vc02.clarionevents.local -User "Administrator@vsphere.local"}
    "BRZ" {$Connection_BRZ = Connect-VIServer 10.17.200.5 } # too old to connect}
    "CPT" {$Connection_CPT = Connect-VIServer 10.30.4.200 -user "administrator@vsphere.local" }
    }


    # Hosts
    $VMhosts = Get-VMHost
    $VMhosts | Get-View | ft vm

    # Get a list of all Virtual Machines
    $AllVMs = Get-VM
    $Obj = @()
    foreach ($VirtualMachine in $AllVMs)
    {
    $VirtualMachine.Name
    $VM = Get-VM $VirtualMachine
    $VMGV = Get-VM $VirtualMachine | Get-View
    $VMconfig = $VMGV.Config
    $VMRuntime = $VMGV.Runtime
    $VMGuest = $VMGV.Summary.Guest 
    $VMHardware = $VMGV.Summary.Config
    $VMHardDisk = Get-HardDisk -VM $VMGV.Name
    $VMNetworkAdapter = Get-NetworkAdapter -VM $VMGV.Name
    $Hash = @{
        VMName = $VM.Name
        HostName = $VMGuest.HostName
        ESXHost = $VM.VMHost.name
        ResourcePool = $VMGV.ResourcePool
        Datastore = $VMGV.Datastore.value -join ";`n"
        Network = $VMGV.Network.value -join ";`n"
        Snapshot = $VMGV.Snapshot
        OperatingSystem = $VMconfig.GuestFullName
        DatastoreName = $VMconfig.DatastoreUrl.name -join ";`n"
        DataStorePath = $VMHardware.VmPathName -join ";`n"
        ConnectionState = $VMRuntime.ConnectionState
        PowerState = $VMRuntime.PowerState
        BootTime = $VMRuntime.BootTime
        MemoryGB = $VMRuntime.MaxMemoryUsage / 1024
        NumCPU = $VMHardware.NumCpu
        NumNic = $VMHardware.NumEthernetCards
        numDisks = $VMHardware.NumVirtualDisks
        ToolsStatus = $VMGuest.ToolsStatus
        IPAddress = $VMGuest.IpAddress
        VMHardDisk =  $VMHardDisk.Filename -join ";`n"
        NetworkName = $VMNetworkAdapter.NetworkName  -join ";`n"

    }

    $Obj += New-Object psobject -Property $hash
    }

    $Obj |
        Select VMName, HostName, IPAddress, PowerState, ESXHost, ResourcePool, MemoryGB, NumCPU, NumNic, Network, NetworkName, numDisks, DatastoreName, Datastore, DataStorePath, VMHardDisk, ConnectionState, ToolsStatus, OperatingSystem, BootTime, Snapshot |
            epcsv "E:\Scripts\PowerCli\VMware Environment Audit\$Site-Clarion-Vmware-Env-$Now.csv" -NoTypeInformation

    # Disconnect
    Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false

}