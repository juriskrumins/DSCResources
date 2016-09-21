#region Get-TargetResource 
# DSC uses the Get-TargetResource cmdlet to fetch the status of the resource instance specified in the parameters for the target machine
function Get-TargetResource 
{
    [CmdletBinding()] 
    [OutputType([Hashtable])]   
    param 
    (
        [Parameter(Mandatory)]
        [System.String]$DisplayName,

        [Parameter(Mandatory)]
        [System.String]$Authority,

        [Parameter()]
        [ValidateSet("Root", "Intermediate")]
        [System.String]$AuthorityType='Root',

        [Parameter()]
        [System.String]$Description='',

        [Parameter()]
        [System.Boolean]$Machine=$true,

        [Parameter()]
        [System.Boolean]$Health=$false     
    )
    
    $returnValue = @{}
    try
    {
       $IPsecPhase1AuthSet=Get-NetIPsecPhase1AuthSet -DisplayName $DisplayName -ErrorAction Stop
       if($IPsecPhase1AuthSet)
       {
            $returnValue.Add('DisplayName',$DisplayName)
            $returnValue.Add('Authority',$IPsecPhase1AuthSet.Proposal[0].Authority)
            $returnValue.Add('AuthorityType',$IPsecPhase1AuthSet.Proposal[0].AuthorityType)
            $returnValue.Add('Description',$IPsecPhase1AuthSet.Description)
            if($IPsecPhase1AuthSet.Proposal[0].AuthenticationMethod -eq 'MachineCert' -or $IPsecPhase1AuthSet.Proposal[0].AuthenticationMethod -eq 'MachineHealthCert' )
            {
                $returnValue.Add('Machine',$True)
            }
            else
            {
                $returnValue.Add('Machine',$False)
            }
            if($IPsecPhase1AuthSet.Proposal[0].AuthenticationMethod -eq 'MachineHealthCert' )
            {
                $returnValue.Add('Health',$True)
            }
            else
            {
                $returnValue.Add('Health',$False)
            }
       }
       else
       {
            Write-Verbose -Message "Can't get object for IPsecPhase1AuthSet with DisplayName $DisplayName"
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
    param 
    (
        [Parameter(Mandatory)]
        [System.String]$DisplayName,

        [Parameter(Mandatory)]
        [System.String]$Authority,

        [Parameter()]
        [ValidateSet("Root", "Intermediate")]
        [System.String]$AuthorityType='Root',

        [Parameter()]
        [System.String]$Description='',

        [Parameter()]
        [System.Boolean]$Machine=$true,

        [Parameter()]
        [System.Boolean]$Health=$false     
    )

    $BoundParameters=@{}
    $CACertNames=@()
    try
    {
        switch($AuthorityType)
        {
            "Root"
            {
                $CACertNames=(Get-ChildItem Cert:\LocalMachine\Root).GetName()
                Break
            }
            "Intermediate"
            {
                $CACertNames=(Get-ChildItem Cert:\LocalMachine\CA).GetName()
                Break
            }
        }
        if($Authority -in $CACertNames)
        {
            $BoundParameters=$MyInvocation.BoundParameters
            if( 'AuthorityType' -notin $MyInvocation.BoundParameters.Keys)
            {
                $BoundParameters.Add('AuthorityType',$AuthorityType)
            }
            if('Description' -notin $MyInvocation.BoundParameters.Keys)
            {
                $BoundParameters.Add('Description',$Description)
            }
            if('Machine' -notin $MyInvocation.BoundParameters.Keys)
            {
                $BoundParameters.Add('Machine',$Machine)
            }
            if('Health' -notin $MyInvocation.BoundParameters.Keys)
            {
                $BoundParameters.Add('Health',$Health)
            }
            $ResourceState=Get-TargetResource @BoundParameters
            if($ResourceState.Count -eq 0)
            {
                Write-Verbose -Message "Going to create IPSecPhase1AuthSet called $DisplayName"
                Write-Verbose -Message "Creating NetIPsecAuthProposal"
                $NetIPsecAuthProposalParam=@{}
                $NetIPsecAuthProposalParam.Add('Cert',$null)
                $NetIPsecAuthProposalParam.Add('Authority',$Authority)
                $NetIPsecAuthProposalParam.Add('AuthorityType',$AuthorityType)
                $NetIPsecAuthProposalParam.Add('ErrorAction','Stop')
                if($BoundParameters['Machine'])
                { 
                    $NetIPsecAuthProposalParam.Add('Machine',$null)
                }
                if($BoundParameters['Health'])
                {
                    $NetIPsecAuthProposalParam.Add('Health',$null)
                }
                $NetIPsecAuthProposal = New-NetIPsecAuthProposal @NetIPsecAuthProposalParam

                Write-Verbose -Message "Creating NetIPsecPhase1AuthSet $DisplayName"
                $NetIPsecPhase1AuthSetParam=@{}
                $NetIPsecPhase1AuthSetParam.Add('DisplayName',$DisplayName)
                $NetIPsecPhase1AuthSetParam.Add('Description',$Description)
                $NetIPsecPhase1AuthSetParam.Add('Proposal',$NetIPsecAuthProposal)
                $NetIPsecPhase1AuthSetParam.Add('ErrorAction','Stop')
                $NetIPsecPhase1AuthSet = New-NetIPsecPhase1AuthSet @NetIPsecPhase1AuthSetParam
            }
            else
            {
                Write-Verbose -Message "Going to modify IPSecPhase1AuthSet called $DisplayName"

                Write-Verbose -Message "Creating NetIPsecAuthProposal"
                $NetIPsecAuthProposalParam=@{}
                $NetIPsecAuthProposalParam.Add('Cert',$null)
                $NetIPsecAuthProposalParam.Add('Authority',$Authority)
                $NetIPsecAuthProposalParam.Add('AuthorityType',$AuthorityType)
                $NetIPsecAuthProposalParam.Add('ErrorAction','Stop')
                if($BoundParameters['Machine'])
                { 
                    $NetIPsecAuthProposalParam.Add('Machine',$null)
                }
                if($BoundParameters['Health'])
                {
                    $NetIPsecAuthProposalParam.Add('Health',$null)
                }
                $NetIPsecAuthProposal = New-NetIPsecAuthProposal @NetIPsecAuthProposalParam

                $NetIPsecPhase1AuthSetParam=@{}
                $NetIPsecPhase1AuthSetParam.Add('DisplayName',$DisplayName)
                $NetIPsecPhase1AuthSetParam.Add('NewDisplayName',$DisplayName)
                $NetIPsecPhase1AuthSetParam.Add('Description',$Description)
                $NetIPsecPhase1AuthSetParam.Add('Proposal',$NetIPsecAuthProposal)
                $NetIPsecPhase1AuthSetParam.Add('ErrorAction','Stop')
                Set-NetIPsecPhase1AuthSet @NetIPsecPhase1AuthSetParam
            }
        }
        else
        {
            Write-Verbose -Message "Can't find CA certificate with $Authority name in $AuthorityType certificate store."
            Write-Verbose -Message "Can't create/modify authentication set. Make sure specified $AuthorityType CA certificate are in place."
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
    [OutputType([System.Boolean])] 
    param 
    (
        [Parameter(Mandatory)]
        [System.String]$DisplayName,

        [Parameter(Mandatory)]
        [System.String]$Authority,

        [Parameter()]
        [ValidateSet("Root", "Intermediate")]
        [System.String]$AuthorityType='Root',

        [Parameter()]
        [System.String]$Description='',

        [Parameter()]
        [System.Boolean]$Machine=$true,

        [Parameter()]
        [System.Boolean]$Health=$false     
    )

    $returnValue=$True
    $BoundParameters=@{}
    try
    {
        $BoundParameters=$MyInvocation.BoundParameters
        if( 'AuthorityType' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('AuthorityType',$AuthorityType)
        }
        if('Description' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Description',$Description)
        }
        if('Machine' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Machine',$Machine)
        }
        if('Health' -notin $MyInvocation.BoundParameters.Keys)
        {
            $BoundParameters.Add('Health',$Health)
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