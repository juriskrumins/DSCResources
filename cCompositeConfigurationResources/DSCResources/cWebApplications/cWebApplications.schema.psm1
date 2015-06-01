Configuration cWebApplications {
        param
        (
            [parameter(Mandatory = $true)]
            [System.Collections.Hashtable]
            $WebApplications
        )

        Import-DscResource -ModuleName xWebAdministration

        foreach($WebApplication in $WebApplications.Keys)
        {
            $random=Get-Random
            xWebApplication "xWebApplication$random"
            {
                Name = "$WebApplication"
                PhysicalPath = "$($WebApplications["$WebApplication"][0])"
                WebAppPool = "$($WebApplications["$WebApplication"][1])"
                Website = "$($WebApplications["$WebApplication"][2])"
                Ensure = "$($WebApplications["$WebApplication"][3])"
            }
        }
}