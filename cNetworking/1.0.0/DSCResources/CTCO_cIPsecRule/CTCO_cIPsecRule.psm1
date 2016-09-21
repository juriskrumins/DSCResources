#region Get-TargetResource 
# DSC uses the Get-TargetResource cmdlet to fetch the status of the resource instance specified in the parameters for the target machine
function Get-TargetResource 
{
    [CmdletBinding()] 
    [OutputType([Hashtable])]   
    param 
    (
        [Parameter(Mandatory=$true)]
        [System.String]$DisplayName,

        [Parameter()]
        [System.String]$Description='',

        [Parameter()]
        [ValidateSet("True", "False")]
        [System.String]$Enabled='False',

        [Parameter()]
        [ValidateSet("None","Request","Require")]
        [System.String]$InboundSecurity='None',

        [Parameter()]
        [ValidateSet("None","Request","Require")]
        [System.String]$OutboundSecurity='None',

        [Parameter()]
        [ValidateSet("None","Transport","Tunnel")]
        [System.String]$Mode='Transport',

        [Parameter()]
        [System.String]$Protocol='Any',

        [Parameter()]
        [System.String]$LocalAddress='Any',

        [Parameter()]
        [System.String]$LocalPort='Any',

        [Parameter()]
        [System.String]$RemoteAddress='Any',

        [Parameter()]
        [System.String]$RemotePort='Any',

        [Parameter()]
        [ValidateSet("Any","Domain","Private","Public","NotApplicable")]
        [System.String]$Profile='Any',

        [Parameter()]
        [System.String]$Phase1AuthSetDisplayName
    )
    

    $returnValue = @{}
    try
    {
        $NetIPSecRule=Get-NetIPsecRule -DisplayName $DisplayName -ErrorAction Stop
        if($NetIPSecRule)
        {
            $returnValue.Add('DisplayName',$($NetIPSecRule.DisplayName))
            $returnValue.Add('Description',$($NetIPSecRule.Description))
            $returnValue.Add('Enabled',$($NetIPSecRule.Enabled))
            $returnValue.Add('InboundSecurity',$($NetIPSecRule.InboundSecurity))
            $returnValue.Add('OutboundSecurity',$($NetIPSecRule.OutboundSecurity))
            $returnValue.Add('Mode',$($NetIPSecRule.Mode))
            $returnValue.Add('Protocol',$(($NetIPSecRule | Get-NetFirewallPortFilter -ErrorAction Stop).Protocol))
            $returnValue.Add('LocalAddress',$(($NetIPSecRule | Get-NetFirewallAddressFilter -ErrorAction Stop).LocalAddress))
            $returnValue.Add('LocalPort',$(($NetIPSecRule | Get-NetFirewallPortFilter -ErrorAction Stop).LocalPort))
            $returnValue.Add('RemoteAddress',$(($NetIPSecRule | Get-NetFirewallAddressFilter -ErrorAction Stop).RemoteAddress))
            $returnValue.Add('RemotePort',$(($NetIPSecRule | Get-NetFirewallPortFilter -ErrorAction Stop).RemotePort))
            $returnValue.Add('Profile',$($NetIPSecRule.Profile))
            $returnValue.Add('Phase1AuthSetDisplayName',$((Get-NetIPsecPhase1AuthSet -Name $NetIPSecRule.Phase1AuthSet).DisplayName))
        }
    }
    catch
    {
        Write-Verbose -Message  "Error occured. $($_)"
    }
    return $returnValue
}
#endregion #region Get-TargetResource 

#region Set-TargetResource
# DSC uses Set-TargetResource cmdlet to create, delete or configure the resource instance on the target machine
function Set-TargetResource 
{   
    [CmdletBinding()] 
    param 
    (
        [Parameter(Mandatory=$true)]
        [System.String]$DisplayName,

        [Parameter()]
        [System.String]$Description='',

        [Parameter()]
        [ValidateSet("True", "False")]
        [System.String]$Enabled='False',

        [Parameter()]
        [ValidateSet("None","Request","Require")]
        [System.String]$InboundSecurity='None',

        [Parameter()]
        [ValidateSet("None","Request","Require")]
        [System.String]$OutboundSecurity='None',

        [Parameter()]
        [ValidateSet("None","Transport","Tunnel")]
        [System.String]$Mode='Transport',

        [Parameter()]
        [System.String]$Protocol='Any',

        [Parameter()]
        [System.String]$LocalAddress='Any',

        [Parameter()]
        [System.String]$LocalPort='Any',

        [Parameter()]
        [System.String]$RemoteAddress='Any',

        [Parameter()]
        [System.String]$RemotePort='Any',

        [Parameter()]
        [ValidateSet("Any","Domain","Private","Public","NotApplicable")]
        [System.String]$Profile='Any',

        [Parameter()]
        [System.String]$Phase1AuthSetDisplayName
    )

    $BoundParameters=@{}
    try
    {
        $BoundParameters=$MyInvocation.BoundParameters
        if('Description' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Description',$Description)
        }
        if('Enabled' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Enabled',$Enabled)
        }
        if('InboundSecurity' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('InboundSecurity',$InboundSecurity)
        }
        if('OutboundSecurity' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('OutboundSecurity',$OutboundSecurity)
        }
        if('Mode' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Mode',$Mode)
        }
        if('Protocol' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Protocol',$Protocol)
        }
        if('LocalAddress' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('LocalAddress',$LocalAddress)
        }
        if('LocalPort' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('LocalPort',$LocalPort)
        }
        if('RemoteAddress' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('RemoteAddress',$RemoteAddress)
        }
        if('RemotePort' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('RemotePort',$RemotePort)
        }
        if('Profile' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Profile',$Profile)
        }
        if('Phase1AuthSetDisplayName' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Phase1AuthSetDisplayName',$Phase1AuthSetDisplayName)
        }
        $BoundParameters.Add('ErrorAction','Stop')
        $ResourceState=Get-TargetResource @BoundParameters
        if($ResourceState.Count -ne 0)
        {
            Write-Verbose -Message "NetIPSec $DisplayName rule have been found. Going to adjust it's properties."
            $Phase1AuthSetName =  (Get-NetIPsecPhase1AuthSet -DisplayName $BoundParameters['Phase1AuthSetDisplayName'] -ErrorAction Stop).Name
            $BoundParameters.Remove('Phase1AuthSetDisplayName')
            $BoundParameters.Add('Phase1AuthSet',$Phase1AuthSetName)
            Set-NetIPsecRule @BoundParameters
        }
        else
        {
            Write-Verbose -Message "No NetIPSec rule have been found. I'm going to create IPSecRule $($DisplayName)."
            if($BoundParameters['Phase1AuthSetDisplayName'] -ne '')
            {               
                $Phase1AuthSetName =  (Get-NetIPsecPhase1AuthSet -DisplayName $BoundParameters['Phase1AuthSetDisplayName'] -ErrorAction Stop).Name
                $BoundParameters.Remove('Phase1AuthSetDisplayName')
                $BoundParameters.Add('Phase1AuthSet',$Phase1AuthSetName)
            }
            else
            {
                $BoundParameters.Remove('Phase1AuthSetDisplayName')
            }
            New-NetIPsecRule @BoundParameters
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)"
    }
}
#endregion Set-TargetResource

#region Test-TargetREsource
# DSC uses Test-TargetResource cmdlet to check the status of the resource instance on the target machine
function Test-TargetResource 
{
    [CmdletBinding()] 
    [OutputType([System.Boolean])] 
    param 
    (
        [Parameter(Mandatory=$true)]
        [System.String]$DisplayName,

        [Parameter()]
        [System.String]$Description='',

        [Parameter()]
        [ValidateSet("True", "False")]
        [System.String]$Enabled='False',

        [Parameter()]
        [ValidateSet("None","Request","Require")]
        [System.String]$InboundSecurity='None',

        [Parameter()]
        [ValidateSet("None","Request","Require")]
        [System.String]$OutboundSecurity='None',

        [Parameter()]
        [ValidateSet("None","Transport","Tunnel")]
        [System.String]$Mode='Transport',

        [Parameter()]
        [System.String]$Protocol='Any',

        [Parameter()]
        [System.String]$LocalAddress='Any',

        [Parameter()]
        [System.String]$LocalPort='Any',

        [Parameter()]
        [System.String]$RemoteAddress='Any',

        [Parameter()]
        [System.String]$RemotePort='Any',

        [Parameter()]
        [ValidateSet("Any","Domain","Private","Public","NotApplicable")]
        [System.String]$Profile='Any',

        [Parameter()]
        [System.String]$Phase1AuthSetDisplayName
    )

    $returnValue=$True
    $BoundParameters=@{}
    try
    {
        $BoundParameters=$MyInvocation.BoundParameters
        if('Description' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Description',$Description)
        }
        if('Enabled' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Enabled',$Enabled)
        }
        if('InboundSecurity' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('InboundSecurity',$InboundSecurity)
        }
        if('OutboundSecurity' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('OutboundSecurity',$OutboundSecurity)
        }
        if('Mode' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Mode',$Mode)
        }
        if('Protocol' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Protocol',$Protocol)
        }
        if('LocalAddress' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('LocalAddress',$LocalAddress)
        }
        if('LocalPort' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('LocalPort',$LocalPort)
        }
        if('RemoteAddress' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('RemoteAddress',$RemoteAddress)
        }
        if('RemotePort' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('RemotePort',$RemotePort)
        }
        if('Profile' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Profile',$Profile)
        }
        if('Phase1AuthSetDisplayName' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Phase1AuthSetDisplayName',$Phase1AuthSetDisplayName)
        }
        $ResourceState=Get-TargetResource @BoundParameters
        if($ResourceState.Count -ne 0)
        {
            Foreach($Parameter in $ResourceState.Keys)
            {
                if($ResourceState[$Parameter] -ne $BoundParameters[$Parameter])
                {
                    Write-Verbose -Message "Parameter $Parameter is not in it's desired state. $Parameter = $($ResourceState[$Parameter]), but should be $($BoundParameters[$Parameter])"
                    $returnValue=$False
                    Break
                }
            }
        }
        else
        {
            Write-Verbose -Message "Can't get current resource state. Probably it doesn't exists."
            $returnValue=$False
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)"
    }
    return $returnValue
}
#endregion Test-TargetREsource

Export-ModuleMember -Function *-TargetResource