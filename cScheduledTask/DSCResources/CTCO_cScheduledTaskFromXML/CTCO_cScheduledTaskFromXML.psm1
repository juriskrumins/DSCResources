function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
      [Parameter(Mandatory=$true)]
      [String]$TaskName,
      [Parameter(Mandatory=$true)]
      [String]$XML,
      [Parameter(Mandatory=$true)]
      [String]$User,
      [Parameter(Mandatory=$true)]
      [String]$Password,
      [Parameter(Mandatory=$false)]
      [String]$TaskPath="\",
      [parameter(Mandatory = $true)]
      [PSCredential] $DomainAdministratorCredential
     )

    $returnValue = @{}
    try
    {
        $ErrorActionPreference = "Stop"
        Write-Verbose "Getting required scheduled task values"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
        if($task -eq $null) 
        {
            $taskXML=$null
        }
        else
        {
            $taskXML = Export-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath | Out-String
        }
        $returnValue = @{
            TaskName = $task.TaskName
            TaskPath = $task.TaskPath
            XML = $taskXML
            User = $task.Principal.UserId
            Password = $Password
            DomainAdministratorCredential = $DomainAdministratorCredential
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
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
	$returnValue
}

function Set-TargetResource
{
    param (
      [Parameter(Mandatory=$true)]
      [String]$TaskName,
      [Parameter(Mandatory=$true)]
      [String]$XML,
      [Parameter(Mandatory=$true)]
      [String]$User,
      [Parameter(Mandatory=$true)]
      [String]$Password,
      [Parameter(Mandatory=$false)]
      [String]$TaskPath="\",
      [parameter(Mandatory = $true)]
      [PSCredential] $DomainAdministratorCredential
     )

    try
    {
        $ErrorActionPreference = "Stop"
        Write-Verbose "Registering scheduled task ..."
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -XML $XML -User $User -Password $Password
        Write-Verbose "Scheduled task registration completed."
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
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

function Test-TargetResource
{
    [OutputType([Boolean])]
    param (
      [Parameter(Mandatory=$true)]
      [String]$TaskName,
      [Parameter(Mandatory=$true)]
      [String]$XML,
      [Parameter(Mandatory=$true)]
      [String]$User,
      [Parameter(Mandatory=$true)]
      [String]$Password,
      [Parameter(Mandatory=$false)]
      [String]$TaskPath="\",
      [parameter(Mandatory = $true)]
      [PSCredential] $DomainAdministratorCredential
     )

    $retValue = $false
    Write-Verbose "Getting required scheduled task"
    $TaskStatus = Get-TargetResource  -TaskName $TaskName -XML $XML -User $User -Password $Password -TaskPath $TaskPath  -DomainAdministratorCredential $DomainAdministratorCredential
    if($TaskStatus.TaskName -eq $null)
    {
        Write-Verbose -Message "No Scheduled Task have been found. Need to create one."
    }
    else
    {
        Write-Verbose -Message "Scheduled Task have been found. Everything looks good"
        $retValue = $true
    }
    return $retValue
}

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