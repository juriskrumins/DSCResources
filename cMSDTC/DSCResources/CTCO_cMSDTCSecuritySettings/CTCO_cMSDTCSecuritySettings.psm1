#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

function Get-TargetResource
{
    [OutputType([Hashtable])]
	param
	(	
        [parameter(Mandatory=$true)]
        [string] $DtcName,
        [parameter(Mandatory=$false)]
        [boolean] $InboundTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $OutboundTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $RemoteClientAccessEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $RemoteAdministrationAccessEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $XATransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $LUTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [string] $AuthenticationLevel
  	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference = "Stop"
        if ((Get-Dtc -DtcName $DtcName -ErrorAction SilentlyContinue) -ne $null)
        {
            Write-Verbose -Message "MSDTC $DtcName found"
            $DtcNetworkSetting = Get-DtcNetworkSetting -DtcName $DtcName
            $returnValue = @{
                DtcName = $DtcName
                InboundTransactionsEnabled = $DtcNetworkSetting.InboundTransactionsEnabled
                OutboundTransactionsEnabled = $DtcNetworkSetting.OutboundTransactionsEnabled
                RemoteClientAccessEnabled = $DtcNetworkSetting.RemoteClientAccessEnabled
                RemoteAdministrationAccessEnabled = $DtcNetworkSetting.RemoteAdministrationAccessEnabled
                XATransactionsEnabled = $DtcNetworkSetting.XATransactionsEnabled
                LUTransactionsEnabled = $DtcNetworkSetting.LUTransactionsEnabled
                AuthenticationLevel = $DtcNetworkSetting.AuthenticationLevel
            }
        }
        else
        {
            Write-Verbose -Message "MSDTC $DtcName not found"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
    }
	$returnValue
}

function Set-TargetResource
{
	param
	(	
        [parameter(Mandatory=$true)]
        [string] $DtcName,
        [parameter(Mandatory=$false)]
        [boolean] $InboundTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $OutboundTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $RemoteClientAccessEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $RemoteAdministrationAccessEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $XATransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $LUTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [string] $AuthenticationLevel
  	)

    try
    {
        $ErrorActionPreference = "Stop"
        if ((Get-Dtc -DtcName $DtcName -ErrorAction SilentlyContinue) -ne $null)
        {
            Write-Verbose -Message "MSDTC $DtcName found"
            Write-Verbose -Message "Goind to set desired parameters for MSDTC $DtcName"
            $DesiredNetworkSetting = @{"DtcName"=$DtcName}
            if("InboundTransactionsEnabled" -in $MyInvocation.BoundParameters.keys)
            {
                $DesiredNetworkSetting.Add("InboundTransactionsEnabled",$InboundTransactionsEnabled)
            }

            if("OutboundTransactionsEnabled" -in $MyInvocation.BoundParameters.keys)
            {
                $DesiredNetworkSetting.Add("OutboundTransactionsEnabled",$OutboundTransactionsEnabled)
            }

            if("RemoteClientAccessEnabled" -in $MyInvocation.BoundParameters.keys)
            {
                $DesiredNetworkSetting.Add("RemoteClientAccessEnabled",$RemoteClientAccessEnabled)
            }

            if("RemoteAdministrationAccessEnabled" -in $MyInvocation.BoundParameters.keys)
            {
                $DesiredNetworkSetting.Add("RemoteAdministrationAccessEnabled",$RemoteAdministrationAccessEnabled)
            }

            if("XATransactionsEnabled" -in $MyInvocation.BoundParameters.keys)
            {
                $DesiredNetworkSetting.Add("XATransactionsEnabled",$XATransactionsEnabled)
            }

            if("LUTransactionsEnabled" -in $MyInvocation.BoundParameters.keys)
            {
                $DesiredNetworkSetting.Add("LUTransactionsEnabled",$LUTransactionsEnabled)
            }

            if("AuthenticationLevel" -in $MyInvocation.BoundParameters.keys)
            {
                $DesiredNetworkSetting.Add("AuthenticationLevel",$AuthenticationLevel)
            }

            $DesiredNetworkSetting.Add("Confirm",$false)
            Set-DtcNetworkSetting @DesiredNetworkSetting
        }
        else
        {
            Write-Verbose -Message "MSDTC $DtcName not found"
        }

    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
    }

}

function Test-TargetResource
{
    [OutputType([Boolean])]
	param
	(	
        [parameter(Mandatory=$true)]
        [string] $DtcName,
        [parameter(Mandatory=$false)]
        [boolean] $InboundTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $OutboundTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $RemoteClientAccessEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $RemoteAdministrationAccessEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $XATransactionsEnabled,
        [parameter(Mandatory=$false)]
        [boolean] $LUTransactionsEnabled,
        [parameter(Mandatory=$false)]
        [string] $AuthenticationLevel
  	)
    $retValue = $false
    $ActualNetworkSetting = Get-TargetResource -DtcName $DtcName -InboundTransactionsEnabled $InboundTransactionsEnabled -OutboundTransactionsEnabled $OutboundTransactionsEnabled `
                             -RemoteClientAccessEnabled $RemoteClientAccessEnabled -RemoteAdministrationAccessEnabled $RemoteAdministrationAccessEnabled `
                             -XATransactionsEnabled $XATransactionsEnabled -LUTransactionsEnabled $LUTransactionsEnabled -AuthenticationLevel $AuthenticationLevel
    $DesiredNetworkSetting = @{"DtcName"=$DtcName}
    if("InboundTransactionsEnabled" -in $MyInvocation.BoundParameters.keys)
    {
        $DesiredNetworkSetting.Add("InboundTransactionsEnabled",$InboundTransactionsEnabled)
    }
    else
    {
        $DesiredNetworkSetting.Add("InboundTransactionsEnabled",$ActualNetworkSetting.InboundTransactionsEnabled)
    }

    if("OutboundTransactionsEnabled" -in $MyInvocation.BoundParameters.keys)
    {
        $DesiredNetworkSetting.Add("OutboundTransactionsEnabled",$OutboundTransactionsEnabled)
    }
    else
    {
        $DesiredNetworkSetting.Add("OutboundTransactionsEnabled",$ActualNetworkSetting.OutboundTransactionsEnabled)
    }

    if("RemoteClientAccessEnabled" -in $MyInvocation.BoundParameters.keys)
    {
        $DesiredNetworkSetting.Add("RemoteClientAccessEnabled",$RemoteClientAccessEnabled)
    }
    else
    {
        $DesiredNetworkSetting.Add("RemoteClientAccessEnabled",$ActualNetworkSetting.RemoteClientAccessEnabled)
    }

    if("RemoteAdministrationAccessEnabled" -in $MyInvocation.BoundParameters.keys)
    {
        $DesiredNetworkSetting.Add("RemoteAdministrationAccessEnabled",$RemoteAdministrationAccessEnabled)
    }
    else
    {
        $DesiredNetworkSetting.Add("RemoteAdministrationAccessEnabled",$ActualNetworkSetting.RemoteAdministrationAccessEnabled)
    }

    if("XATransactionsEnabled" -in $MyInvocation.BoundParameters.keys)
    {
        $DesiredNetworkSetting.Add("XATransactionsEnabled",$XATransactionsEnabled)
    }
    else
    {
        $DesiredNetworkSetting.Add("XATransactionsEnabled",$ActualNetworkSetting.XATransactionsEnabled)
    }

    if("LUTransactionsEnabled" -in $MyInvocation.BoundParameters.keys)
    {
        $DesiredNetworkSetting.Add("LUTransactionsEnabled",$LUTransactionsEnabled)
    }
    else
    {
        $DesiredNetworkSetting.Add("LUTransactionsEnabled",$ActualNetworkSetting.LUTransactionsEnabled)
    }

    if("AuthenticationLevel" -in $MyInvocation.BoundParameters.keys)
    {
        $DesiredNetworkSetting.Add("AuthenticationLevel",$AuthenticationLevel)
    }
    else
    {
        $DesiredNetworkSetting.Add("AuthenticationLevel",$ActualNetworkSetting.AuthenticationLevel)
    }

    foreach($key in $DesiredNetworkSetting.Keys)
    {
        if($ActualNetworkSetting["$key"] -ne $DesiredNetworkSetting["$key"])
        {
            $retValue=$false
            break
        }
        else
        {
            $retValue=$true
        }
    }
    
    return $retValue
}


Export-ModuleMember -Function *-TargetResource