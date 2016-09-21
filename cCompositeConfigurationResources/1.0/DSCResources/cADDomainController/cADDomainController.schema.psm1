Configuration cADDomainController {
        param
        (
            [parameter(Mandatory=$true)]
            [string]$DomainName,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential,
            [parameter(Mandatory=$true)]
            [PSCredential]$SafemodeAdministratorPassword,
            [parameter(Mandatory=$false)]
            [boolean]$isFirstDomainController=$false,
            [parameter(Mandatory=$false)]
            [int64]$RetryCount = 96,
            [parameter(Mandatory=$false)]
            [int]$RetryIntervalSec = 5
        )

        Import-DscResource -ModuleName xActiveDirectory
        $random=Get-Random
        switch($isFirstDomainController)
        {
            $true 
            {
			            xADDomain "xADDomain$random"
			            { 
				            DomainName = $DomainName
				            DomainAdministratorCredential = $DomainAdministratorCredential
				            SafemodeAdministratorPassword = $SafemodeAdministratorPassword
			            }
                        xWaitForADDomain WaitForADDomain {
                            DomainName = $DomainName
                            DomainUserCredential = $DomainAdministratorCredential
				            RetryCount = $RetryCount
				            RetryIntervalSec = $RetryIntervalSec
                            DependsOn = "[xADDomain]xADDomain$random"
                        }
                        Break
            }

            $false
            {
			        xWaitForADDomain "xWaitForADDomain$random"
			        {
				        DomainName = $DomainName
				        DomainUserCredential = $DomainAdministratorCredential
				        RetryCount = $RetryCount
				        RetryIntervalSec = $RetryIntervalSec
			        }
			        xADDomainController "xADDomainController$random"
			        { 
				        DomainName = $DomainName
				        DomainAdministratorCredential = $DomainAdministratorCredential
				        SafemodeAdministratorPassword = $SafemodeAdministratorPassword
				        DependsOn = "[xWaitForADDomain]xWaitForADDomain$random"
			        }
                    Break
            }
        }
}