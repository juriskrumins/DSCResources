function Get-TargetResource
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param
    (
        [Int32]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $Id,
        [String]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Idle","BelowNormal","Normal","AboveNormal","High","Realtime")]
        $Priority,
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $PriorityBoostEnabled=$true,
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $IncludeParentProcess=$false
    )

    $returnValue = @{}
    try 
    {
        $ErrorActionPreference="Stop"
        if($id -eq -1)
        {
            Write-Verbose "Specified processid is -1. Actual process ID will be $PID"
            $Id=$PID
        }
        $Process=Get-Process -Id $Id
        Write-Verbose "Getting process's with Id $Id priority"
        $returnValue.Id=$Process.Id
        $returnValue.Priority=$Process.PriorityClass
        $returnValue.PriorityBoostEnabled=$Process.PriorityBoostEnabled
        $returnValue.IncludeParentProcess=$IncludeParentProcess
    }
    catch 
    {
        Write-Verbose "Error occured $_"
        "Error occured $_"
    }
	$returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [Int32]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $Id,
        [String]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Idle","BelowNormal","Normal","AboveNormal","High","Realtime")]
        $Priority,
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $PriorityBoostEnabled=$true,
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $IncludeParentProcess=$false
    )

    try 
    {
        $ErrorActionPreference="Stop"
        if($id -eq -1)
        {
            Write-Verbose "Specified processid is -1. Actual process ID will be $PID"
            $Id=$PID
        }
        $Process=Get-Process -Id $Id
        if($IncludeParentProcess)
        {
            Write-Verbose -Message "Getting process object for parent process."
            $PPid=(Get-WmiObject -Class win32_process -Filter "processid='$Id'").parentprocessid
            $ParentProcess=Get-Process -Id $PPid
        }
        Write-Verbose "Setting process's with Id $Id priority to $Priority"
        $Process.PriorityClass="$Priority"
        $Process.PriorityBoostEnabled=$PriorityBoostEnabled
        if($IncludeParentProcess) 
        {
            $ParentProcess.PriorityClass="$Priority"
            $ParentProcess.PriorityBoostEnabled=$PriorityBoostEnabled
        }
    }
    catch 
    {
        Write-Verbose "Error occured $_"
        "Error occured $_"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    Param
    (
        [Int32]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $Id,
        [String]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Idle","BelowNormal","Normal","AboveNormal","High","Realtime")]
        $Priority,
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $PriorityBoostEnabled=$true,
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $IncludeParentProcess=$false
    )

    $retValue = $false
    try 
    {
        $ErrorActionPreference="Stop"
        if($id -eq -1)
        {
            Write-Verbose "Specified processid is -1. Actual process ID will be $PID"
            $Id=$PID
        }
        Write-Verbose -Message "Getting process object for process with id $Id."
        $Process=Get-Process -Id $Id
        if($IncludeParentProcess)
        {
            Write-Verbose -Message "Getting process object for parent process."
            $PPid=(Get-WmiObject -Class win32_process -Filter "processid='$Id'").parentprocessid
            $ParentProcess=Get-Process -Id $PPid
        }
        Write-Verbose "Checking if process's with Id $Id priority is $Priority"
        if($Process.PriorityClass -eq "$Priority" -and $Process.PriorityBoostEnabled -eq $PriorityBoostEnabled )
        {
            Write-Verbose "Process's with Id $Id priority is $Priority and PriorityBoostEnabled is $PriorityBoostEnabled. We'll skip setting priority and PriorityBoostEnabled attribute on process"
            if($IncludeParentProcess)
            {
                Write-Verbose -Message "Checking process parent's priority and  PriorityBoostEnabled attribute"
                if($ParentProcess.PriorityClass -eq "$Priority" -and $ParentProcess.PriorityBoostEnabled -eq $PriorityBoostEnabled )
                {
                    Write-Verbose "Parent process's priority is $Priority and PriorityBoostEnabled is $PriorityBoostEnabled. We'll skip setting priority and PriorityBoostEnabled attribute on parent process"
                    $retValue = $true
                }
                else
                {
                    Write-Verbose "Parent process's priority is $($ParentProcess.PriorityClass) and PriorityBoostEnabled is $($ParentProcess.PriorityBoostEnabled). It'll be necessary to adjust process priority and/or PriorityBoostEnabled attribute."
                }
            }
            else
            {
                $retValue = $true
            }
        }
        else
        {
            Write-Verbose "Process's with Id $Id priority is $($Process.PriorityClass) and PriorityBoostEnabled is $($Process.PriorityBoostEnabled). It'll be necessary to adjust process priority and/or PriorityBoostEnabled attribute."
        }

    }
    catch 
    {
        Write-Verbose "Error occured $_"
        "Error occured $_"
    }
    return $retValue
}

Export-ModuleMember -Function *-TargetResource