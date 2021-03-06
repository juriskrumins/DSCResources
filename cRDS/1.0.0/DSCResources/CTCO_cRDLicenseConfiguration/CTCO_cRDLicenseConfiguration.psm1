Import-Module -Name RemoteDesktop -Scope Global

#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]$ConnectionBroker,

		[parameter(Mandatory = $true)]
		[System.String[]]$LicenseServer,

		[parameter(Mandatory = $true)]
        [ValidateSet("PerDevice","PerUser")]
		[System.String]$Mode

	)

    $returnValue=@{}
    try
    {
        $RDLicenseConfiguration = Get-RDLicenseConfiguration -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue
        if($RDLicenseConfiguration -ne $null)
        {
            Write-Verbose -Message "RDS license server configuration has been found."
            $returnValue.Add('ConnectionBroker',$ConnectionBroker)
            $returnValue.Add('LicenseServer',$RDLicenseConfiguration.LicenseServer)
            $returnValue.Add('Mode',$RDLicenseConfiguration.Mode)
        }
        else
        {
            Write-Verbose -Message "No RDS license configuration has been found."
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured.$_"
    }
    return $returnValue;


}
#endregion Get-TargetResource

#region Set-TargetResource
function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]$ConnectionBroker,

		[parameter(Mandatory = $true)]
		[System.String[]]$LicenseServer,

		[parameter(Mandatory = $true)]
        [ValidateSet("PerDevice","PerUser")]
		[System.String]$Mode

	)

    try
    {
        Write-Verbose -Message "Going to configure RD License server configuration using $ConnectionBroker broker server."
        $AddRDServerParams=@{}
        $AddRDServerParams.Add('LicenseServer',$LicenseServer)
        $AddRDServerParams.Add('Mode',$Mode)
        $AddRDServerParams.Add('ConnectionBroker',$ConnectionBroker)
        $AddRDServerParams.Add('ErrorAction','Stop')
        $AddRDServerParams.Add('Force',$True)
        Set-RDLicenseConfiguration @AddRDServerParams
        Write-Verbose -Message "Configuration of RD License server list and mode has been finished."
    }
    catch
    {
        Write-Verbose -Message "Error occured. $_"
    }
}
#endregion Set-TargetResource

#region Test-TargetResource
function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]$ConnectionBroker,

		[parameter(Mandatory = $true)]
		[System.String[]]$LicenseServer,

		[parameter(Mandatory = $true)]
        [ValidateSet("PerDevice","PerUser")]
		[System.String]$Mode

	)

    $returnValue=$true
    try
    {
        $CurrentRDLicenseServer=Get-TargetResource -ConnectionBroker $ConnectionBroker -LicenseServer $LicenseServer -Mode $Mode
        if($CurrentRDLicenseServer["ConnectionBroker"] -ne "$ConnectionBroker")
        {
            Write-Verbose -Message "Required connection broker differs from currently deployed connection broker."
            $returnValue=$false
        }
        $diff = Compare-Object -ReferenceObject $LicenseServer -DifferenceObject $CurrentRDLicenseServer["LicenseServer"]
        if(($diff | Where-Object{$_.SideIndicator -eq "<="}) -ne $null -and $returnValue)
        {
            Write-Verbose -Message "Required RDS License server list differs from currently deployed. $(($diff | Where-Object{$_.SideIndicator -eq "<="}).InputObject)"
            $returnValue=$false
        }
        if($CurrentRDLicenseServer["Mode"] -ne $Mode)
        {
            Write-Verbose -Message "Required RDS License mode differs from currently deployed."
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

Export-ModuleMember -Function *-TargetResource