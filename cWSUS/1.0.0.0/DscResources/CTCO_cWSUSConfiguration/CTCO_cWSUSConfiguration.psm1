function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $false)]
        [System.String]
        $ContentDir='C:\Program Files\Update Services\WsusContent',
        [parameter(Mandatory = $false)]
        [System.String]
        $ProxyServer='',
        [parameter(Mandatory = $false)]
        [ValidateSet("Client","Server")]
        [System.String]
        $TargetingMode='Server'
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting WSUS configuration ...."
        $WSUSServiceContentDir = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -Name ContentDir -ErrorAction SilentlyContinue
        if((Get-Website -Name "WSUS Administration" -ErrorAction Stop) -ne $null)
        {
            $WSUSServer = Get-WsusServer -ErrorAction Stop
        }
        else
        {
            $WSUSServer = $null
        }
        if($WSUSServiceContentDir.ContentDir -ne $null -and $WSUSServer -ne $null)
        {
            $returnValue.Add('Id',$Id)
            $returnValue.Add('ContentDir',$WSUSServiceContentDir.ContentDir)
            if($WSUSServer.GetConfiguration().UseProxy -eq $True)
            {
                $returnValue.Add('ProxyServer',"$($WSUSServer.GetConfiguration().ProxyName):$($WSUSServer.GetConfiguration().ProxyServerPort)")
            }
            else
            {
                $returnValue.Add('ProxyServer','')
            }
            $returnValue.Add('TargetingMode',$WSUSServer.GetConfiguration().TargetingMode)
        }
        else
        {
            Write-Verbose -Message "Can't find WSUS ContentDir option value or get connection to WSUS server."
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
        [parameter(Mandatory = $false)]
        [System.String]
        $ContentDir='C:\Program Files\Update Services\WsusContent',
        [parameter(Mandatory = $false)]
        [System.String]
        $ProxyServer='',
        [parameter(Mandatory = $false)]
        [ValidateSet("Client","Server")]
        [System.String]
        $TargetingMode='Server'
    )
    try
    {
        $doPostinstall=$false
        $doProxyServer=$false
        $doTargetingMode=$false
        $currentState = Get-TargetResource -Id $Id -ContentDir $ContentDir -ProxyServer $ProxyServer -TargetingMode $TargetingMode
        if($currentState.Count -eq 0)
        {
            Write-Verbose -Message "Looks like we need to do WSUS postinstall."
            $doPostinstall=$true
            $doProxyServer=$true
            $doTargetingMode=$true
        }
        else
        {
            if($currentState.ContentDir -ne $ContentDir)
            {
                Write-Verbose -Message "ContentDir property is not in desired state. Need to do postinstall."
                $doPostinstall=$true
            }
            if($currentState.ProxyServer -ne $ProxyServer)
            {
                Write-Verbose -Message "ProxyServer is not in desired state."
                $doProxyServer=$true
            }
            if($currentState.TargetingMode -ne $TargetingMode)
            {
                Write-Verbose -Message "TargetingMode is not in desired state."
                $doTargetingMode=$true
            }
        }
        if($doPostinstall)
        {
            Write-Verbose -Message "Executing postinstall"
            $PostInstallResult = & 'C:\Program Files\Update Services\Tools\WsusUtil.exe' postinstall content_dir=$ContentDir
            if ($PostInstallResult -contains 'Post install has successfully completed')
            {
                Write-Verbose -Message "Post install has successfully completed"
            }
            else
            {
                Write-Verbose -Message "Post install has not successfully completed"
            }
        }
        if($doProxyServer -or $doTargetingMode)
        {   
            Write-Verbose -Message "Configuring WSUS server"
            $WsusServer = Get-WsusServer -ErrorAction Stop
            $wuConfig = $WsusServer.GetConfiguration()
            if($doProxyServer -and $ProxyServer -ne '')
            {
                $wuConfig.ProxyName = ($ProxyServer -split ':')[0]
                $wuConfig.ProxyServerPort = ($ProxyServer -split ':')[1]
                $wuConfig.UseProxy = $true
            }
            else
            {
                $wuConfig.UseProxy = $false
            }
            if($doTargetingMode)
            {
                $wuConfig.TargetingMode=$TargetingMode
            }
            Write-Verbose -Message "Saving WSUS server configuration"
            $wuConfig.Save()
        }
        Write-Verbose -Message "Now everything should be in a desired state."
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
        [parameter(Mandatory = $false)]
        [System.String]
        $ContentDir='C:\Program Files\Update Services\WsusContent',
        [parameter(Mandatory = $false)]
        [System.String]
        $ProxyServer='',
        [parameter(Mandatory = $false)]
        [ValidateSet("Client","Server")]
        [System.String]
        $TargetingMode='Server'
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -Id $Id -ContentDir $ContentDir -ProxyServer $ProxyServer -TargetingMode $TargetingMode
        if ( $currentState.Count -ne 0 )
        {
            Write-Verbose -Message "Got WSUS configuration."
            Write-Verbose -Message "Check if it's in desired state."
            if($currentState.ContentDir -ne $ContentDir)
            {
                Write-Verbose -Message "ContentDir property is not in desired state"
                $returnValue = $false
            }
            if($currentState.ProxyServer -ne $ProxyServer)
            {
                Write-Verbose -Message "ProxyServer property is not in desired state"
                $returnValue = $false
            }
            if($currentState.TargetingMode -ne $TargetingMode)
            {
                Write-Verbose -Message "TargetingMode property is not in desired state"
                $returnValue = $false
            }
            $WSUSSetup = Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -ErrorAction SilentlyContinue
            if ( $WSUSSetup.GetValue('WsusAdministratorsSid') -ne $null -and 
                 $WSUSSetup.GetValue('WsusReportersSid') -ne $null -and
                 $WSUSSetup.GetValue('IISTargetWebSiteIndex') -ne $null -and
                 $WSUSSetup.GetValue('IISTargetWebSiteCreated') -ne $null -and
                 $WSUSSetup.GetValue('EncryptionParam').ToString() -ne $null -and
                 $WSUSSetup.GetValue('EncryptionKey').ToString() -ne $null
                )
            {
                Write-Verbose -Message "WSUS postinstall configuration has been done already."
            }
            else
            {
                Write-Verbose -Message "Looks like WSUS postinstall configuration has not been done yet."
                Write-Verbose -Message "WSUS postinstall configuration is not in desired state."
                $returnValue = $false
            }
        }
        else
        {
            Write-Verbose -Message "Can't get current WSUS configuration."
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