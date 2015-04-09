Configuration cNLBClusterPortRules {
        param
        (
            [parameter(Mandatory=$true)]
            $NLBClusterPortRules,
            [parameter(Mandatory=$true)]
            [string]$ClusterPrimaryNode,
            [parameter(Mandatory=$true)]
            [string]$ClusterPrimaryIP,
            [parameter(Mandatory=$true)]
            [string]$Name,
            [parameter(Mandatory=$false)]
            [uint32]$RetryCount=60,
            [parameter(Mandatory=$false)]
            [uint64]$RetryIntervalSec=10,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cNLBCluster

        $random=Get-Random
        $cWaitForNLBCluster = "WaitForNLBCluster$random"

        cWaitForNLBCluster $cWaitForNLBCluster
        {
            ClusterPrimaryNode = $ClusterPrimaryNode
            Name = $Name
            DomainAdministratorCredential = $DomainAdministratorCredential
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
        }

        foreach ($NLBClusterPortRule in $NLBClusterPortRules.keys)
        {
            $random=Get-Random
            cNLBClusterPortRule "NLBClusterPortRule$random"
            {
                Name = "NLBClusterPortRule$random"
                ClusterPrimaryNode = $ClusterPrimaryNode
                DomainAdministratorCredential = $DomainAdministratorCredential
                ClusterName = $Name
                Affinity = $NLBClusterPortRules["$NLBClusterPortRule"][0]
                StartPort = $NLBClusterPortRules["$NLBClusterPortRule"][1]
                EndPort = $NLBClusterPortRules["$NLBClusterPortRule"][2]
                IP = $NLBClusterPortRules["$NLBClusterPortRule"][3]
                Mode = $NLBClusterPortRules["$NLBClusterPortRule"][4]
                Protocol = $NLBClusterPortRules["$NLBClusterPortRule"][5]
                Timeout = $NLBClusterPortRules["$NLBClusterPortRule"][6]
                Ensure = $NLBClusterPortRules["$NLBClusterPortRule"][7]
                DependsOn = "[cWaitForNLBCluster]$cWaitForNLBCluster"
            }
        }

}
