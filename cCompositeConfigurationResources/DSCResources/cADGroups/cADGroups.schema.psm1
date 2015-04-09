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
            cGroup "Group$random"
            {
	            GroupName = "$GroupName"
	            DomainAdministratorCredential = $DomainAdministratorCredential
                Members = $GroupNames["$GroupName"]
            }
        }
}