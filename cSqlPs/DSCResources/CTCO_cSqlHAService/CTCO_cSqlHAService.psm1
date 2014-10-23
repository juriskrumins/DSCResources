function RestartSqlServer()
{
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $InstanceName
    )
    $list = Get-Service | ?{$_.DisplayName -eq "SQL Server ($InstanceName)"}
    
    Write-Verbose -Message "Restarting SQL instance ..."
    foreach ($s in $list)
    {
        Set-Service -Name $s.Name -StartupType Automatic
        if ($s.Status -ne "Stopped")
        {
            $s.Stop()
            $s.WaitForStatus("Stopped")
            $s.Refresh()
        }
        if ($s.Status -ne "Running")
        {
            $s.Start()
            $s.WaitForStatus("Running")
            $s.Refresh()
        }
    }
    Write-Verbose -Message "SQL instance restarted."
}

function RestartClusteredSqlServer()
{
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ClusterGroupName
    )
    try 
    {
	    $ErrorActionPreference = "Stop"
        Write-Verbose -Message "Restarting clustered SQL instance ..."
	    ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $cluster = Get-Cluster
        $cluster | Stop-ClusterGroup -Name $ClusterGroupName
        $cluster | Start-ClusterGroup -Name $ClusterGroupName
	    Write-Verbose -Message "Clustered SQL instance restared."
    }
    catch
    {
	    Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
    }
    finally
    {
	    if ($context)
	    {
		    $context.Undo()
		    $context.Dispose()
		    CloseUserToken($newToken)
	    }
    }
}

function IsSQLLogin($SqlInstance, $SAPassword, $Login )
{
	$query = OSQL -S $SqlInstance -U sa -P $SAPassword -Q "select count(name) from master.sys.server_principals where name = '$Login'" -h-1
        return ($query[0].Trim() -eq "1")
}

function IsSrvRoleMember($SqlInstance, $SAPassword, $Login )
{
	$query = OSQL -S $SqlInstance -U sa -P $SAPassword -Q "select IS_srvRoleMember('sysadmin', '$Login')" -h-1
        return ($query[0].Trim() -eq "1")
}

function IsHAEnabled($SqlInstance, $SAPassword)
{
	$query = OSQL -S $SqlInstance -U sa -P $SAPassword -Q "select ServerProperty('IsHadrEnabled')" -h-1
	return ($query[0].Trim() -eq "1")
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $InstanceName,
	    
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential, 
	    
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceCredential,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$DomainAdministratorCredential,

        [parameter()]
        [boolean]$RestartService=$false,

        [parameter()]
        [boolean]$RestartMachine=$false,

        [parameter()]
        [string] $ClusterGroupName=""
    )

    $retValue=@{}
    Write-Verbose -Message "Get SQL Service configuration ..."

    $SAPassword = $SqlAdministratorCredential.GetNetworkCredential().Password

    $ServiceAccount = $ServiceCredential.UserName

    
    $bServiceAccountInSqlLogin = IsSQLLogin -SqlInstance $InstanceName -SAPassword $SAPassword -Login $ServiceAccount

    $bServiceAccountInSrvRole = IsSrvRoleMember -SqlInstance $InstanceName -SAPassword $SAPassword -Login $ServiceCredential.UserName

    $bSystemAccountInSrvRole = IsSrvRoleMember -SqlInstance $InstanceName -SAPassword $SAPassword -Login "NT AUTHORITY\SYSTEM"

    $bHAEnabled = IsHAEnabled -SqlInstance $InstanceName -SAPassword $SAPassword

	$retValue=@{
        ServiceAccount = $ServiceAccount
        ServiceAccountInSqlLogin = $bServiceAccountInSqlLogin
        ServiceAccountInSrvRole = $bServiceAccountInSrvRole
        SystemAccountInSrvRole = $bSystemAccountInSrvRole
        HAEnabled = $bHAEnabled
        RestartService = $RestartService
        RestartMachine = $RestartMachine
    }

    if($ClusterGroupName -ne "")
    {
        try {
            $ErrorActionPreference = "Stop"
            ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
            $cluster = Get-Cluster
            $clustergroup = $cluster | Get-ClusterGroup -Name $ClusterGroupName
            $retValue.Add("ClusterGroupName","$ClusterGroupName")
            $retValue.Add("DomainAdministratorCredential","$DomainAdministratorCredential")
        }
        catch
        {
            Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
        }
        finally
        {
            if ($context)
            {
                $context.Undo()
                $context.Dispose()
                CloseUserToken($newToken)
            }
        }
    }

    return $retValue
}

function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $InstanceName,
	    
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential, 
	    
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceCredential,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$DomainAdministratorCredential,

        [parameter()]
        [boolean]$RestartService=$false,

        [parameter()]
        [boolean]$RestartMachine=$false,

        [parameter()]
        [string]$ClusterGroupName=""
    )

    Write-Verbose -Message "Set SQL Service configuration ..."

    $SAPassword = $SqlAdministratorCredential.GetNetworkCredential().Password

    $ServiceAccount = $ServiceCredential.UserName
    $ServicePassword = $ServiceCredential.GetNetworkCredential().Password

    $bCheck = IsSQLLogin -SqlInstance $InstanceName -SAPassword $SAPassword -Login $ServiceAccount
    if ($false -eq $bCheck)
    {
        osql -S $InstanceName -U sa -P $SAPassword -Q "Create Login [$ServiceAccount] From Windows"
    }

    $bCheck = IsSrvRoleMember -SqlInstance $InstanceName -SAPassword $SAPassword -Login $ServiceAccount
    if ($false -eq $bCheck)
    {
    	osql -S $InstanceName -U sa -P $SAPassword -Q "Exec master.sys.sp_addsrvrolemember '$ServiceAccount', 'sysadmin'"
    }

    $bCheck = IsSrvRoleMember -SqlInstance $InstanceName -SAPassword $SAPassword -Login "NT AUTHORITY\SYSTEM"
    if ($false -eq $bCheck)
    {
	    osql -S $InstanceName -U sa -P $SAPassword -Q "Exec master.sys.sp_addsrvrolemember 'NT AUTHORITY\SYSTEM', 'sysadmin'"
    }

    $serviceName = Get-SqlServiceName -InstanceName $InstanceName
    $service = Get-WmiObject Win32_Service | ? { $_.Name -eq $serviceName }
    $service.Change($null,$null,$null,$null,$null,$null,$ServiceAccount,$ServicePassword,$null,$null,$null)
 
    if($RestartService)
    {
        if($ClusterGroupName -eq "")
        {
            RestartSqlServer -InstanceName $InstanceName
        }
        else
        {
            try 
            {
                $ErrorActionPreference = "Stop"
                ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
                RestartClusteredSqlServer -ClusterGroupName $ClusterGroupName
            }
            catch
            {
                Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
            }
            finally
            {
                if ($context)
                {
                    $context.Undo()
                    $context.Dispose()
                    CloseUserToken($newToken)
                }
            }
        }
    }

    $bCheck = IsHAEnabled -SqlInstance $InstanceName -SAPassword $SAPassword
    if ($false -eq $bCheck)
    {
        Enable-SqlAlwaysOn -ServerInstance $InstanceName -Force
        if($RestartService)
        {
            if($ClusterGroupName -eq "")
            {
                RestartSqlServer -InstanceName $InstanceName
            }
            else
            {
                try 
                {
                    $ErrorActionPreference = "Stop"
                    ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
                    RestartClusteredSqlServer -ClusterGroupName $ClusterGroupName
                }
                catch
                {
                    Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
                }
                finally
                {
                    if ($context)
                    {
                        $context.Undo()
                        $context.Dispose()
                        CloseUserToken($newToken)
                    }
                }
            }
        }
    }

    if($RestartMachine)
    {
        $global:DSCMachineStatus = 1
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $InstanceName,
	    
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential, 
	    
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceCredential,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$DomainAdministratorCredential,

        [parameter()]
        [boolean]$RestartService=$false,

        [parameter()]
        [boolean]$RestartMachine=$false,

        [parameter()]
        [string] $ClusterGroupName=""
    )

    Write-Verbose -Message "Test SQL Service configuration ..."

    $SAPassword = $SqlAdministratorCredential.GetNetworkCredential().Password
    $ServiceAccount = $ServiceCredential.UserName

    $ret = IsSQLLogin -SqlInstance $InstanceName -SAPassword $SAPassword -Login $ServiceAccount
    if ($false -eq $ret)
    {
        Write-Verbose -Message "$ServiceAccount is NOT in SqlServer login"
        return $false
    }

    $ret = IsSrvRoleMember -SqlInstance $InstanceName -SAPassword $SAPassword -Login $ServiceCredential.UserName
    if ($false -eq $ret)
    {
        Write-Verbose -Message "$ServiceCredential.UserName is NOT in admin role"
        return $false
    }

    $ret = IsSrvRoleMember -SqlInstance $InstanceName -SAPassword $SAPassword -Login "NT AUTHORITY\SYSTEM"
    if ($false -eq $ret)
    {
        Write-Verbose -Message "NT AUTHORITY\SYSTEM is NOT in admin role"
        return $false
    }

    $ret = IsHAEnabled -SqlInstance $InstanceName -SAPassword $SAPassword
    if ($false -eq $ret)
    {
        Write-Verbose -Message "$InstanceName does NOT enable SQL HA."
        return $false
    }

    return $ret
}

function Get-SqlServiceName ($InstanceName)
{
    $list = $InstanceName.Split("\")
    if ($list.Count -gt 1)
    {
        "MSSQL$" + $list[1]
    }
    else
    {
        "MSSQLSERVER"
    }
}

#region Additional functions
function Get-ImpersonatetLib
{
    if ($script:ImpersonateLib)
    {
        return $script:ImpersonateLib
    }

    $sig = @'
[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

[DllImport("kernel32.dll")]
public static extern Boolean CloseHandle(IntPtr hObject);
'@ 
   $script:ImpersonateLib = Add-Type -PassThru -Namespace 'Lib.Impersonation' -Name ImpersonationLib -MemberDefinition $sig 

   return $script:ImpersonateLib
    
}

function ImpersonateAs([PSCredential] $cred)
{
    [IntPtr] $userToken = [Security.Principal.WindowsIdentity]::GetCurrent().Token
    $userToken
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::LogonUser($cred.GetNetworkCredential().UserName, $cred.GetNetworkCredential().Domain, $cred.GetNetworkCredential().Password, 
    9, 0, [ref]$userToken)
    
    if ($bLogin)
    {
        $Identity = New-Object Security.Principal.WindowsIdentity $userToken
        $context = $Identity.Impersonate()
    }
    else
    {
        throw "Can't Logon as User $cred.GetNetworkCredential().UserName."
    }
    $context, $userToken
}

function CloseUserToken([IntPtr] $token)
{
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::CloseHandle($token)
    if (!$bLogin)
    {
        throw "Can't close token"
    }
}
#endregion Additional functions

Export-ModuleMember -Function *-TargetResource
