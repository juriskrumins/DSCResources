Configuration cJoinADDomain {
        param
        (
            [parameter(Mandatory=$true)]
            [string]$NodeName,
            [parameter(Mandatory=$true)]
            [string]$DomainName,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential,
            [parameter(Mandatory=$false)]
            [int64]$RetryCount = 96,
            [parameter(Mandatory=$false)]
            [int]$RetryIntervalSec = 5,
            [parameter(Mandatory=$false)]
            [string]$JoinOU = $null
        )
        Import-DscResource -ModuleName xActiveDirectory
        Import-DscResource -ModuleName xComputerManagement

        $random=Get-Random

        xWaitForADDomain "WaitForADDomain$random"
        {
            DomainName = $DomainName
            DomainUserCredential = $DomainAdministratorCredential
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
        }
        if($JoinOU -eq $null)
        {
            xComputer "xComputerResource$random"
            {
                Name = $NodeName
                Credential = $DomainAdministratorCredential
                DomainName = $DomainName
                DependsOn = "[xWaitForADDomain]WaitForADDomain$random"
            }
        }
        else
        {
            xComputer "xComputerResource$random"
            {
                Name = $NodeName
                Credential = $DomainAdministratorCredential
                DomainName = $DomainName
                JoinOU = $JoinOU
                DependsOn = "[xWaitForADDomain]WaitForADDomain$random"
            }
        }
}