#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$CollectionName,

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
        Write-Verbose -Message "Looking for a RD Session collection  $CollectionName on RD connection broker $ConnectionBroker"
        $RDSessionCollection = Get-RDSessionCollection -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue
        if($RDSessionCollection -ne $null)
        {
            Write-Verbose -Message "RD Session collection $CollectionName on RD connection broker $ConnectionBroker has been found."
            $returnValue.Add('CollectionName',$RDSessionCollection.CollectionName)
            $returnValue.Add('ConnectionBroker',$ConnectionBroker)
            Write-Verbose -Message "Collecting RD Session collection's RD Session hosts list."
            $RDSessionHost=Get-RDSessionHost -CollectionName $CollectionName -ConnectionBroker $ConnetionBroker -ErrorAction Stop
            $RDSessionHostList=@()
            Foreach($RDHost in $RDSessionHost)
            {
                $RDSessionHostList+=$RDHost.SessionHost.ToString()
            }
            $returnValue.Add('SessionHost',$RDSessionHostList)
        }
        else
        {
            Write-Verbose -Message "No RD Session collection  $CollectionName on RD connection broker $ConnectionBroker has been found."
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
		$CollectionName,

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
        $CurrentRDSessionCollection=Get-TargetResource -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -SessionHost $SessionHost
        if($CurrentRDSessionCollection.Count -ne 0)
        {
            Write-Verbose -Message "RD Session collection  $CollectionName on RD connection broker $ConnectionBroker has been found."
            if($CurrentRDSessionCollection["CollectionName"] -eq $CollectionName)
            {
                $diff=Compare-Object -ReferenceObject $SessionHost -DifferenceObject $CurrentRDSessionCollection["SessionHost"]
                if("<=" -in $diff.SideIndicator)
                {
                    Write-Verbose -Message "Looks like current RD Session Host list differs from desired list. Hosts not in current session host list $(($diff | Where-Object{$_.SideIndicator -eq "<="}).InputObject)"
                    Write-Verbose -Message "Going to add those hosts to collection's RD Session Host list"
                    $RDSessionHostList=@()
                    Foreach($RDSessionHost in ($diff | Where-Object{$_.SideIndicator -eq "<="}).InputObject)
                    {
                        $RDSessionHostList+=$RDSessionHost
                    }
                    Add-RDSessionHost -CollectionName $CollectionName -SessionHost $RDSessionHostList -ConnectionBroker $ConnectionBroker
                }
                else
                {
                    Write-Verbose -Message "Looks like current RD Session Host list and desired host list equals. Nothing to do"
                }
            }
            else
            {
                Write-Verbose -Message "Current Collection name differs from desired name. This is strange; don't know what to do."
            }
        }
        else
        {
            Write-Verbose -Message "No RD Session collection  $CollectionName on RD connection broker $ConnectionBroker has been found. Going to create it."
            New-RDSessionCollection -CollectionName $CollectionName -SessionHost $SessionHost -ConnectionBroker $ConnectionBroker -ErrorAction Stop
            Write-Verbose -Message "RD Session collection  $CollectionName on RD connection broker $ConnectionBroker has been created."
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
		$CollectionName,

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
        $CurrentRDSessionCollection=Get-TargetResource -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -SessionHost $SessionHost
        if($CurrentRDSessionCollection.Count -ne 0)
        {
            Write-Verbose -Message "RD Session collection  $CollectionName on RD connection broker $ConnectionBroker has been found."
            if($CurrentRDSessionCollection["CollectionName"] -eq $CollectionName)
            {
                $diff=Compare-Object -ReferenceObject $SessionHost -DifferenceObject $CurrentRDSessionCollection["SessionHost"]
                if("<=" -in $diff.SideIndicator)
                {
                    Write-Verbose -Message "Looks like current RD Session Host list differs from desired list. Hosts not in current session host list $(($diff | Where-Object{$_.SideIndicator -eq "<="}).InputObject)"
                    $returnValue=$false
                }
                else
                {
                    Write-Verbose -Message "Looks like current RD Session Host list and desired host list equals."
                }
            }
            else
            {
                Write-Verbose -Message "Current Collection name differs from desired name."
                $returnValue=$false
            }
        }
        else
        {
            Write-Verbose -Message "No RD Session collection  $CollectionName on RD connection broker $ConnectionBroker has been found."
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