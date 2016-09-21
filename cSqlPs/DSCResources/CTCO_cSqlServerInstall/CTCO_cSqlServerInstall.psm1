function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (   
        [parameter(Mandatory)] 
        [string] $InstanceName,

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SetupPath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SetupArguments,

        [parameter(Mandatory=$false)] 
        [ValidateNotNullOrEmpty()]
        [string] $SetupLog="C:\sqlinstall.log",

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
    if(Get-Item -Path $SetupPath -ErrorAction SilentlyContinue)
    {
        $returnValue.Add("SetupPath","$SetupPath")
        $returnValue.Add("SetupArguments","$SetupArguments")
        $returnValue.Add("SetupLog","$SetupLog")
    }
    $returnValue.Add("DomainAdministratorCredential","$DomainAdministratorCredential")
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
        [string] $SetupPath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SetupArguments,

        [parameter(Mandatory=$false)] 
        [ValidateNotNullOrEmpty()]
        [string] $SetupLog="C:\sqlinstall.log",

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,
        
        [parameter()]
        [boolean]$RestartMachine=$false
    )

    $ScheduledTaskName="dscInstallSQLServer"
    $dscInstallSQLServerBatFilename="C:\dscInstallSQLServer.bat"
    $ScheduledTask='<?xml version="1.0" encoding="UTF-16"?> <Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">   <RegistrationInfo>     <Date>2014-10-17T11:39:13.9515958</Date>     <Author>__USERID__</Author>   </RegistrationInfo>   <Triggers />   <Principals>     <Principal id="Author">       <UserId>__USERID__</UserId>       <LogonType>Password</LogonType>       <RunLevel>HighestAvailable</RunLevel>     </Principal>   </Principals>   <Settings>     <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>     <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>     <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>     <AllowHardTerminate>false</AllowHardTerminate>     <StartWhenAvailable>false</StartWhenAvailable>     <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>     <IdleSettings>       <StopOnIdleEnd>true</StopOnIdleEnd>       <RestartOnIdle>false</RestartOnIdle>     </IdleSettings>     <AllowStartOnDemand>true</AllowStartOnDemand>     <Enabled>true</Enabled>     <Hidden>false</Hidden>     <RunOnlyIfIdle>false</RunOnlyIfIdle>     <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>     <UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine>     <WakeToRun>false</WakeToRun>     <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>     <Priority>7</Priority>   </Settings>   <Actions Context="Author">     <Exec>       <Command>__SETUP_PATH__</Command>       </Exec>   </Actions> </Task>'
    $ScheduledTask = $ScheduledTask -replace "__USERID__","$($DomainAdministratorCredential.Username)"
    $ScheduledTask = $ScheduledTask -replace "__SETUP_PATH__","$dscInstallSQLServerBatFilename"

    Write-Verbose -Message "SQL installation command: $SetupPath $SetupArguments"
    try
    {
        Write-Verbose -Message "Creating SQL installation bat file $dscInstallSQLServerBatFilename"
        $stream = [System.IO.StreamWriter] "$dscInstallSQLServerBatFilename"
        $stream.WriteLine("$SetupPath $SetupArguments  > $SetupLog")
        $stream.Close()
        Write-Verbose -Message "Creating scheduled task to install SQL server ..."
        Write-Verbose -Message "$ScheduledTask"
        Register-ScheduledTask -TaskName "$ScheduledTaskName" -Xml "$ScheduledTask" -User "$($DomainAdministratorCredential.Username)" -Password "$($DomainAdministratorCredential.GetNetworkCredential().Password)"
        Write-Verbose -Message "Scheduled task created."
        Write-Verbose -Message "Executing scheduled task to install SQL server ..."
        Get-ScheduledTask -TaskName "$ScheduledTaskName" | Start-ScheduledTask
        Write-Verbose -Message "Waiting for the scheduled task  to be finished ..."
        Start-Sleep 10
        $ScheduledTaskState = (Get-ScheduledTask -TaskName "$ScheduledTaskName").State
        While($ScheduledTaskState -eq "Running")
        {
            $ScheduledTaskState = (Get-ScheduledTask -TaskName "$ScheduledTaskName").State
            Start-Sleep 10    
        }
        Write-Verbose -Message "Scheduled task finished."
    }
    catch
    {
        Write-Verbose -Message "SQL setup command execution failed. $($_)"
    }
    finally
    {
        $summary = Get-Content "C:\Program Files\Microsoft SQL Server\110\Setup Bootstrap\Log\Summary.txt" -ErrorAction SilentlyContinue
        if(($summary -match ".*Final result:                  Passed.*") -and ($summary -match ".*Exit code \(Decimal\):           0.*"))
        {
            Write-Verbose "Looks like SQL installation process finished succesfuly."
            if($RestartMachine)
            {
                Write-Verbose "Restart requested."
                $global:DSCMachineStatus = 1
            }
        }
        Get-ScheduledTask -TaskName "$ScheduledTaskName" | Unregister-ScheduledTask -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\dscInstallSQLServer.bat" -ErrorAction SilentlyContinue
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
        [string] $SetupPath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SetupArguments,

        [parameter(Mandatory=$false)] 
        [ValidateNotNullOrEmpty()]
        [string] $SetupLog="C:\sqlinstall.log",

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,
        
        [parameter()]
        [boolean]$RestartMachine=$false
    )

    $retValue = $false
    $status = Get-TargetResource -InstanceName $InstanceName -SetupPath $SetupPath -SetupArguments $SetupArguments -SetupLog $SetupLog -DomainAdministratorCredential $DomainAdministratorCredential -RestartMachine $RestartMachine
    if($status["InstanceName"] -eq $InstanceName)
    {
        Write-Verbose -Message "Looks like we already have SQL instance with name $InstanceName installed on this machine. We'll skip installation."
        $retValue = $true
    }
    else
    {
        Write-Verbose -Message "SQL instance not found on local machine."
        if(($status["SetupPath"] -eq $SetupPath))
        {
            Write-Verbose -Message "Setup.exe found."
        }
        else
        {
            Write-Verbose -Message "Can't find setup.exe. We'll skip installation."
            $retValue=$true
        }
    }
    return $retValue
}


Export-ModuleMember -Function *-TargetResource
