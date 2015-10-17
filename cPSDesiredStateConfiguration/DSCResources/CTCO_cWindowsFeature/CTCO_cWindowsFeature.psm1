function Get-TargetResource 
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
    param 
    (      
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Id,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $WindowsFeature
    )

    $retValue=@{}
    $InstalledFeatures=(Get-WindowsFeature -Name $WindowsFeature | Where-Object {$_.InstallState -eq "Installed"}).Name
    $retValue.WindowsFeature=$InstalledFeatures
    return $retValue
}


function Set-TargetResource 
{
    [CmdletBinding()]
    param 
    (      
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Id,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $WindowsFeature
    )

    Install-WindowsFeature -Name $WindowsFeature

}

# The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
function Test-TargetResource 
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
    param 
    (      
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Id,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $WindowsFeature
    )

    $return=$false
    $InstalledFeatures=(Get-TargetResource -Id $Id -WindowsFeature $WindowsFeature).WindowsFeature
    if($InstalledFeatures.Count -eq $WindowsFeature.Count)
    {
        Write-Verbose -Message "Seems like all features are already installed"
        $return=$true
    }
    else
    {
        Write-Verbose -Message "Some features are still missing. It'll be necessary to installed them."
    }
    return $return

}


Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
