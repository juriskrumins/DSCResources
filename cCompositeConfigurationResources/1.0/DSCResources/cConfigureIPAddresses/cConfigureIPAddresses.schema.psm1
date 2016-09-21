Configuration cConfigureIPAddresses {
        param
        (
            [parameter(Mandatory=$true)]
            [string[]]$IPAddresses,
            [parameter(Mandatory=$false)]
            [string]$InterfaceAlias="Ethernet",
            [parameter(Mandatory=$true)]
            [string]$DefaultGateway,
            [parameter(Mandatory=$false)]
            [ValidateSet("IPv4","IPv6")]
            [string]$AddressFamily = "IPv4",
            [parameter(Mandatory=$false)]
            [int]$SubnetMask=24
        )
        $i=0
        Import-DscResource -ModuleName xNetworking
        foreach($IPAddress in $IPAddresses)
        {
            $ResourceName="xIPAddress$($IPAddress -replace '\.','')"
            if($i -eq 0 -and $DefaultGateway -ne $null)
            {
                xIPAddress "$ResourceName"
                {
                    InterfaceAlias = "$InterfaceAlias"
                    IPAddress = "$IPAddress"
                    AddressFamily = "$AddressFamily"
                    SubnetMask = $SubnetMask
                }
                xDefaultGatewayAddress "xDefaultGatewayAddress$(Get-Random)"
                {
                    AddressFamily = "$AddressFamily"
                    InterfaceAlias = "$InterfaceAlias"
                    Address = "$DefaultGateway"
                    DependsOn = "[xIPAddress]$ResourceName"
                }
            }
            else
            {
                xIPAddress "$ResourceName"
                {
                    InterfaceAlias = "$InterfaceAlias"
                    IPAddress = "$IPAddress"
                    AddressFamily = "$AddressFamily"
                    SubnetMask = $SubnetMask
                }
            }
            $i++
        }
}