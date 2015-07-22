Configuration cGroups {
        param
        (
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable[]]$Groups,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential

        )

        Import-DscResource -ModuleName PSDesiredStateConfiguration

        foreach($Group in $Groups)
        {
            $random=Get-Random
            Group "Group$random"
            {
                GroupName = $Group["GroupName"]
                Credential = $DomainAdministratorCredential
                Ensure = $Group["Ensure"]
                MembersToExclude = $Group["MembersToExclude"]
                MembersToInclude = $Group["MembersToInclude"]
            }
        }
}