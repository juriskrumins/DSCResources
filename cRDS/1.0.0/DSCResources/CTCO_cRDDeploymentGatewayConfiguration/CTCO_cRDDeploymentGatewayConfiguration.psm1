Import-Module -Name RemoteDesktop -Force
#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ConnectionBroker,

		[parameter(Mandatory = $true)]
        [ValidateSet("DoNotUse","Custom","Automatic")]
		[System.String]
		$GatewayMode,

		[parameter(Mandatory = $false)]
		[System.String]
		$GatewayExternalFqdn,

		[parameter(Mandatory = $false)]
        [ValidateSet("AllowUserToSelectDuringConnection","Password","Smartcard")]
		[System.String]
		$LogonMethod,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$UseCachedCredentials,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$BypassLocal
	)

    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting RD deployment gateway configuration"
        $RDDeploymentGatewayConfiguration = Get-RDDeploymentGatewayConfiguration  -ConnectionBroker $ConnectionBroker -ErrorAction Stop
        if($RDDeploymentGatewayConfiguration -ne $null)
        {
            Write-Verbose -Message "Got RD deployment gateway configuration"
            $returnValue.Add("ConnectionBroker",$ConnectionBroker)
            $returnValue.Add("GatewayMode",$RDDeploymentGatewayConfiguration.GatewayMode)
            $returnValue.Add("GatewayExternalFqdn",$RDDeploymentGatewayConfiguration.GatewayExternalFqdn)
            $returnValue.Add("LogonMethod",$RDDeploymentGatewayConfiguration.LogonMethod)
            $returnValue.Add("UseCachedCredentials",$RDDeploymentGatewayConfiguration.UseCachedCredentials)
            $returnValue.Add("BypassLocal",$RDDeploymentGatewayConfiguration.BypassLocal)
        }
        else
        {
            Write-Verbose -Message "Can't get RD deployment gateway configuration"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured.$_"
    }
    return $returnValue;


}
#endregion Get-TargetResource

#region Test-TargetResource
function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ConnectionBroker,

		[parameter(Mandatory = $true)]
        [ValidateSet("DoNotUse","Custom","Automatic")]
		[System.String]
		$GatewayMode,

		[parameter(Mandatory = $false)]
		[System.String]
		$GatewayExternalFqdn,

		[parameter(Mandatory = $false)]
        [ValidateSet("AllowUserToSelectDuringConnection","Password","Smartcard")]
		[System.String]
		$LogonMethod,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$UseCachedCredentials,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$BypassLocal
	)

    $returnValue=$true
    try
    {
        $CurrentRDDeploymentGatewayConfiguration = Get-TargetResource -ConnectionBroker $ConnectionBroker -GatewayMode $GatewayMode -GatewayExternalFqdn $GatewayExternalFqdn -LogonMethod $LogonMethod -UseCachedCredentials $UseCachedCredentials -BypassLocal $BypassLocal
        if($CurrentRDDeploymentGatewayConfiguration["GatewayMode"] -eq $GatewayMode)
        {
            Write-Verbose -Message "RD gateway mode is in desired state."
            if($CurrentRDDeploymentGatewayConfiguration["GatewayMode"] -eq "Custom")
            {
                if($CurrentRDDeploymentGatewayConfiguration["GatewayExternalFqdn"] -ne $GatewayExternalFqdn)
                {
                    Write-Verbose -Message "Desired and current RD gateway's GatewayExternalFqdn parameter differs."
                    $returnValue=$false
                }
                if($CurrentRDDeploymentGatewayConfiguration["LogonMethod"] -ne $LogonMethod -and $returnValue)
                {
                    Write-Verbose -Message "Desired and current RD gateway's LogonMethod parameter differs."
                    $returnValue=$false
                }
                if($CurrentRDDeploymentGatewayConfiguration["UseCachedCredentials"] -ne $UseCachedCredentials -and $returnValue)
                {
                    Write-Verbose -Message "Desired and current RD gateway's UseCachedCredentials parameter differs."
                    $returnValue=$false
                }
                if($CurrentRDDeploymentGatewayConfiguration["BypassLocal"] -ne $BypassLocal -and $returnValue)
                {
                    Write-Verbose -Message "Desired and current RD gateway's BypassLocal parameter differs."
                    $returnValue=$false
                }
            }
        }
        else
        {
            Write-Verbose -Message "Desired and current RD deployment gateway mode differs."
            $returnValue=$false
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $_"
    }
    return $returnValue
}
#endregion Test-TargetResource

#region Set-TargetResource
function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ConnectionBroker,

		[parameter(Mandatory = $true)]
        [ValidateSet("DoNotUse","Custom","Automatic")]
		[System.String]
		$GatewayMode,

		[parameter(Mandatory = $false)]
		[System.String]
		$GatewayExternalFqdn,

		[parameter(Mandatory = $false)]
        [ValidateSet("AllowUserToSelectDuringConnection","Password","Smartcard")]
		[System.String]
		$LogonMethod,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$UseCachedCredentials,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$BypassLocal
	)

    try
    {
        $RDDeploymentGatewayConfigurationParams=@{}
        Write-Verbose -Message "Going to set RD deployment gateway configuration"
        Write-Verbose -Message "Packing common RD deployment gateway  parameters."
        $RDDeploymentGatewayConfigurationParams.Add("ConnectionBroker",$ConnectionBroker)
        $RDDeploymentGatewayConfigurationParams.Add("GatewayMode",$GatewayMode)
        $RDDeploymentGatewayConfigurationParams.Add("Force",$true)
        $RDDeploymentGatewayConfigurationParams.Add("ErrorAction","Stop")
        if($GatewayMode -eq "Custom")
        {
            Write-Verbose -Message "Packing specific parameters for Custom  gateway mode."
            $RDDeploymentGatewayConfigurationParams.Add("GatewayExternalFqdn",$GatewayExternalFqdn)
            $RDDeploymentGatewayConfigurationParams.Add("LogonMethod",$LogonMethod)
            $RDDeploymentGatewayConfigurationParams.Add("UseCachedCredentials",$UseCachedCredentials)
            $RDDeploymentGatewayConfigurationParams.Add("BypassLocal",$BypassLocal)
        }
        Set-RDDeploymentGatewayConfiguration @RDDeploymentGatewayConfigurationParams
    }
    catch
    {
        Write-Verbose -Message "Error occured. $_"
    }
}
#endregion Set-TargetResource

Export-ModuleMember -Function *-TargetResource