Configuration cIPSecRules {
        param
        (
            [parameter(Mandatory=$true)]
            $IPSecRules
        )

        Import-DscResource -ModuleName cNetworking
        foreach($IPSecRule in $IPSecRules)
        {
            cIPsecRule "cIPsecRule$(Get-Random)"
            {
                DisplayName = $IPSecRule['DisplayName']
                Description = $IPSecRule['Description']
                Enabled = $IPSecRule['Enabled']
                InboundSecurity = $IPSecRule['InboundSecurity']
                LocalAddress = $IPSecRule['LocalAddress']
                LOcalPort = $IPSecRule['LOcalPort']
                Mode = $IPSecRule['Mode']
                OutboundSecurity = $IPSecRule['OutboundSecurity']
                Phase1AuthSetDisplayName = $IPSecRule['Phase1AuthSetDisplayName']
                Profile = $IPSecRule['Profile']
                Protocol = $IPSecRule['Protocol']
                RemoteAddress = $IPSecRule['RemoteAddress']
                RemotePort = $IPSecRule['RemotePort']
            }
        }
}