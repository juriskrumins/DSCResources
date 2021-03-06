#region Get-TargetResource
function Get-TargetResource
{
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [parameter(Mandatory = $true)]
		[String] $Id,

        [parameter(Mandatory = $true)]
		[String] $QueueName,

		[parameter(Mandatory = $true)]
		[String]  $Username,

		[parameter(Mandatory = $true)]
		[String[]] $MessageQueueAccessRights,

		[parameter(Mandatory = $true)]
        [ValidateSet("Allow","Deny")]
		[String] $MessageQueueAccessType,

        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential
	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference="Stop"
        Write-Verbose "Checking for MSMQ queue $QueueName ..."
        $ScriptBlock={param([String]$q) Get-MSMQQueue -Name $q}
        $queue = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName . -Credential $DomainAdministratorCredential -ArgumentList $QueueName -ErrorAction SilentlyContinue
        if($queue -ne $null)
        {
            Write-Verbose "Got MSMQ Queue $($QueueName) object."
            Write-Verbose "Getting MSMQ queue ACL list ..."
            $ScriptBlock=
            {
                param(
                    [String]$q,
                    [String]$u,
                    [String]$t
                )
                Get-MsmqQueue -Name $q | Get-MsmqQueueACL | Where-Object {($_.AccountName -eq "$u") -and ($_.Access -eq "$t")}
            }
            $queueacls=Invoke-Command -ScriptBlock $ScriptBlock -ComputerName . -Credential $DomainAdministratorCredential -ArgumentList $QueueName,$Username,$MessageQueueAccessType
            Write-Verbose "Got MSMQ queue ACL list."
            $count=0
            Foreach ($MessageQueueAccessRight in $MessageQueueAccessRights)
            {
                if($queueacls.Right -contains $MessageQueueAccessRight) 
                {
                    Write-Verbose -Message "MSMQ Queue ACL contains $MessageQueueAccessRight right to user $Username"
                    $count++
                }
            }
            if($MessageQueueAccessRights.Count -eq $count)
            {
                Write-Verbose -Message "MSMQ Queue ACL contains all necessary rights with appropriate access type for user $Username"
                $returnValue.Id=$Id
                $returnValue.QueueName=($queue.QueueName -split "\\")[1]
                $returnValue.Username = $Username
                $returnValue.MessageQueueAccessRights = $queueacls.Right
                $returnValue.MessageQueueAccessType = $MessageQueueAccessType
                $returnValue.DomainAdministratorCredential = $DomainAdministratorCredential
            }
            else
            {
                Write-Verbose -Message "Some necessary rights for user $Username are not defined within MSMQ Queue $QueueName ACL list."
            }
        }
        else
        {
            Write-Verbose -Message "Can't get MSMQ Queue $QueueName object."
        }
    }
    catch 
    {
        Write-Verbose "Error occured. $($_)"
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
		[String] $Id,

        [parameter(Mandatory = $true)]
		[String] $QueueName,

		[parameter(Mandatory = $true)]
		[String]  $Username,

		[parameter(Mandatory = $true)]
		[String[]] $MessageQueueAccessRights,

		[parameter(Mandatory = $true)]
        [ValidateSet("Allow","Deny")]
		[String] $MessageQueueAccessType,

        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential
	)

    try
    {
        $ErrorActionPreference = "Stop"
        Write-Verbose "Setting up MSMQ Queue $QueueName ACL rights for user $Username ."
        $ScriptBlock={
			param(
				[String] $QueueName,
				[String]  $Username,
				[String[]] $MessageQueueAccessRight,
				[ValidateSet("Allow","Deny")]
				[String] $MessageQueueAccessType
			) 
			$params = @{}
			$queue = Get-MSMQQueue -Name $QueueName
			$params.Add("InputObject",$queue)
			$params.Add("Username",$Username)
			switch ($MessageQueueAccessType)
			{
				"Allow" {$params.Add("Allow","$MessageQueueAccessRight"); Break;}
				"Deny" {$params.Add("Deny","$MessageQueueAccessRight"); Break;}
			}
			Set-MsmqQueueACL @params
		}
	    Foreach($MessageQueueAccessRight in $MessageQueueAccessRights)
	    {
		    Invoke-Command -ScriptBlock $ScriptBlock -ComputerName . -Credential $DomainAdministratorCredential -ArgumentList $QueueName,$Username,$MessageQueueAccessRight,$MessageQueueAccessType
	    }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)"
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
		[String] $Id,

        [parameter(Mandatory = $true)]
		[String] $QueueName,

		[parameter(Mandatory = $true)]
		[String]  $Username,

		[parameter(Mandatory = $true)]
		[String[]] $MessageQueueAccessRights,

		[parameter(Mandatory = $true)]
        [ValidateSet("Allow","Deny")]
		[String] $MessageQueueAccessType,

        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential
	)

    $retValue = $false
    $queuestatus = Get-TargetResource -Id $Id -QueueName $QueueName -Username $Username -MessageQueueAccessRights $MessageQueueAccessRights -MessageQueueAccessType $MessageQueueAccessType -DomainAdministratorCredential $DomainAdministratorCredential
    if($queuestatus.Count -ne 0)
    {
        Write-Verbose -Message "All necessary rights $MessageQueueAccessRights are provided for user $Username for MSMQ Queue $QueueName"
        $retValue = $true
    }
    else
    {
        Write-Verbose -Message "Some rights are missing for user $Username for MSMQ Queue $QueueName. Need to setup those."
    }
    return $retValue
}
#endregion Test-TargetResource

Export-ModuleMember -Function *-TargetResource

