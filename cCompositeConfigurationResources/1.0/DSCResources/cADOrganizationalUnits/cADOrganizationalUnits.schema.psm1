Configuration cADOrganizationalUnits {
        param
        (
            [parameter(Mandatory=$true)]
            $ADOrganizationalUnits,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName xActiveDirectory

        Foreach($ADOrganizationalUnit in $ADOrganizationalUnits)
        {
            $Name = "$(($ADOrganizationalUnit -split ',')[0] -replace 'OU=','')"
            $Path = "$(($array=$ADOrganizationalUnit -split ',')[1..$array.count] -join ',')"

            xADOrganizationalUnit "xADOrganizationalUnit$(Get-Random)"
            {
                Name = $Name
                Path = $Path
                PsDscRunAsCredential = $DomainAdministratorCredential
            }
        }
}