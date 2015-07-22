#
# cCluster: DSC resource to configure a Windows Cluster. If the cluster does not exist, it will create one in the 
# domain and assign the StaticIPAddress to the cluster. Then, it will add current node to the cluster.
#

#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $StaticIPAddress,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter(Mandatory=$false)]
        [boolean] $noStorage=$false
    )

    $ComputerInfo = Get-WmiObject Win32_ComputerSystem
    if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
    {
        throw "Can't find machine's domain name"
    }
    
    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain
        if ($null -eq $cluster)
        {
            throw "Can't find the cluster $Name"
        }

        $address = Get-ClusterGroup -Cluster $Name -Name "Cluster IP Address" | Get-ClusterParameter "Address"
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

    $retvalue = @{
        Name = $Name
        IPAddress = $address.Value
        noStorage=$noStorage
    }
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $StaticIPAddress,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter(Mandatory=$false)]
        [boolean] $noStorage=$false
    )

    $bCreate = $true

    Write-Verbose -Message "Checking if Cluster $Name is present ..."
    try
    {
        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
        {
            throw "Can't find machine's domain name"
        }

        $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain

        if ($cluster)
        {
            $bCreate = $false     
        }
    }
    catch
    {
        $bCreate = $true

    }

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential  

        if ($bCreate)
        {
            Write-Verbose -Message "Cluster $Name is NOT present"
            Clear-ClusterNode -Force -ErrorAction SilentlyContinue
            New-Cluster -Name $Name -Node $env:COMPUTERNAME -StaticAddress $StaticIPAddress -NoStorage:$noStorage
            Write-Verbose -Message "Created Cluster $Name"
        }
        else
        {
            Write-Verbose -Message "Add node to Cluster $Name ..."
            Write-Verbose -Message "Add-ClusterNode $env:COMPUTERNAME to cluster $Name"
            $list = Get-ClusterNode -Cluster $Name
            foreach ($node in $list)
            {
                if ($node.Name -eq $env:COMPUTERNAME)
                {
                    if ($node.State -eq "Down")
                    {
                        Write-Verbose -Message "node $env:COMPUTERNAME was down, need remove it from the list."
                        Remove-ClusterNode $env:COMPUTERNAME -Cluster $Name -Force
                    }
                }
            }

            Clear-ClusterNode -Force -ErrorAction SilentlyContinue
            Add-ClusterNode -Name $env:COMPUTERNAME -Cluster $Name -NoStorage:$noStorage
            Write-Verbose -Message "Added node to Cluster $Name"
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

# 
# Test-TargetResource
#
# The code will check the following in order: 
# 1. Is machine in domain?
# 2. Does the cluster exist in the domain?
# 3. Is the machine is in the cluster's nodelist?
# 4. Does the cluster node is UP?
#  
# Function will return FALSE if any above is not true. Which causes cluster to be configured.
# 
function Test-TargetResource  
{
    [OutputType([Boolean])]
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $StaticIPAddress,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter(Mandatory=$false)]
        [boolean] $noStorage=$false
    )

    $bRet = $false

    Write-Verbose -Message "Checking if Cluster $Name is present ..."
    try
    {

        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
        {
            Write-Verbose -Message "Can't find machine's domain name"
            $bRet = $false
        }
        else
        {
            try
            {
                ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
         
                $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain

                Write-Verbose -Message "Cluster $Name is present"

                if ($cluster)
                {
                    Write-Verbose -Message "Checking if the node is in cluster $Name ..."
         
                    $allNodes = Get-ClusterNode -Cluster $Name

                    foreach ($node in $allNodes)
                                                                        {
                    if ($node.Name -eq $env:COMPUTERNAME)
                    {
                        if ($node.State -eq "Up")
                        {
                            $bRet = $true
                        }
                        else
                        {
                             Write-Verbose -Message "Node is in cluster $Name but is NOT up, treat as NOT in cluster."
                        }

                        break
                    }
                }

                    if ($bRet)
                    {
                        Write-Verbose -Message "Node is in cluster $Name"
                    }
                    else
                    {
                        Write-Verbose -Message "Node is NOT in cluster $Name"
                    }
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
    }
    catch
    {
        Write-Verbose -Message "Cluster $Name is NOT present with Error $_.Message"
    }

    $bRet
}