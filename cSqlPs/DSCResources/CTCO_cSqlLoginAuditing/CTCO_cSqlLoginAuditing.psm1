#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

$LoginAuditingRegValues=
@{
    0 = "None";
    1 = "Success";
    2 = "Failure";
    3 = "All";
}

function Restart-SqlServer()
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

function Restart-ClusteredSqlServer()
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
        $cluster = Get-Cluster
        $cluster | Stop-ClusterGroup -Name $ClusterGroupName
        $cluster | Start-ClusterGroup -Name $ClusterGroupName
	    Write-Verbose -Message "Clustered SQL instance restarted."
    }
    catch
    {
	    Write-Warning -Message "Error occured. $_"
    }
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $InstanceName,
	    
        [parameter(Mandatory)]
        [ValidateSet("None", "Success", "Failure", "All")]
        [String] $LoginAuditing="Failure", 

        [parameter()]
        [Boolean]$RestartService=$false,

        [parameter()]
        [String] $ClusterGroupName="",

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential
    )

    $retValue=@{}
    Write-Verbose -Message "Collecting SQL Server Login Auditing configuration ..."

    try 
    {
        if($ClusterGroupName -eq "")
        {
            Write-Verbose -Message "This is non-clustered instance"
            Write-Verbose -Message "Looking for SQL instance $InstanceName on localmachine"
            if($InstanceName -in (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' -ErrorAction SilentlyContinue).InstalledInstances)
            {
                Write-Verbose -Message "SQL instance $InstanceName found"
                $FullInstanceName=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -ErrorAction SilentlyContinue).$InstanceName
                $AuditLevel=(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($FullInstanceName)\MSSQLServer" -ErrorAction SilentlyContinue).AuditLevel
                Write-Verbose -Message "SQL instance $InstanceName have login audit level: $AuditLevel"
                $retValue.Add("InstanceName",$InstanceName)
                $retValue.Add("RestartService",$RestartService)
                $retValue.Add("ClusterGroupName",$ClusterGroupName)
                $retValue.Add("LoginAuditing",$LoginAuditingRegValues[$AuditLevel])
                $retValue.Add("SqlAdministratorCredential",$SqlAdministratorCredential)
            }
            else
            {
                Write-Verbose -Message "Can't find SQL instance $InstanceName"
            }
        }
        else
        {
            Write-Verbose -Message "This is clustered instance"
            Write-Verbose -Message "Getting cluster object"
            $Cluster = Get-Cluster -ErrorAction Stop
            $ClusterGroupOwner=($Cluster | Get-ClusterGroup -Name $ClusterGroupName -ErrorAction Stop).OwnerNode
            Write-Verbose -Message "Cluster group $ClusterGroupName owner is $($ClusterGroupOwner.Name)"
            $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', "$($ClusterGroupOwner.Name)")
            $RegKey= $Reg.OpenSubKey("SOFTWARE\\Microsoft\\Microsoft SQL Server")
            if($InstanceName -in $RegKey.GetValue("InstalledInstances"))
            {
                Write-Verbose -Message "SQL instance $InstanceName on $($ClusterGroupOwner.Name) machine found"
                $RegKey= $Reg.OpenSubKey("SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names\\SQL")
                $FullInstanceName=$RegKey.GetValue("$InstanceName")
                $RegKey= $Reg.OpenSubKey("SOFTWARE\\Microsoft\\Microsoft SQL Server\\$($FullInstanceName)\\MSSQLServer")
                $AuditLevel = $RegKey.GetValue("AuditLevel")
                Write-Verbose -Message "SQL instance $InstanceName login audit level: $AuditLevel"
                $retValue.Add("InstanceName",$InstanceName)
                $retValue.Add("RestartService",$RestartService)
                $retValue.Add("ClusterGroupName",$ClusterGroupName)
                $retValue.Add("LoginAuditing",$LoginAuditingRegValues[$AuditLevel])
                $retValue.Add("SqlAdministratorCredential",$SqlAdministratorCredential)
            }
            else
            {
                Write-Verbose -Message "Can't find SQL instance $InstanceName"
            }
        }
    }
    catch
    {
        Write-Warning -Message "Error occured. $_"
    }
    return $retValue
}

function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $InstanceName,
	    
        [parameter(Mandatory)]
        [ValidateSet("None", "Success", "Failure", "All")]
        [String] $LoginAuditing="Failure", 

        [parameter()]
        [Boolean]$RestartService=$false,

        [parameter()]
        [String] $ClusterGroupName="",

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential
    )

    Write-Verbose -Message "Setting SQL Server Login Audiging level to $LoginAuditing"
    $OSQLUsername=$SqlAdministratorCredential.UserName
    $OSQLPassword=$SqlAdministratorCredential.GetNetworkCredential().Password
    $DesiredLoginAuditingValue=$LoginAuditingRegValues.Keys | %{if($LoginAuditingRegValues[$_] -eq "$LoginAuditing"){$_}}
    if($ClusterGroupName -eq "")
    {
        Write-Verbose -Message "Non-clustered instance"
        if($InstanceName -eq "MSSQLSERVER")
        {
            $OSQLServer="$($Env:ComputerName)"
        }
        else
        {
            $OSQLServer="$($Env:ComputerName)\$InstanceName"
        }
    }
    else
    {
        Write-Verbose -Message "Clustered instance"
        try
        {        
            $Cluster=Get-Cluster -ErrorAction Stop
            $ClusterGroup = $Cluster | Get-ClusterGroup -Name $ClusterGroupName -ErrorAction Stop
            $ClusterGroupResources = $ClusterGroup | Get-ClusterResource -ErrorAction Stop
            $ClusterGroupResourceNetworkName =  ($ClusterGroupResources | Where-Object {$_.ResourceType -eq "Network Name"})[0]
            if($ClusterGroupResourceNetworkName -ne $null)
            {
                $SQLClusterNetworkName=($ClusterGroupResourceNetworkName | Get-ClusterParameter -ErrorAction Stop | Where-Object {$_.Name -eq "DnsName"}).Value
                if($InstanceName -eq "MSSQLSERVER")
                {
                    $OSQLServer="$SQLClusterNetworkName"
                }
                else
                {
                    $OSQLServer="$SQLClusterNetworkName\$InstanceName"
                }
                Write-Verbose -Message "Full SQL server name is $OSQLServer"
            }
            else
            {
                Write-Verbose -Message "Can't find Network Name in cluster group $ClusterGroupName."
            }
        }
        catch
        {
            Write-Warning -Message "Error occured. $_"
        }
    }
    Write-Verbose -message "Going to execute following SQL expression against  $($OSQLServer) server: EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, $DesiredLoginAuditingValue"
    $OSQLexecresult=osql -S $OSQLServer -U $OSQLUsername -P $OSQLPassword -Q "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, $DesiredLoginAuditingValue"
    if($OSQLexecresult -like "(0 rows affected)")
    {
        Write-Verbose -Message "osql expression executed seccessfully"
        if($RestartService)
        {
            Write-Verbose -Message "Going to restart SQL Instance"
            if($ClusterGroupName -eq "")
            {
                Restart-SqlServer -InstanceName $InstanceName
            }
            else
            {
                Restart-ClusteredSqlServer -ClusterGroupName $ClusterGroupName
            }
        }
    }
    else
    {
        Write-Verbose -Message "osql expression execution failed. $OSQLexecresult"
    }

}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $InstanceName,
	    
        [parameter(Mandatory)]
        [ValidateSet("None", "Success", "Failure", "All")]
        [String] $LoginAuditing="Failure", 

        [parameter()]
        [Boolean]$RestartService=$false,

        [parameter()]
        [String] $ClusterGroupName="",

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential
    )

    $retValue=$true
    try 
    {
        $CurrentState = Get-TargetResource -InstanceName $InstanceName -LoginAuditing $LoginAuditing -RestartService $RestartService -ClusterGroupName $ClusterGroupName -SqlAdministratorCredential $SqlAdministratorCredential
        if($CurrentState.Count -ne 0)
        {
            Write-Verbose -Message "Got current resource state"
            if($CurrentState["LoginAuditing"] -eq $LoginAuditing)
            {
                Write-Verbose -Message "SQL Server Login Auditing configuration setting is in desired state"
            }
            else
            {
                Write-Verbose -Message "SQL Server Login Auditing configuration setting is not in desired state"
                $retValue=$false
            }

        }
        else
        {
            Write-Verbose -Message "Can't get current resource state"
        }
    }
    catch
    {
        Write-Warning -Message "Error occured. $_"
    }    
    return $retValue
}

Export-ModuleMember -Function *-TargetResource
