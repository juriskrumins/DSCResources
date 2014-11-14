#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$QueueName,

		[parameter(Mandatory = $true)]
        [ValidateSet("Private","Public")]
        [string] $QueueType,

        [parameter(Mandatory = $true)]
        [boolean] $Transactional,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference="Stop"
        Write-Verbose "Checking for MSMQ queue $QueueName ..."
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $queue = Get-MSMQQueue -Name $QueueName -QueueType $QueueType -ErrorAction SilentlyContinue
        if($queue -ne $null)
        {
            $returnValue.QueueType=($queue.QueueName -split "\$")[0]
            $returnValue.QueueName=($queue.QueueName -split "\\")[1]
            $returnValue.Transactional=$queue.Transactional
            $returnValue.DomainAdministratorCredential = $DomainAdministratorCredential
        }
    }
    catch 
    {
        Write-Verbose "Error occured. Error message $($Error[0].Message)"
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
		$QueueName,

		[parameter(Mandatory = $true)]
        [ValidateSet("Private","Public")]
        [string] $QueueType,

        [parameter(Mandatory = $true)]
        [boolean] $Transactional,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
	)

    try
    {
        $ErrorActionPreference="Stop"
        Write-Verbose "Setting up MSMQ queue ..."
        $queueStatus = Get-TargetResource -QueueName $QueueName -QueueType $QueueType -Transactional $Transactional -DomainAdministratorCredential $DomainAdministratorCredential
		$params=@{
			Name = $QueueName
			QueueType = $QueueType
		}
		if($Transactional)
		{
			$params+=@{
				Transactional=$null
			}
		}
        if($queueStatus.Count -eq 0)
        {
            Write-Verbose "Creating new MSMQ queue ..."
            $ScriptBlock={param([System.Collections.Hashtable]$p) New-MSMQQueue @p}
            Invoke-Command -ScriptBlock $ScriptBlock -ComputerName . -Credential $DomainAdministratorCredential -ArgumentList $params
            Write-Verbose "New MSMQ queue created"
        }
        if($queueStatus.Count -ne 0)
        {
            Write-Verbose "Removing MSMQ queue ..."
            $ScriptBlock={param([String]$q) Get-MSMQQueue -Name $q | Remove-MSMQQueue}
            Invoke-Command -ScriptBlock $ScriptBlock -ComputerName . -Credential $DomainAdministratorCredential -ArgumentList $QueueName
            Write-Verbose "MSMQ queue removed."
            Write-Verbose "Creating new MSMQ queue ..."
            $ScriptBlock={param([System.Collections.Hashtable]$p) New-MSMQQueue @p}
            Invoke-Command -ScriptBlock $ScriptBlock -ComputerName . -Credential $DomainAdministratorCredential -ArgumentList $params
            Write-Verbose "New MSMQ queue created"
        }
    }
    catch 
    {
        Write-Verbose "Error occured. Error message $($Error[0].Message)"
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
		$QueueName,

		[parameter(Mandatory = $true)]
        [ValidateSet("Private","Public")]
        [string] $QueueType,

        [parameter(Mandatory = $true)]
        [boolean] $Transactional,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
	)

    $returnValue=$false
    $queueStatus = Get-TargetResource -QueueName $QueueName -QueueType $QueueType -Transactional $Transactional -DomainAdministratorCredential $DomainAdministratorCredential
    if($queueStatus.Count -ne 0)
    {
        if($queueStatus.QueueName -eq $QueueName -and $queueStatus.QueueType -eq $QueueType -and $queueStatus.Transactional -eq $Transactional)
        {
            Write-Verbose -Message "MSMQ exists and configured correctly"
            $returnValue=$true
        }
        else
        {
            Write-Verbose -Message "MSMQ exists, but configured incorrectly. Need to fix it."
        }
    }
    else
    {
        Write-Verbose -Message "can't find MSMQ queue. Need to create one."
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

