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
            [int]$RetryIntervalSec = 5
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
        xComputer "xComputerResource$random"
        {
            Name = $NodeName
            Credential = $DomainAdministratorCredential
            DomainName = $DomainName
            DependsOn = "[xWaitForADDomain]WaitForADDomain$random"
        }
}