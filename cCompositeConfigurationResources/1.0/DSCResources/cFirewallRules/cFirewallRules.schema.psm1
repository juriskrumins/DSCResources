Configuration cFirewallRules {
        param
        (
            [parameter(Mandatory=$true)]
            $FirewallRules
        )

        Import-DscResource -ModuleName xNetworking
        foreach($FirewallRule in $FirewallRules)
        {
            if($FirewallRule['Action'] -eq $null -and $FirewallRule['Direction'] -eq $null -and $FirewallRule['Ensure'] -eq $null)
            {
                xFirewall "xFirewall$(Get-Random)"
                {
                    Name = $FirewallRule['Name']
                    Enabled = $FirewallRule['Enabled']
                }
            }
            else
            {
                xFirewall "xFirewall$(Get-Random)"
                {
                    Name = $FirewallRule['Name']
                    Action = $FirewallRule['Action']
                    Authentication = $FirewallRule['Authentication']
                    Description = $FirewallRule['Description']
                    Direction = $FirewallRule['Direction']
                    DisplayName = $FirewallRule['DisplayName']
                    Enabled = $FirewallRule['Enabled']
                    Encryption = $FirewallRule['Encryption']
                    Ensure = $FirewallRule['Ensure']
                    LocalAddress = $FirewallRule['LocalAddress']
                    LocalPort = $FirewallRule['LocalPort']
                    RemoteAddress = $FirewallRule['RemoteAddress']
                    RemotePort = $FirewallRule['RemotePort']
                    Protocol = $FirewallRule['Protocol']
                }
            }
        }
}