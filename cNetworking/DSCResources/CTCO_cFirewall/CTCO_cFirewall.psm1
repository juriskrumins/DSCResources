#region Get-TargetResource 
# DSC uses the Get-TargetResource cmdlet to fetch the status of the resource instance specified in the parameters for the target machine
function Get-TargetResource 
{ 
    [OutputType([Hashtable])]   
    param 
    (        
        [Parameter(Mandatory)]
        [ValidateSet("Public", "Private", "Domain")]
        [String]$Profile,
                      
        [Parameter(Mandatory)]
        [ValidateSet("True", "False")]
        [String]$Enabled,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential      
    )
    
    try
    {
        # Hash table for Get
        $getTargetResourceResult = @{}
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $NetFirewallProfile = Get-NetFirewallProfile -Profile $Profile -ErrorAction SilentlyContinue -ErrorVariable e
        if($NetFirewallProfile -ne $null) 
        { 
            $getTargetResourceResult.Profile = $NetFirewallProfile.Name
            if ($NetFirewallProfile.Enabled -eq "True")
            {
                $getTargetResourceResult.Enabled = "True"
            }
            if ($NetFirewallProfile.Enabled -eq "False")
            {
                   $getTargetResourceResult.Enabled = "False"
            }
        }
        else
        {
            Write-Verbose "Can't find Firewall profile `"$Profile`""
        }
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
    return $getTargetResourceResult;
}
#endregion #region Get-TargetResource 

#region Set-TargetResource
# DSC uses Set-TargetResource cmdlet to create, delete or configure the resource instance on the target machine
function Set-TargetResource 
{   
    param 
    (        
        [Parameter(Mandatory)]
        [ValidateSet("Public", "Private", "Domain")]
        [String]$Profile,
                      
        [Parameter(Mandatory)]
        [ValidateSet("True", "False")]
        [String]$Enabled,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential      
    )

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Configure Firewall profile `"$Profile`" state ..."
        $NetFirewallProfile = Get-NetFirewallProfile -Profile $Profile -ErrorAction SilentlyContinue -ErrorVariable e 
        if($NetFirewallProfile -ne $null) {
            $NetFirewallProfile | Set-NetFirewallProfile -Enabled $Enabled
            Write-Verbose "Firewall profile`s `"$Profile`" Enabled property set to $Enabled"
        }
        else
        {
            Write-Verbose "Can't find Firewall profile `"$Profile`""
        }
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
#endregion Set-TargetResource

#region Test-TargetREsource
# DSC uses Test-TargetResource cmdlet to check the status of the resource instance on the target machine
function Test-TargetResource 
{
    [OutputType([Boolean])] 
    param 
    (        
        [Parameter(Mandatory)]
        [ValidateSet("Public", "Private", "Domain")]
        [String]$Profile,
                      
        [Parameter(Mandatory)]
        [ValidateSet("True", "False")]
        [String]$Enabled,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential      
    )

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Check state of Firewall profile `"$Profile`" ..."
        $NetFirewallProfile = Get-NetFirewallProfile -Profile $Profile -ErrorAction SilentlyContinue -ErrorVariable e
        if($NetFirewallProfile -ne $null) 
        {
            Write-Verbose "Firewall profile `"$Profile`" found ..."
            if ($NetFirewallProfile.Enabled -eq $Enabled)
            {
                Write-Verbose "Firewall profile `"$Profile`" state is correct: Enabled=$Enabled"
                $returnValue=$true
            }
            else
            {
                Write-Verbose "Firewall profile `"$Profile`" state is incorrect: Enabled=$($NetFirewallProfile.Enabled)"
                $returnValue=$false
            }
        }
        else 
        {
            Write-Verbose "Can't find Firewall profile `"$Profile`"..."
            $returnValue=$false
        }
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
    return $returnValue
}
#endregion Test-TargetREsource

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