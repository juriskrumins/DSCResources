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
        $UpdateLanguages
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting WSUS update languages..."
        $wsusServer = Get-WsusServer -ErrorAction Stop
        $wsusconf=$wsusServer.GetConfiguration()
        if($wsusconf.AllUpdateLanguagesEnabled -eq $True)
        {
            $returnValue.Add('Id',$Id)
            $returnValue.Add('UpdateLanguages',@("All"))
        }
        else
        {
            $returnValue.Add('Id',$Id)
            $returnValue.Add('UpdateLanguages',@($wsusconf.GetEnabledUpdateLanguages()))
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
        [System.String[]]
        $UpdateLanguages
    )
    try
    {
        $wsusServer = Get-WsusServer -ErrorAction Stop
        $wsusconf=$wsusServer.GetConfiguration()
        if($UpdateLanguages.Length -eq 1 -and $UpdateLanguages[0] -eq 'All')
        {
            Write-Verbose -Message "All update languages are selected."
            $wsusconf.AllUpdateLanguagesEnabled=$true
        }
        else
        {
            Write-Verbose -Message "Selected update languages: $($UpdateLanguages)."
            $wsusconf.AllUpdateLanguagesEnabled=$false
            $wsusconf.SetEnabledUpdateLanguages($UpdateLanguages)
        }
        Write-Verbose -Message "Saving new WSUS update languages configuration."
        $wsusconf.Save()
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
        $UpdateLanguages
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -Id $Id -UpdateLanguages $UpdateLanguages
        if ( $currentState.Count -ne 0 )
        {
            Write-Verbose -Message "Got update languages list."
            if($currentState.UpdateLanguages -ne $null)
            {
                $diff=Compare-Object -ReferenceObject $UpdateLanguages -DifferenceObject $currentState.UpdateLanguages
                if($diff -eq $null)
                {
                    Write-Verbose -Message "All requested update languages are selected"
                }
                else
                {
                    Write-Verbose -Message "Selected languages. $($currentState.UpdateLanguages)"
                    Write-Verbose -Message "Update languages configurationis  not in desired state. Requested update languages: $($UpdateLanguages) "
                    $returnValue = $false
                }
            }
            else
            {
                Write-Verbose -Message "Update language list is currently empty"
                $returnValue = $false
            }
        }
        else
        {
            Write-Verbose -Message "Can't get update languages list."
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