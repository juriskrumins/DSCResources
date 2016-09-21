function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WUServer,
        [parameter(Mandatory = $true)]
        [System.String]
        $WUStatusServer,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $ElevateNonAdmins=$false,
        [parameter(Mandatory = $false)]
        [System.String]
        $TargetGroup='',
        [parameter(Mandatory = $false)]
        [System.Int32]
        $AUOptions=3,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $AutoInstallMinorUpdates=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $NoAutoUpdate=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $ScheduledInstallDay=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $ScheduledInstallTime=3,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $EnableFeaturedSoftware=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $DetectionFrequencyEnabled=1,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $DetectionFrequency=1,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $UseWUServer=1
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting Windows Update Agent Environment configuration ...."
        $WindowsUpdateWSUSEnv=Get-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -ErrorAction SilentlyContinue
        $WindowsUpdateAUEnv=Get-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -ErrorAction SilentlyContinue
        if($WindowsUpdateWSUSEnv -ne $null -and $WindowsUpdateWSUSEnv.GetValue('WUserver') -ne $null -and $WindowsUpdateAUEnv -ne $null)
        {
            Write-Verbose -Message "Windows Update Agent WSUS configuration found"
            $returnValue.Add('WUServer',$WindowsUpdateWSUSEnv.GetValue('WUserver'))
            $returnValue.Add('WUStatusServer',$WindowsUpdateWSUSEnv.GetValue('WUStatusServer'))
            $returnValue.Add('ElevateNonAdmins',$(if($WindowsUpdateWSUSEnv.GetValue('ElevateNonAdmins')){$true}else{$false}))
            $returnValue.Add('TargetGroup',$WindowsUpdateWSUSEnv.GetValue('TargetGroup'))
            $returnValue.Add('AUOptions',$WindowsUpdateAUEnv.GetValue('AUOptions'))
            $returnValue.Add('AutoInstallMinorUpdates',$WindowsUpdateAUEnv.GetValue('AutoInstallMinorUpdates'))
            $returnValue.Add('NoAutoUpdate',$WindowsUpdateAUEnv.GetValue('NoAutoUpdate'))
            $returnValue.Add('ScheduledInstallDay',$WindowsUpdateAUEnv.GetValue('ScheduledInstallDay'))
            $returnValue.Add('ScheduledInstallTime',$WindowsUpdateAUEnv.GetValue('ScheduledInstallTime'))
            $returnValue.Add('EnableFeaturedSoftware',$WindowsUpdateAUEnv.GetValue('EnableFeaturedSoftware'))
            $returnValue.Add('DetectionFrequencyEnabled',$WindowsUpdateAUEnv.GetValue('DetectionFrequencyEnabled'))
            $returnValue.Add('DetectionFrequency',$WindowsUpdateAUEnv.GetValue('DetectionFrequency'))
            $returnValue.Add('UseWUServer',$WindowsUpdateAUEnv.GetValue('UseWUServer'))
        }
        else
        {
            Write-Verbose -Message "Windows Update Agent WSUS configuration not found"
        }
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
        throw
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
        $WUServer,
        [parameter(Mandatory = $true)]
        [System.String]
        $WUStatusServer,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $ElevateNonAdmins=$false,
        [parameter(Mandatory = $false)]
        [System.String]
        $TargetGroup='',
        [parameter(Mandatory = $false)]
        [System.Int32]
        $AUOptions=3,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $AutoInstallMinorUpdates=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $NoAutoUpdate=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $ScheduledInstallDay=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $ScheduledInstallTime=3,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $EnableFeaturedSoftware=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $DetectionFrequencyEnabled=1,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $DetectionFrequency=1,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $UseWUServer=1
    )
    try
    {
        Write-Verbose -Message "Setting Windows Update Agent Environment Options Registry Keys"
        $RegistryItem='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
        $RegistryItem1='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        $WindowsUpdateWSUSEnv=Get-Item $RegistryItem -ErrorAction SilentlyContinue
        $WindowsUpdateAUEnv=Get-Item $RegistryItem1 -ErrorAction SilentlyContinue
        if($WindowsUpdateWSUSEnv -eq $null)
        {
            New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -Name 'WindowsUpdate' -ErrorAction Stop | Out-Null
        }
        if($WindowsUpdateAUEnv -eq $null)
        {
            New-Item -Path $RegistryItem -Name 'AU' -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -Path $RegistryItem -Name DoNotConnectToWindowsUpdateInternetLocations -Value 1 -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem -Name WUServer -Value "$WUServer" -PropertyType String -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem -Name WUStatusServer -Value "$WUStatusServer" -PropertyType String -Force -ErrorAction Stop | Out-Null
        if($ElevateNonAdmins)
        {
            New-ItemProperty -Path $RegistryItem -Name ElevateNonAdmins -Value 1 -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        }
        else
        {
            New-ItemProperty -Path $RegistryItem -Name ElevateNonAdmins -Value 0 -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        }
        if($TargetGroup -ne '')
        {
            New-ItemProperty -Path $RegistryItem -Name TargetGroup -Value "$TargetGroup" -PropertyType String -Force -ErrorAction Stop | Out-Null
            New-ItemProperty -Path $RegistryItem -Name TargetGroupEnabled -Value 1 -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        } 
        else
        {
            if((Get-ItemProperty -Path $RegistryItem -Name TargetGroup  -ErrorAction SilentlyContinue) -ne $null)
            {
                Remove-ItemProperty -Path $RegistryItem -Name TargetGroup -Force -ErrorAction Stop 
            }
            if((Get-ItemProperty -Path $RegistryItem -Name TargetGroupEnabled  -ErrorAction SilentlyContinue) -ne $null)
            {
                Remove-ItemProperty -Path $RegistryItem -Name TargetGroupEnabled -Force -ErrorAction Stop
            }
        }

        New-ItemProperty -Path $RegistryItem1 -Name AUOptions -Value $AUOptions -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem1 -Name AutoInstallMinorUpdates -Value $AutoInstallMinorUpdates -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem1 -Name NoAutoUpdate -Value $NoAutoUpdate -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem1 -Name ScheduledInstallDay -Value $ScheduledInstallDay -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem1 -Name ScheduledInstallTime -Value $ScheduledInstallTime -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem1 -Name EnableFeaturedSoftware -Value $EnableFeaturedSoftware -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem1 -Name DetectionFrequencyEnabled -Value $DetectionFrequencyEnabled -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem1 -Name DetectionFrequency -Value $DetectionFrequency -PropertyType Dword -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegistryItem1 -Name UseWUServer -Value $UseWUServer -PropertyType Dword -Force -ErrorAction Stop | Out-Null

        Write-Verbose -Message "Restarting Windows Update Agent service"
        Restart-Service -Name wuauserv -ErrorAction Stop
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
        throw
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
        $WUServer,
        [parameter(Mandatory = $true)]
        [System.String]
        $WUStatusServer,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $ElevateNonAdmins=$false,
        [parameter(Mandatory = $false)]
        [System.String]
        $TargetGroup='',
        [parameter(Mandatory = $false)]
        [System.Int32]
        $AUOptions=3,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $AutoInstallMinorUpdates=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $NoAutoUpdate=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $ScheduledInstallDay=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $ScheduledInstallTime=3,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $EnableFeaturedSoftware=0,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $DetectionFrequencyEnabled=1,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $DetectionFrequency=1,
        [parameter(Mandatory = $false)]
        [System.Int32]
        $UseWUServer=1
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -WUServer $WUServer -WUStatusServer $WUStatusServer -ElevateNonAdmins $ElevateNonAdmins -TargetGroup $TargetGroup
        if($currentState['TargetGroup'] -eq $null)
        {
            $currentState['TargetGroup']=''
        }
        if($currentState.Count -ne 0)
        {
            Write-Verbose -Message "Windows Update Agent Environment WSUS configuration found"
            if($currentState['WUServer'] -ne $WUServer)
            {
                Write-Verbose -Message "Windows Update Agent WSUS server configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['WUStatusServer'] -ne $WUStatusServer -and $WUStatusServer -ne $null)
            {
                Write-Verbose -Message "Windows Update Agent WSUS status server configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['ElevateNonAdmins'] -ne $ElevateNonAdmins)
            {
                Write-Verbose -Message "Windows Update Agent ElevateNonAdmins configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['TargetGroup'] -ne $TargetGroup)
            {
                Write-Verbose -Message "Windows Update Agent TargetGroup configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['AUOptions'] -ne $AUOptions)
            {
                Write-Verbose -Message "Windows Update Agent AUOptions configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['AutoInstallMinorUpdates'] -ne $AutoInstallMinorUpdates)
            {
                Write-Verbose -Message "Windows Update Agent AutoInstallMinorUpdates configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['NoAutoUpdate'] -ne $NoAutoUpdate)
            {
                Write-Verbose -Message "Windows Update Agent NoAutoUpdate configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['ScheduledInstallDay'] -ne $ScheduledInstallDay)
            {
                Write-Verbose -Message "Windows Update Agent ScheduledInstallDay configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['ScheduledInstallTime'] -ne $ScheduledInstallTime)
            {
                Write-Verbose -Message "Windows Update Agent ScheduledInstallTime configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['EnableFeaturedSoftware'] -ne $EnableFeaturedSoftware)
            {
                Write-Verbose -Message "Windows Update Agent EnableFeaturedSoftware configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['DetectionFrequencyEnabled'] -ne $DetectionFrequencyEnabled)
            {
                Write-Verbose -Message "Windows Update Agent DetectionFrequencyEnabled configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['DetectionFrequency'] -ne $DetectionFrequency)
            {
                Write-Verbose -Message "Windows Update Agent DetectionFrequency configuration is not in desired state."
                $returnValue = $false
            }
            if($currentState['UseWUServer'] -ne $UseWUServer)
            {
                Write-Verbose -Message "Windows Update Agent UseWUServer configuration is not in desired state."
                $returnValue = $false
            }
        }
        else
        {
            Write-Verbose -Message "Windows Update Agent Environment WSUS configuration not found"
            $returnValue = $false
        }
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
        throw
    }
    $returnValue
}

Export-ModuleMember -Function *-TargetResource