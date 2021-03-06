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
		[System.String[]]
		$SessionHost
	)

    $returnValue=@{}
    try
    {
        Import-Module -Name RemoteDesktop -Force
        $RDDeployment = Get-RDServer -ConnectionBroker $ConnectionBroker -ErrorAction Stop
        $RDSConnectionBroker=""
        $RDSRDServers =@()
        if($RDDeployment -ne $null)
        {
            Write-Verbose -Message "RDS deployment has been found."
            Foreach($Server in $RDDeployment){
                if("RDS-CONNECTION-BROKER" -in $Server.Roles)
                {
                    $RDSConnectionBroker=$Server.Server
                }
                if("RDS-RD-SERVER" -in $Server.Roles)
                {
                    $RDSRDServers+=$Server.Server
                }
            }
            $returnValue.Add('ConnectionBroker',$RDSConnectionBroker)
            $returnValue.Add('SessionHost',$RDSRDServers)
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
		[System.String]
		$ConnectionBroker,

		[parameter(Mandatory = $true)]
		[System.String[]]
		$SessionHost
	)

    try
    {
        Import-Module -Name RemoteDesktop -Force
        $CurrentRDSessionDeployment=Get-TargetResource -ConnectionBroker $ConnectionBroker -SessionHost $SessionHost
        if(($CurrentRDSessionDeployment.Count -eq 0) -or ($CurrentRDSessionDeployment.Count -ne 0 -and $CurrentRDSessionDeployment["SessionHost"].Count -eq 0))
        {
            Write-Verbose -Message "Creating new RDSessionDeployment with ConnectionBroker $ConnectionBroker  and SessionHost $SessionHost"
            New-RDSessionDeployment -ConnectionBroker $ConnectionBroker -SessionHost $SessionHost -ErrorAction Stop
            Write-Verbose -Message "New RDSessionDeployment has been finished"
        }
        else
        {
            Write-Verbose -Message "Looks like we already have RDSessionDeployment with ConnectionBroker $ConnectionBroker"
            Write-Verbose -Message "Going to check is all required RDS session hosts are a part of deployment"
            $diff=Compare-Object -ReferenceObject $SessionHost -DifferenceObject $CurrentRDSessionDeployment["SessionHost"]
            if(($diff | Where-Object{$_.SideIndicator -eq "<="}) -ne $null)
            {
                Write-Verbose -Message "Looks like some RDS Session hosts are missing from deployment."
                Foreach($RDSSessionHost in $diff.InputObject)
                {
                    Write-Verbose -Message "Going to add $RDSSessionHost to existing deployment."
                    Add-RDServer -Server $RDSSessionHost -Role RDS-RD-SERVER -ConnectionBroker $ConnectionBroker -ErrorAction Stop
                    Write-Verbose -Message "Adding $RDSSessionHost to existing deployment has been finished."
                }
            }
            else
            {
                Write-Verbose -Message "Looks like deployment has been setup correctly. Nothing to do."
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
		[System.String]
		$ConnectionBroker,

		[parameter(Mandatory = $true)]
		[System.String[]]
		$SessionHost
	)

    $returnValue=$true
    try
    {
        $CurrentRDSessionDeployment=Get-TargetResource -ConnectionBroker $ConnectionBroker -SessionHost $SessionHost
        if($CurrentRDSessionDeployment["ConnectionBroker"] -ne "$ConnectionBroker")
        {
            Write-Verbose -Message "Required connection broker differs from currently deployed connection broker."
            $returnValue=$false
        }
        $diff = Compare-Object -ReferenceObject $SessionHost -DifferenceObject $CurrentRDSessionDeployment["SessionHost"]
        if(($diff | Where-Object{$_.SideIndicator -eq "<="}) -ne $null -and $returnValue)
        {
            Write-Verbose -Message "Required RDS session host list differs from currently deployed. $($diff.InputObject)"
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