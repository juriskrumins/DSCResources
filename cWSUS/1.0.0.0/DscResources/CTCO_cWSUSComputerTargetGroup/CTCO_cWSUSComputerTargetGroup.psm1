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
        [System.String[]]
        $ComputerTargetGroup
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting available WSUS's computer target groups."
        $wsusServer = Get-WsusServer -ErrorAction Stop
        $ComputerTargetGroups = $wsusServer.GetComputerTargetGroups().Name
        $returnValue.Add('Id',$Id)
        $returnValue.Add('ComputerTargetGroup',$ComputerTargetGroups)
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
        [System.String[]]
        $ComputerTargetGroup
    )
    try
    {
        $currentState = Get-TargetResource -Id $Id -ComputerTargetGroup $ComputerTargetGroup
        [System.Collections.ArrayList]$ctg=$currentState.ComputerTargetGroup
        $ctg.Remove("All Computers")
        $ctg.Remove('Unassigned Computers')
        $currentState.ComputerTargetGroup=$ctg
        $diff=Compare-Object -ReferenceObject $ComputerTargetGroup -DifferenceObject $currentState.ComputerTargetGroup
        Write-Verbose -Message "Creating computer target groups: $(($diff | Where-Object{$_.SideIndicator -eq '<='}).InputObject -join ',')"
        $myWsus = Get-WsusServer -ErrorAction Stop
        Foreach($ComputerGroup in ($diff | Where-Object{$_.SideIndicator -eq '<='}).InputObject)
        {
            $myWsus.CreateComputerTargetGroup("$ComputerGroup") | Out-Null
        }
        Write-Verbose -Message "Computer target groups created."

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
        [System.String[]]
        $ComputerTargetGroup
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -Id $Id -ComputerTargetGroup $ComputerTargetGroup
        [System.Collections.Generic.List[System.String]]$ctg=$currentState.ComputerTargetGroup
        $ctg.Remove('All Computers') | Out-Null
        $ctg.Remove('Unassigned Computers') | Out-Null
        $currentState.ComputerTargetGroup=$ctg
        if ( $currentState.Count -ne 0 )
        {
            Write-Verbose -Message "Got WSUS's computer target group list."
            $diff=Compare-Object -ReferenceObject $ComputerTargetGroup -DifferenceObject $currentState.ComputerTargetGroup
            if($diff -eq $null)
            {
                Write-Verbose -Message "Required and actual target group list are in desired state"
            }
            else
            {
                Write-Verbose -Message "Required and actual target group list are not in desired state"
                Write-Verbose -Message "Required computer taget groups that are missed (ignore build-in groups): $(($diff | Where-Object{$_.SideIndicator -eq '<='}).InputObject -join ',')"
                Write-Verbose -Message "Computer taget groups that exists, but are not in required list (ignore build-in groups): $(($diff | Where-Object{$_.SideIndicator -eq '=>'}).InputObject -join ',')"
                $returnValue = $false
            }
        }
        else
        {
            Write-Verbose -Message "Can't WSUS's computer target group list."
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