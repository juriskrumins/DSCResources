Configuration cIPsecPhase1AuthSets {
        param
        (
            [parameter(Mandatory=$true)]
            $IPsecPhase1AuthSets
        )

        Import-DscResource -ModuleName cNetworking
        foreach($IPsecPhase1AuthSet in $IPsecPhase1AuthSets)
        {
            cIPsecPhase1AuthSet "cIPsecPhase1AuthSet$(Get-Random)"
            {
                Authority = $IPsecPhase1AuthSet['Authority']
                DisplayName = $IPsecPhase1AuthSet['DisplayName']
                AuthorityType = $IPsecPhase1AuthSet['AuthorityType']
                Description = $IPsecPhase1AuthSet['Description']
                Health = $IPsecPhase1AuthSet['Health']
                Machine = $IPsecPhase1AuthSet['Machine']
            }
        }
}