Configuration cADGroups {
        param
        (
            [parameter(Mandatory=$true)]
            $GroupNames,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cPSDesiredStateConfiguration

        foreach($GroupName in $GroupNames.keys)
        {
            $random=Get-Random
            if(($GroupNames["$GroupName"]).Count -eq 0)
            {
                cGroup "Group$random"
                {
	                GroupName = "$GroupName"
	                DomainAdministratorCredential = $DomainAdministratorCredential
                }
            }
            else
            {
                cGroup "Group$random"
                {
	                GroupName = "$GroupName"
	                DomainAdministratorCredential = $DomainAdministratorCredential
                    Members = $GroupNames["$GroupName"]
                }
            }
        }
}