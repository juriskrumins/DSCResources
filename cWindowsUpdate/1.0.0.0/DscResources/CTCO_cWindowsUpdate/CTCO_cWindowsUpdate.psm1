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
        $UpdateId,
        [parameter(Mandatory = $false)]
        [ValidateSet("Software")]
        [System.String]
        $UpdateType='Software',
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Reboot=$false
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting updates information ...."
        $updateSession = new-object -com "Microsoft.Update.Session" -ErrorAction Stop
        $installedUpdates=$updateSession.CreateupdateSearcher().Search(("IsInstalled=1 and Type='$UpdateType'")).Updates
        if($installedUpdates.Count -ne 0 )
        {
            Write-Verbose -Message "Installed updates of type $UpdateType found."
            $installedUpdateIDs=@()
            foreach($installedUpdate in $installedUpdates)
            {
                $installedUpdateIDs+=$installedUpdate.Identity.UpdateID
            }
            $returnValue.Add('Id',$Id)
            $returnValue.Add('UpdateId',$installedUpdateIDs)
            $returnValue.Add('UpdateType',$UpdateType)
            $returnValue.Add('Reboot',$Reboot)
        }
        else
        {
            Write-Verbose -Message "No installed updates of type $UpdateType found."
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
        $UpdateId,
        [parameter(Mandatory = $false)]
        [ValidateSet("Software")]
        [System.String]
        $UpdateType='Software',
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Reboot=$false
    )
    try
    {
        $updateSession = new-object -com "Microsoft.Update.Session" -ErrorAction Stop
        $updateSearcher = $updateSession.CreateupdateSearcher()
        $updateDownloader = $updateSession.CreateUpdateDownloader()
        $updateInstaller = $updateSession.CreateUpdateInstaller()
        Write-Verbose -Message "Getting a list of all available updates"
        $availableUpdates=$updateSearcher.Search(("IsInstalled=0 and Type='$UpdateType'")).Updates
        if($availableUpdates.Count -ne 0)
        {
            $updateDownloader.Updates = $availableUpdates
            Write-Verbose -Message "Downloading all available updates."
            $downloadResult= $updateDownloader.Download()
            if (($downloadResult.Hresult -eq 0) –and (($downloadResult.resultCode –eq 2) -or ($downloadResult.resultCode –eq 3)) ) 
            {
                Write-Verbose -Message "Creating a list of updates to install"
                $updatesToInstall = New-object -com “Microsoft.Update.UpdateColl” -ErrorAction Stop
                $downloadedUpdates = $availableUpdates | Where-Object {$_.isdownloaded}
                if($downloadedUpdates.Count -ne 0)
                {
                    if($UpdateId -eq 'All')
                    {
                        Write-Verbose -Message "All available and downloaded updates are included in installable update list"
                        $downloadedUpdates | Foreach-Object {$updatesToInstall.Add($_) | out-null }
                    }
                    else
                    {
                        foreach ($downloadedUpdate in $downloadedUpdates)
                        {
                            if($downloadedUpdate.Identity.UpdateID -in $UpdateID)
                            {
                                $updatesToInstall.Add($downloadedUpdate) | out-null
                            }
                        }
                    }
                    if($updatesToInstall.Count -ne 0)
                    {
                        Write-Verbose -Message "Installing $($updatesToInstall | ForEach-Object{$_.Identity.UpdateId}) updates"
                        $updateInstaller.Updates = $updatesToInstall
                        $updateInstallationResult = $updateInstaller.Install()
                        if (($updateInstallationResult.Hresult -eq 0) –and (($updateInstallationResult.resultCode –eq 2) -or ($updateInstallationResult.resultCode –eq 3)) ) 
                        {
                            Write-Verbose -Message "Update installation succeded."
                            if($updateInstallationResult.RebootRequired)
                            {
                                if($Reboot)
                                {
                                    Write-Verbose -Message "Reboot required. Machine will be rebooted."
                                    $global:DSCMachineStatus = 1
                                }
                                else
                                {
                                    Write-Verbose -Message "Reboot required, but Reboot is set to $Reboot. Please reboot machine manually."
                                }
                            }
                        }
                        else
                        {
                            Write-Verbose -Message "Update installation failed. $updateInstallationResult"
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "No installable updates found from the list of available and downloaded updates."
                    }
                }
                else
                {
                    Write-Verbose -Message "No download updates found in available updates list."
                }
            }
            else
            {
                Write-Verbose -Message "Updates download failed."
            }
        }
        else
        {
            Write-Verbose -Message "No updates are available."
        }
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
        $UpdateId,
        [parameter(Mandatory = $false)]
        [ValidateSet("Software")]
        [System.String]
        $UpdateType='Software',
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Reboot=$false
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -Id $Id -UpdateId $UpdateId -UpdateType $UpdateType -Reboot $Reboot
        if ( $currentState.Count -ne 0 )
        {
            Write-Verbose -Message "Installed updates found."
            Write-Verbose -Message "Looking for an available updates"
            $updateSession = new-object -com "Microsoft.Update.Session"
            $availableUpdates=$updateSession.CreateupdateSearcher().Search(("IsInstalled=0 and Type='$UpdateType'")).Updates
            $installedUpdates=$updateSession.CreateupdateSearcher().Search(("IsInstalled=1 and Type='$UpdateType'")).Updates
            if($UpdateId -eq 'All')
            {
                if($availableUpdates.Count -ne 0)
                {
                    $availableUpdateIDs=@()
                    foreach($availableUpdate in $availableUpdates)
                    {
                        $availableUpdateIDs+=$availableUpdate.Identity.UpdateID
                        $availableUpdateIDs+=$availableUpdate.SupersededUpdateIDs
                    }
                    Write-Verbose -Message "Some available updates are not installed. UpdateIDs: $availableUpdateIDs"
                    $returnValue = $false
                }
                else
                {
                    Write-Verbose -Message "All available updates are installed."
                }
            }
            else
            {
                $installedsuperseededUpdateIDs=@()
                foreach($installedUpdate in $installedUpdates)
                {
                    $installedsuperseededUpdateIDs+=$installedUpdate.Identity.UpdateID
                    $installedsuperseededUpdateIDs+=$installedUpdate.SupersededUpdateIDs
                }
                $diff=Compare-Object -ReferenceObject $installedsuperseededUpdateIDs  -DifferenceObject $UpdateId
                if("=>" -in $diff.SideIndicator)
                {
                    Write-Verbose -Message "Updates with updateID: $UpdateID should be installed."
                    Write-Verbose -Message "Required updates are missing. UpdateIDs: $(($diff | Where-Object{$_.SideIndicator -eq "=>"}).InputObject -join ',')"
                    $returnValue=$false
                }
                else
                {
                    Write-Verbose -Message "All required updates are installed."
                }
            }
        }
        else
        {
            Write-Verbose -Message "No installed updates found."
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