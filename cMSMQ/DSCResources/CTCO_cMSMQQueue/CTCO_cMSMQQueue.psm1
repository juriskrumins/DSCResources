#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

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

Export-ModuleMember -Function *-TargetResource

