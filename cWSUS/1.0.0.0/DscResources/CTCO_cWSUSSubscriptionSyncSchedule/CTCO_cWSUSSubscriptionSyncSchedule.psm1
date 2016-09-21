function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $SynchronizeAutomatically,
        [parameter(Mandatory = $false)]
        [System.Int32]
        [ValidateRange(1,24)]
        $NumberOfSynchronizationsPerDay=1
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting WSUS subscription synchronization schedule configuration ...."
        $WSUSServer = Get-WsusServer -ErrorAction SilentlyContinue
        if($WSUSServer -ne $null)
        {
            $mysubs = $WSUSServer.GetSubscription()
            $returnValue.Add('Id',$Id)
            $returnValue.Add('SynchronizeAutomatically',$mysubs.SynchronizeAutomatically)
            $returnValue.Add('NumberOfSynchronizationsPerDay',$mysubs.NumberOfSynchronizationsPerDay)
        }
        else
        {
            Write-Verbose -Message "Can't get WSUS server object."
        }
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
    }
    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $SynchronizeAutomatically,
        [parameter(Mandatory = $false)]
        [System.Int32]
        [ValidateRange(1,24)]
        $NumberOfSynchronizationsPerDay=1
    )
    try
    {
        $myWsus = Get-WsusServer -ErrorAction Stop
        $mysubs = $myWsus.GetSubscription()
        Write-Verbose -Message "Setting up SynchronizeAutomatically property."
        $mysubs.SynchronizeAutomatically = $SynchronizeAutomatically
        Write-Verbose -Message "Setting up NumberOfSynchronizationsPerDay property."
        $mysubs.NumberOfSynchronizationsPerDay = $NumberOfSynchronizationsPerDay
        $mysubs.Save()
        Write-Verbose -Message "WSUS subscription synchronization schedule has been configured succesfully"
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $SynchronizeAutomatically,
        [parameter(Mandatory = $false)]
        [System.Int32]
        [ValidateRange(1,24)]
        $NumberOfSynchronizationsPerDay=1
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -Id $Id -SynchronizeAutomatically $SynchronizeAutomatically -NumberOfSynchronizationsPerDay $NumberOfSynchronizationsPerDay
        if ( $currentState.Count -ne 0 )
        {
            Write-Verbose -Message "Got WSUS subscription synchronization schedule configuration."
            Write-Verbose -Message "Check if it's in desired state."
            if($currentState.SynchronizeAutomatically -ne $SynchronizeAutomatically)
            {
                Write-Verbose -Message "SynchronizeAutomatically property is not in desired state"
                $returnValue = $false
            }
            if($currentState.NumberOfSynchronizationsPerDay -ne $NumberOfSynchronizationsPerDay)
            {
                Write-Verbose -Message "NumberOfSynchronizationsPerDay property is not in desired state"
                $returnValue = $false
            }
        }
        else
        {
            Write-Verbose -Message "Can't get current WSUS subscription synchronization schedule configuration."
            $returnValue=$false
        }
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
    }
    $returnValue
}

Export-ModuleMember -Function *-TargetResource