#region Get-TargetResource 
# DSC uses the Get-TargetResource cmdlet to fetch the status of the resource instance specified in the parameters for the target machine
function Get-TargetResource 
{ 
    [OutputType([Hashtable])]   
    param 
    (        
        [Parameter(Mandatory)]
        [ValidateSet("Vpn")]
        [String]$VpnType,
                      
        [Parameter(Mandatory)]
        [String[]]$RadiusServer,

        [Parameter(Mandatory)]
        [String]$SharedSecret,
        
        [parameter(Mandatory)]
        [String[]]$IPAddressRange
    )
    
    $return=@{}
    try
    {
        $remoteaccessobj=Get-RemoteAccess -ErrorAction Stop
        if($remoteaccessobj -ne $null)
        {
            if($remoteaccessobj.VpnStatus -eq "Installed")
            {
                Write-Verbose -Message "Vpn is installed"
                $return.Add("VpnType","Vpn")
                $return.Add("RadiusServer",$remoteaccessobj.RadiusServerList)
                $return.Add("SharedSecret","************")
                if($remoteaccessobj.IPAssignmentMethod -eq "StaticPool")
                {
                    $ipr=@()
                    foreach($ipar in $remoteaccessobj.IPAddressRangeList)
                    {
                        $ipr+=$ipar -split " - "
                    }
                    $return.Add("IPAddressRange",$ipr)
                }
            }

        }
        else
        {
            Write-Verbose -Message "RemoteAccess object eq null."
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)"
    }
    return $return;
}
#endregion #region Get-TargetResource 

#region Set-TargetResource
# DSC uses Set-TargetResource cmdlet to create, delete or configure the resource instance on the target machine
function Set-TargetResource 
{   
    param 
    (        
        [Parameter(Mandatory)]
        [ValidateSet("Vpn")]
        [String]$VpnType,
                      
        [Parameter(Mandatory)]
        [String[]]$RadiusServer,

        [Parameter(Mandatory)]
        [String]$SharedSecret,
        
        [parameter(Mandatory)]
        [String[]]$IPAddressRange
    )

    try
    {
        if((Get-RemoteAccess -ErrorAction Stop).VpnStatus -eq "Installed")
        {
            Write-Verbose -Message "Going to uninstall RemoteAccess."
            Uninstall-RemoteAccess -VpnType $VpnType -Force -ErrorAction Stop
        }
        Write-Verbose -Message "Going to install RemoteAccess."
        Install-RemoteAccess -VpnType $VpnType -RadiusServer $RadiusServer[0] -SharedSecret $SharedSecret -IPAddressRange $IPAddressRange -ErrorAction Stop
        if($RadiusServer.Length -gt 1)
        {
            Write-Verbose -Message "Going to add additional Radius servers."
            for ($i = 1; $i -lt $RadiusServer.Length; $i++)
            { 
                Write-Verbose -Message "Adding $($RadiusServer[$i]) Radius server"
                Add-RemoteAccessRadius -ServerName $RadiusServer[$i] -SharedSecret $SharedSecret -Purpose Authentication
            }
        }
        Write-Verbose -Message "Getting `"Default Web Site`" certificate hash."
        $certhash=(Get-WebBinding -Name "Default Web Site" -ErrorAction Stop).CertificateHash
        $setsstpsslcerthash="Netsh ras set sstp-ssl-cert hash=$certhash"
        Write-Verbose -Message "Setting SSTP VPN server certificate to the one with the hash $certhash"
        Invoke-Expression -Command $setsstpsslcerthash -ErrorAction Stop
        Write-Verbose -Message "Restarting RemoteAccess service"
        Get-Service -name RemoteAccess -ErrorAction Stop | Restart-Service -ErrorAction Stop
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)"
    }
}
#endregion Set-TargetResource

#region Test-TargetREsource
# DSC uses Test-TargetResource cmdlet to check the status of the resource instance on the target machine
function Test-TargetResource 
{
    [OutputType([Boolean])] 
    param 
    (        
        [Parameter(Mandatory)]
        [ValidateSet("Vpn")]
        [String]$VpnType,
                      
        [Parameter(Mandatory)]
        [String[]]$RadiusServer,

        [Parameter(Mandatory)]
        [String]$SharedSecret,
        
        [parameter(Mandatory)]
        [String[]]$IPAddressRange
    )

    $returnValue=$true
    try
    {
        $remoteaccessconfiguration=Get-TargetResource -VpnType $VpnType -RadiusServer $RadiusServer -SharedSecret $SharedSecret -IPAddressRange $IPAddressRange
        if($remoteaccessconfiguration.Count -ne 0)
        {
            if((Compare-Array -array1 $remoteaccessconfiguration.RadiusServer -array2 $RadiusServer) `
                -and (Compare-Array -array1 $remoteaccessconfiguration.IPAddressRange -array2 $IPAddressRange))
            {
                Write-Verbose -Message "Looks like RadiusServer and IPAddressRange are in desired state. Nothing to do."
                $returnValue=$true
            }
            else
            {
                Write-Verbose -Message "Looks like RadiusServer and/or IPAddressRange are not in desired state."
                Write-Verbose -Message "Going to reconfigure RRAS and restart RemoteAccess service."
                $returnValue=$false
            }
        }
        else
        {
            Write-Verbose -Message "Vpn is probably not configured. Going to configure RRAS."
            $returnValue=$false
        }
    }
    finally
    {
    }
    return $returnValue
}
#endregion Test-TargetREsource

#region  Helper functions
function Compare-Array
{
    [OutputType([Boolean])]
    param 
    (        
        [Parameter(Mandatory)]
        $array1,
                      
        [Parameter(Mandatory)]
        $array2
    )
    if($array1.Length -eq $array2.Length)
    {
        for ($i = 0; $i -lt $array1.Length; $i++)
        { 
            if($array1[$i] -ne $array2[$i])
            {
                $returnVal=$false
                break
            }
            else
            {
                $returnVal=$true
            }
        }
    }
    else
    {
        $returnVal=$false
    }
    return $returnVal
}
#endregion  Helper functions