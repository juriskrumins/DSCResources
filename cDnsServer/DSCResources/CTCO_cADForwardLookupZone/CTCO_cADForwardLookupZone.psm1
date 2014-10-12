#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$ServerName,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
	)


    try
    {
        Write-Verbose "Checking for DNS zone $Name on server $ServerName ..."
        $returnValue = @{}
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $returnValue.DomainAdministratorCredential = $DomainAdministratorCredential
        $returnValue.ServerName = $ServerName
        $DNSServerZone=Get-DNSServerZone -Name $Name  -ComputerName $ServerName -ErrorAction SilentlyContinue -ErrorVariable e
        if($DNSServerZone -ne $null) 
        {
            Write-Verbose "DNS zone $Name found on server $ServerName"
            $returnValue.Name = $DNSServerZone.ZoneName
        }
        else
        {
            Write-Verbose "Can't find DNS zone $Name on server $ServerName"
            $returnValue.Name = $null
        }
    }
    catch 
    {
        Write-Verbose "Error occured while checking to DNS zone $Name on server $ServerName. $_.Message"
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
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$ServerName,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
	)

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Adding DNS zone $Name on server $ServerName ..."
        $DnsServerPrimaryZone = Add-DnsServerPrimaryZone -Name $Name -ComputerName $ServerName -ReplicationScope "Forest" -PassThru -ErrorAction SilentlyContinue -ErrorVariable e
        if($DnsServerPrimaryZone -ne $null)
        {
            Write-Verbose "DNS zone $Name on server $ServerName created."
        }
        else 
        {
            Write-Verbose "Failed to cteate DNS zone $Name on server $ServerName"
        }
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
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$ServerName,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
	)

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Check state DNS zone $Name on server $ServerName ..."
        $DNSServerZone=Get-DNSServerZone -Name $Name -ComputerName $ServerName -ErrorAction SilentlyContinue -ErrorVariable e
        if($DNSServerZone -ne $null) 
        {
            Write-Verbose "DNS zone $Name exists on server $ServerName"
            $returnValue=$true
        }
        else 
        {
            Write-Verbose "Can't find DNS zone $Name on server $ServerName"
            $returnValue=$false
        }
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
    return $returnValue
}
#endregion Test-TargetResource

#region Additional functions
function Get-ImpersonatetLib
{
    if ($script:ImpersonateLib)
    {
        return $script:ImpersonateLib
    }

    $sig = @'
[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

[DllImport("kernel32.dll")]
public static extern Boolean CloseHandle(IntPtr hObject);
'@ 
   $script:ImpersonateLib = Add-Type -PassThru -Namespace 'Lib.Impersonation' -Name ImpersonationLib -MemberDefinition $sig 

   return $script:ImpersonateLib
    
}

function ImpersonateAs([PSCredential] $cred)
{
    [IntPtr] $userToken = [Security.Principal.WindowsIdentity]::GetCurrent().Token
    $userToken
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::LogonUser($cred.GetNetworkCredential().UserName, $cred.GetNetworkCredential().Domain, $cred.GetNetworkCredential().Password, 
    9, 0, [ref]$userToken)
    
    if ($bLogin)
    {
        $Identity = New-Object Security.Principal.WindowsIdentity $userToken
        $context = $Identity.Impersonate()
    }
    else
    {
        throw "Can't Logon as User $cred.GetNetworkCredential().UserName."
    }
    $context, $userToken
}

function CloseUserToken([IntPtr] $token)
{
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::CloseHandle($token)
    if (!$bLogin)
    {
        throw "Can't close token"
    }
}
#endregion Additional functions

Export-ModuleMember -Function *-TargetResource

