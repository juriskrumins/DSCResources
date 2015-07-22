#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

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

Export-ModuleMember -Function *-TargetResource