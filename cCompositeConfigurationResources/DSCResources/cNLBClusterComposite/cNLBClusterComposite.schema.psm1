Configuration cNLBClusterComposite {
        param
        (
            [parameter(Mandatory=$true)]
            [boolean]$isClusterPrimaryNode,
            [parameter(Mandatory=$true)]
            [string]$ClusterPrimaryNode,
            [parameter(Mandatory=$true)]
            [string]$ClusterPrimaryIP,
            [parameter(Mandatory=$true)]
            [string]$Name,
            [parameter(Mandatory=$true)]
            [string]$InterfaceName,
            [parameter(Mandatory=$true)]
            [ValidateSet("igmpmulticast", "multicast", "unicast")]
            [string]$OperationMode,
            [parameter(Mandatory=$false)]
            [uint32]$RetryCount=60,
            [parameter(Mandatory=$false)]
            [uint64]$RetryIntervalSec=10,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cNLBCluster


        $random=Get-Random
        if ( -not $isClusterPrimaryNode)
        {
            cWaitForNLBCluster "WaitForNLBCluster$random"
            {
                ClusterPrimaryNode = $ClusterPrimaryNode
                Name = $Name
                DomainAdministratorCredential = $DomainAdministratorCredential
                RetryCount = $RetryCount
                RetryIntervalSec = $RetryIntervalSec
            }
            cNLBCluster "NLBCluster$random"
            {
                ClusterPrimaryIP = $ClusterPrimaryIP
                ClusterPrimaryNode = $ClusterPrimaryNode
                DomainAdministratorCredential = $DomainAdministratorCredential
                InterfaceName = $InterfaceName
                Name = $Name
                OperationMode = $OperationMode
                DependsOn = "[cWaitForNLBCluster]WaitForNLBCluster$random"
            }
        }
        if($isClusterPrimaryNode)
        {
            cNLBCluster "NLBCluster$random"
            {
                ClusterPrimaryIP = $ClusterPrimaryIP
                ClusterPrimaryNode = $ClusterPrimaryNode
                DomainAdministratorCredential = $DomainAdministratorCredential
                InterfaceName = $InterfaceName
                Name = $Name
                OperationMode = $OperationMode
            }
        }
}
