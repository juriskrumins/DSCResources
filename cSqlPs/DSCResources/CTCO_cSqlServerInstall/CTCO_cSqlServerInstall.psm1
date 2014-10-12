function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (   
        [parameter(Mandatory)] 
        [string] $InstanceName = "MSSQLSERVER",

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $Configurationfile,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
    )

    $list = Get-Service -Name MSSQL*
    $retInstanceName = $null

    if ($InstanceName -eq "MSSQLSERVER")
    {
        if ($list.Name -contains "MSSQLSERVER")
        {
            $retInstanceName = $InstanceName
        }
    }
    elseif ($list.Name -contains $("MSSQL$" + $InstanceName))
    {
        Write-Verbose -Message "SQL Instance $InstanceName is present"
        $retInstanceName = $InstanceName
    }

    $returnValue = @{
        InstanceName = $retInstanceName
        SourcePath = $SourcePath
        Configurationfile = $Configurationfile
        DomainAdministratorCredential = $DomainAdministratorCredential
    }

    return $returnValue
}

function Set-TargetResource
{
    param
    (   
        [parameter(Mandatory)] 
        [string] $InstanceName = "MSSQLSERVER",

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $Configurationfile,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
    )

    $LogFile = "C:\sqlserverinstall.log"
    $cmd = Join-Path $SourcePath -ChildPath "Setup.exe"
    $cmd += " /CONFIGURATIONFILE=$Configurationfile "   
    $cmd += " > $LogFile 2>&1 "

    ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
    try
    {
        $o=Invoke-Command -ComputerName localhost -ScriptBlock { Param([string]$expr)Invoke-Expression $expr} -Credential $DomainAdministratorCredential -ArgumentList $cmd
        Write-Verbose -Message "$o"
    }
    finally
    {
    }

    $installStatus = $false
    try
    {
        # SQL Server log folder
        $LogPath = Join-Path $env:ProgramFiles "Microsoft SQL Server\110\Setup Bootstrap\Log"        
        $sqlLog = Get-Content "$LogPath\summary.txt"
        if($sqlLog -ne $null)
        {
            $message = $sqlLog | fl
            if($message -ne $null)
            {
                # sample report when the install is succesful
                #    Overall summary:
                #    Final result:                  Passed
                #    Exit code (Decimal):           0
                $finalResult = $message[1] | Out-String     
                $exitCode = $message[2] | Out-String    

                if(($finalResult.Contains("Passed") -eq $True) -and ($exitCode.Contains("0") -eq $True))
                {                     
                    $installStatus = $true
                }                
             }
        }
    }
    catch
    {
        Write-Verbose "SQL Installation did not succeed."
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
    if($installStatus -eq $true)
    {
        $global:DSCMachineStatus = 1
    }
    else    
    {        
        # Throw an error message indicating failure to install SQL Server install 
        $errorId = "InValidSQLServerInstall";
        $exceptionStr = "SQL Server installation did not succeed. For more details please refer to the logs under $LogPath folder."
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult;
        $exception = New-Object System.InvalidOperationException $exceptionStr; 
        $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
        $PSCmdlet.ThrowTerminatingError($errorRecord);
     }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (   
        [parameter(Mandatory)] 
        [string] $InstanceName = "MSSQLSERVER",

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $Configurationfile,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential  
    )

    $info = Get-TargetResource -InstanceName $InstanceName -Configurationfile  $Configurationfile -DomainAdministratorCredential $DomainAdministratorCredential -SourcePath $SourcePath
    
    return ($info.InstanceName -eq $InstanceName)
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
