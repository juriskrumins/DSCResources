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
        $Classification
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting WSUS's enabled update classifications ..."
        $wsusServer = Get-WsusServer -ErrorAction Stop
        $wsusSubscription = $wsusServer.GetSubscription()
        $selectedClassificatins = $wsusSubscription.GetUpdateClassifications().Title
        $returnValue.Add('Id',$Id)
        $returnValue.Add('Classification',$selectedClassificatins)
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
        $Classification
    )
    try
    {
        Write-Verbose -Message "Collecting all update classifications"
        $myUpdateClassificationsAll = Get-WsusClassification
        Write-Verbose -Message "Disabling all update classifications"
        $myUpdateClassificationsAll | Set-WsusClassification -Disable -ErrorAction Stop -Confirm:$false
        Write-Verbose -Message "Enabling required update classifications"
        $myUpdateClassifications = Get-WsusClassification | Where-Object {$_.Classification.Title -in $Classification}
        $myUpdateClassifications | Set-WsusClassification -ErrorAction Stop -Confirm:$false
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
        $Classification
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -Id $Id -Classification $Classification
        if ( $currentState.Count -ne 0 )
        {
            Write-Verbose -Message "Got selected update classifications."
            $diff=Compare-Object -ReferenceObject $Classification -DifferenceObject $currentState.Classification
            if($diff -eq $null)
            {
                Write-Verbose -Message "All requested update classifications are selected"
            }
            else
            {
                Write-Verbose -Message "Not all requested update classifications are selected. Missing classifications: $(($diff | Where-Object {$_.SideIndicator -eq "<="}).InputObject -join ',')"
                Write-Verbose -Message "Not all selected update classifications are required. Selected classifications: $(($diff | Where-Object {$_.SideIndicator -eq "=>"}).InputObject -join ',')"
                $returnValue = $false
            }
        }
        else
        {
            Write-Verbose -Message "Can't get selected update classifications."
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