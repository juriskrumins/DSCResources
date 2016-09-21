Configuration cxADGroups {
        param
        (
            [parameter(Mandatory=$true)]
            $Groups,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName xActiveDirectory

        foreach($Group in $Groups)
        {
                xADGroup "xADGroup$(Get-Random)"
                {
                    GroupName = $Group["GroupName"]
                    Category = $Group["Category"]
                    GroupScope = $Group["GroupScope"]
                    Description = $Group["Description"]
                    Members = $Group["Members"]
                    Path = $Group["Path"]
                    PsDscRunAsCredential = $DomainAdministratorCredential
                }
        }
}