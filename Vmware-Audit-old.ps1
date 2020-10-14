<#
 - Audit Hosts and versinos of vmware

#>



# Install module PowerCli from VMware
Install-Module -Name VMware.PowerCLI

# Connect to VMware environment
Set-PowerCLIConfiguration -InvalidCertificateAction Prompt -Confirm:$false


[array]$Sites = "Pano"#, "UK", "US1", "US2",  "SG", "NL", "BRZ", "CPT"
foreach ($Site  in $Sites[0])
{

    switch ($Site) {
    "Pano" {$Connection_Pano = Connect-VIServer uk-pan-vcs01.panoptics.local -User "Panoptics\Daveyj"}
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
    $VM = Get-VM $VirtualMachine | Get-View
    $VMconfig = $VM.Config
    $VMRuntime = $VM.Runtime
    $VMGuest = $VM.Summary.Guest 
    $VMHardware = $VM.Summary.Config
    $VMHardDisk = Get-HardDisk -VM $vm.Name
    $VMNetworkAdapter = Get-NetworkAdapter -VM $VM.Name
    $Hash = @{
        VMName = $VM.Name
        HostName = $VMGuest.HostName
        ResourcePool = $VM.ResourcePool
        Datastore = $VM.Datastore.value -join ";`n"
        Network = $VM.Network.value -join ";`n"
        Snapshot = $VM.Snapshot
        OperatingSystem = $VMconfig.GuestFullName
        DatastoreName = $VMconfig.DatastoreUrl.name -join ";`n"
        DataStorePath = $VMHardware.VmPathName -join ";`n"
        ConnectionState = $VMRuntime.ConnectionState
        PowerState = $VMconfig.PowerState
        BootTime = $VMconfig.BootTime
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
        Select VMName, ResourcePool, MemoryGB, NumCPU, NumNic, Network, NetworkName, numDisks, DatastoreName, Datastore, DataStorePath, VMHardDisk, ConnectionState, HostName, IPAddress, oolsStatus, OperatingSystem, BootTime, Snapshot, PowerState |
            epcsv "E:\Scripts\PowerCli\VMware Environment Audit\$Site-Clarion-Vmware-Env.csv" -NoTypeInformation

    # Disconnect
    Disconnect-CIServer

}