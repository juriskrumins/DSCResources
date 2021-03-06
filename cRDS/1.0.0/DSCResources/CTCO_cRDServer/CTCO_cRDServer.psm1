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
		[System.String[]]$Server,

		[parameter(Mandatory = $true)]
        [ValidateSet("RDS-GATEWAY","RDS-LICENSING")]
		[System.String]$Role

	)

    $returnValue=@{}
    try
    {
        $RDDeployment = Get-RDServer -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue
        $RDSConnectionBroker=""
        $RDSServers =@()
        if($RDDeployment -ne $null)
        {
            Write-Verbose -Message "RDS deployment has been found."
            Foreach($RDServer in $RDDeployment){
                if("RDS-CONNECTION-BROKER" -in $RDServer.Roles)
                {
                    $RDSConnectionBroker=$RDServer.Server
                }
                if("$Role" -in $RDServer.Roles)
                {
                    $RDSServers+=$RDServer.Server
                }
            }
            $returnValue.Add('ConnectionBroker',$RDSConnectionBroker)
            $returnValue.Add('Server',$RDSServers)
        }
        else
        {
            Write-Verbose -Message "No RDS deployment has been found."
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
		[System.String[]]$Server,

		[parameter(Mandatory = $true)]
        [ValidateSet("RDS-GATEWAY","RDS-LICENSING")]
		[System.String]$Role

	)

    try
    {
        $CurrentRDServers=Get-TargetResource -ConnectionBroker $ConnectionBroker -Server $Server -Role $Role
        if($CurrentRDServers.Count -eq 0)
        {
            Write-Verbose -Message "Looks like we can't find RD Session deployment. Please create RDSession Deployment."
        }
        else
        {
            Write-Verbose -Message "Looks like we have RDSessionDeployment with ConnectionBroker $ConnectionBroker"
            Write-Verbose -Message "Going to check if all $Role RDS servers are a part of deployment"
            $diff=Compare-Object -ReferenceObject $Server -DifferenceObject $CurrentRDServers["Server"]
            if(($diff | Where-Object{$_.SideIndicator -eq "<="}) -ne $null)
            {
                Write-Verbose -Message "Looks like RDS Server $Server with the role $Role are missing from deployment."
                Foreach($RDServer in $diff.InputObject)
                {
                    Write-Verbose -Message "Going to add $RDServer to existing deployment with role $($Role)."
                    $AddRDServerParams=@{}
                    $AddRDServerParams.Add('Server',$RDServer)
                    $AddRDServerParams.Add('Role',$Role)
                    $AddRDServerParams.Add('ConnectionBroker',$ConnectionBroker)
                    $AddRDServerParams.Add('ErrorAction','Stop')
                    if($Role -eq "RDS-GATEWAY")
                    {
                        $AddRDServerParams.Add('GatewayExternalFqdn',$RDServer)
                    }
                    Add-RDServer @AddRDServerParams
                    Write-Verbose -Message "Adding $RDServer to existing deployment with the role $Role has been finished."
                }
            }
            else
            {
                Write-Verbose -Message "Looks like all $Role RDS servers are a part of deployment."
            }
        }
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
		[System.String[]]$Server,

		[parameter(Mandatory = $true)]
        [ValidateSet("RDS-GATEWAY","RDS-LICENSING")]
		[System.String]$Role

	)

    $returnValue=$true
    try
    {
        $CurrentRDServer=Get-TargetResource -ConnectionBroker $ConnectionBroker -Server $Server -Role $Role
        if($CurrentRDServer["ConnectionBroker"] -ne "$ConnectionBroker")
        {
            Write-Verbose -Message "Required connection broker differs from currently deployed connection broker."
            $returnValue=$false
        }
        $diff = Compare-Object -ReferenceObject $Server -DifferenceObject $CurrentRDServer["Server"]
        if(($diff | Where-Object{$_.SideIndicator -eq "<="}) -ne $null -and $returnValue)
        {
            Write-Verbose -Message "Required RDS servers list differs from currently deployed. $($diff.InputObject)"
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