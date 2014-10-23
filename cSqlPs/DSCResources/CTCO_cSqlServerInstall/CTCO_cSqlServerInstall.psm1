function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (   
        [parameter(Mandatory)] 
        [string] $InstanceName,

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $ConfigurationFile,

        [parameter()]
        [string] $SkipRules="",

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,
        
        [parameter()]
        [boolean]$RestartMachine=$false
    )

    $returnValue = @{}
    $service = Get-Service | ?{$_.DisplayName -eq "SQL Server ($InstanceName)"}
    if($service -ne $null)
    {
        $returnValue.Add("InstanceName","$InstanceName")
    }
    if(Get-Item (Join-Path $SourcePath -ChildPath "Setup.exe") -ErrorAction SilentlyContinue)
    {
        $returnValue.Add("SourcePath","$SourcePath")
    }
    if(Get-Item $Configurationfile -ErrorAction SilentlyContinue)
    {
        $returnValue.Add("Configurationfile","$Configurationfile")
    }

    $returnValue.Add("DomainAdministratorCredential","$DomainAdministratorCredential")
    $returnValue.Add("SkipRules","$SkipRules")
    $returnValue.Add("RestartMachine","$RestartMachine")
    return $returnValue
}

function Set-TargetResource
{
    param
    (   
        [parameter(Mandatory)] 
        [string] $InstanceName,

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $ConfigurationFile,

        [parameter()]
        [string] $SkipRules="",

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,
        
        [parameter()]
        [boolean]$RestartMachine=$false
    )

    $SchedledTask='<?xml version="1.0" encoding="UTF-16"?> <Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">   <RegistrationInfo>     <Date>2014-10-17T11:39:13.9515958</Date>     <Author>ECO2G\Administrator</Author>   </RegistrationInfo>   <Triggers />   <Principals>     <Principal id="Author">       <UserId>ECO2G\Administrator</UserId>       <LogonType>Password</LogonType>       <RunLevel>HighestAvailable</RunLevel>     </Principal>   </Principals>   <Settings>     <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>     <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>     <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>     <AllowHardTerminate>false</AllowHardTerminate>     <StartWhenAvailable>false</StartWhenAvailable>     <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>     <IdleSettings>       <StopOnIdleEnd>true</StopOnIdleEnd>       <RestartOnIdle>false</RestartOnIdle>     </IdleSettings>     <AllowStartOnDemand>true</AllowStartOnDemand>     <Enabled>true</Enabled>     <Hidden>false</Hidden>     <RunOnlyIfIdle>false</RunOnlyIfIdle>     <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>     <UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine>     <WakeToRun>false</WakeToRun>     <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>     <Priority>7</Priority>   </Settings>   <Actions Context="Author">     <Exec>       <Command>__SETUP_PATH__</Command>       <Arguments>__SETUP_ARGUMENTS__</Arguments>     </Exec>   </Actions> </Task>'
    $SetupPath = Join-Path $SourcePath -ChildPath "Setup.exe"
    $SetupArguments = " $SkipRules "
    $SetupArguments += " /CONFIGURATIONFILE=$Configurationfile "   
    $SchedledTask = $SchedledTask -replace "__USERID__","$($DomainAdministratorCredential.GetNetworkCredential().Username)"
    $SchedledTask = $SchedledTask -replace "__SETUP_PATH__","$SetupPath"
    $SchedledTask = $SchedledTask -replace "__SETUP_ARGUMENTS__","$SetupArguments"

    Write-Verbose -Message "SQL installation command: $SetupPath $SetupArguments"
    try
    {
        Write-Verbose -Message "Creating scheduled task to install SQL server ..."
        Write-Verbose -Message "$SchedledTask"
        Register-ScheduledTask -TaskName "install sql" -Xml "$SchedledTask" -User "$($DomainAdministratorCredential.GetNetworkCredential().Username)" -Password "$($DomainAdministratorCredential.GetNetworkCredential().Password)"
        Write-Verbose -Message "Scheduled task created."
        Write-Verbose -Message "Executing scheduled task to install SQL server ..."
        Get-ScheduledTask -TaskName "install sql" | Start-ScheduledTask
        Write-Verbose -Message "Waiting for the scheduled task  to be finished ..."
        Start-Sleep 10
        $ScheduledTaskState = (Get-ScheduledTask -TaskName "install sql").State
        While($ScheduledTaskState -eq "Running")
        {
            $ScheduledTaskState = (Get-ScheduledTask -TaskName "install sql").State
            Start-Sleep 10    
        }
        Write-Verbose -Message "Scheduled task finished."
    }
    catch
    {
        Write-Verbose -Message "SQL setup command execution failed. $($Error[0].Exception.Message)"
    }
    finally
    {
        $summary = Get-Content "C:\Program Files\Microsoft SQL Server\110\Setup Bootstrap\Log\Summary.txt"
        if(($summary -match ".*Final result:                  Passed.*") -and ($summary -match ".*Exit code \(Decimal\):           0.*"))
        {
            Write-Verbose "Looks like SQL installation process finished succesfuly."
            if($RestartMachine)
            {
                Write-Verbose "Restart requested."
                $global:DSCMachineStatus = 1
            }
        }
        Get-ScheduledTask -TaskName "install sql" | Unregister-ScheduledTask -ErrorAction SilentlyContinue
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (   
        [parameter(Mandatory)] 
        [string] $InstanceName,

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $ConfigurationFile,

        [parameter()]
        [string] $SkipRules="",

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,
        
        [parameter()]
        [boolean]$RestartMachine=$false
    )

    $retValue = $false
    $status = Get-TargetResource -InstanceName $InstanceName -SourcePath $SourcePath -Configurationfile  $Configurationfile -SkipRules $SkipRules -DomainAdministratorCredential $DomainAdministratorCredential 
    if($status["InstanceName"] -eq $InstanceName)
    {
        Write-Verbose -Message "Looks like we already have SQL instance with name $InstanceName installed on this machine. We'll skip installation."
        $retValue = $true
    }
    else
    {
        Write-Verbose -Message "SQL instance not found on local machine."
        if(($status["SourcePath"] -eq $SourcePath) -and ($status["Configurationfile"] -eq $Configurationfile))
        {
            Write-Verbose -Message "Setup and configuration file found."
        }
        else
        {
            Write-Verbose -Message "Can't find setup and/or configuration file. We'll skip installation."
            $retValue=$true
        }
    }
    return $retValue
}


Export-ModuleMember -Function *-TargetResource
