#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

#region Get-TargetResource
function Get-TargetResource
{
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [parameter(Mandatory = $true)]
		[String]
		$Key,

		[parameter(Mandatory = $true)]
		[String]
		$RRName,

		[parameter(Mandatory = $true)]
		[String]
		$RRValue,

		[parameter(Mandatory = $true)]
		[int]
		$RRPreference,

		[parameter(Mandatory = $true)]
		[String]
		$ZoneName,

        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential
	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference ="Stop"
        Write-Verbose "Checking for A DNS RR ..."
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $rrs=Get-DNSServerResourceRecord -ZoneName $ZoneName -Name $RRName -RRType MX -ErrorAction SilentlyContinue
        $rrhostname = $($rrs | Select-Object Hostname | Sort-Object -Unique).Hostname
        $rrdata = $rrs.RecordData.MailExchange
        $rrpreference=$rrs.RecordData.Preference
        $returnValue.Add("Key",$Key)
        $returnValue.Add("RRName",$rrhostname)
        $returnValue.Add("RRValue",$rrdata)
        $returnValue.Add("RRPreference",$rrpreference)
        $returnValue.Add("ZoneName",$ZoneName)
        $returnValue.Add("DomainAdministratorCredential",$DomainAdministratorCredential)
    }
    catch 
    {
        Write-Verbose "Error occured while checking for A DNS resource record. $($_)"
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()
            CloseUserToken($newToken)
        }
    }
    return $returnValue;


}
#endregion Get-TargetResource

#region Set-TargetResource
function Set-TargetResource
{
	param
	(
        [parameter(Mandatory = $true)]
		[String]
		$Key,

		[parameter(Mandatory = $true)]
		[String]
		$RRName,

		[parameter(Mandatory = $true)]
		[String]
		$RRValue,

		[parameter(Mandatory = $true)]
		[int]
		$RRPreference,

		[parameter(Mandatory = $true)]
		[String]
		$ZoneName,

        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential
	)

    try
    {
        $ErrorActionPreference = "Stop"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Setting up DNS resource record ..."
        Foreach($value in $RRValue)
        {
            Write-Verbose "Creating DNS resource record $RRName  = $ip in $ZoneName ..."
            Get-DNSServerResourceRecord -ZoneName $ZoneName -Name $RRName -RRType MX -ErrorAction SilentlyContinue | Remove-DnsServerResourceRecord -ZoneName $ZoneName -ErrorAction SilentlyContinue
            Add-DnsServerResourceRecord -ZoneName $ZoneName -Name $RRName -MX -MailExchange $value -Preference $RRPreference -Confirm:$false
        }
        Write-Verbose "DNS resource record created."
    }
    catch
    {
        Write-Verbose -Message "Error happened. $($_)"
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()
            CloseUserToken($newToken)
        }
    }
}
#endregion Set-TargetResource

#region Test-TargetResource
function Test-TargetResource
{
	[OutputType([System.Boolean])]
	param
	(
        [parameter(Mandatory = $true)]
		[String]
		$Key,

		[parameter(Mandatory = $true)]
		[String]
		$RRName,

		[parameter(Mandatory = $true)]
		[String]
		$RRValue,

		[parameter(Mandatory = $true)]
		[int]
		$RRPreference,

		[parameter(Mandatory = $true)]
		[String]
		$ZoneName,

        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential
	)

    $retValue = $false
    $rrstatus = Get-TargetResource -Key $Key -RRName $RRName -RRValue $RRValue -RRPreference $RRPreference -ZoneName $ZoneName -DomainAdministratorCredential $DomainAdministratorCredential
    if($rrstatus.Count -ne 0)
    {
        if(($rrstatus["RRName"] -eq $RRName) -and ($rrstatus["ZoneName"] -eq $ZoneName))
        {
            if($rrstatus["RRValue"] -contains $RRValue)
            {
                Write-Verbose -Message "DNS RR $RRName exists and configured correctly"
                $retValue = $true
            }
            if($rrstatus["RRValue"] -notcontains $RRValue)
            {
                Write-Verbose -Message "DNS RR $RRName exists, but RR RecordData don't contain $RRValue. Need to set it up."
            }
        }
        else
        {
            Write-Verbose -Message "Strange thing happened."
        }
    }
    else
    {
        Write-Verbose -Message "No DNS RR record found for RR $RRName using value $RRValue in $ZoneName. It is necessary to create one."
    }
    return $retValue
}
#endregion Test-TargetResource

Export-ModuleMember -Function *-TargetResource

