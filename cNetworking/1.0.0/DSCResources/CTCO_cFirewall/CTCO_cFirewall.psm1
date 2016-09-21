#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

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