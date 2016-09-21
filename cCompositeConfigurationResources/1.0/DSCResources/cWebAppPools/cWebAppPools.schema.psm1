Configuration cWebAppPools {
        param
        (
            [parameter(Mandatory = $true)]
            [System.Collections.Hashtable]
            $WebAppPools
        )

        Import-DscResource -ModuleName xWebAdministration
        Import-DscResource -ModuleName cWebAdministration

        foreach($WebAppPool in $WebAppPools.Keys)
        {
            $random=Get-Random
            switch ($WebAppPools["$WebAppPool"][0]) 
            {
                "Present"
                {
                    xWebAppPool "xWebAppPool$random"
                    {
                        Name = "$WebAppPool"
                        Ensure = $WebAppPools["$WebAppPool"][0]
                        State = $WebAppPools["$WebAppPool"][1]
                    }
                    cWebAppPoolManagedPipelineMode "cWebAppPoolManagedPipelineMode$random"
                    {
                        AppPoolManagedPipelineMode = $WebAppPools["$WebAppPool"][2]
                        AppPoolName = "$WebAppPool"
                        DependsOn = "[xWebAppPool]xWebAppPool$random"
                    }
                    if($WebAppPools["$WebAppPool"][3] -ne $null)
                    {
                        cWebAppPoolProcessModelIdleTimeout "cWebAppPoolProcessModelIdleTimeout$random"
                        {
                            AppPoolName = "$WebAppPool"
                            AppPoolProcessModelIdleTimeout = $WebAppPools["$WebAppPool"][3]
                            DependsOn = "[xWebAppPool]xWebAppPool$random"
                        }
                    }
                    if($WebAppPools["$WebAppPool"][4] -ne $null)
                    {
                        cWebAppPoolRecyclingPeriodicRestartTime "cWebAppPoolRecyclingPeriodicRestartTime$random"
                        {
                            AppPoolName = "$WebAppPool"
                            AppPoolRecyclingPeriodicRestartTime = $WebAppPools["$WebAppPool"][4]
                            DependsOn = "[xWebAppPool]xWebAppPool$random"
                        }
                    }
                    if($WebAppPools["$WebAppPool"][5] -ne $null)
                    {
                        cWebAppPoolEnable32BitAppOnWin64 "cWebAppPoolEnable32BitAppOnWin64$random"
                        {
                            AppPoolEnable32BitAppOnWin64 = $WebAppPools["$WebAppPool"][5]
                            AppPoolName = "$WebAppPool"
                            DependsOn = "[xWebAppPool]xWebAppPool$random"
                        }
                    }
                    if($WebAppPools["$WebAppPool"][6] -ne $null)
                    {
                        $Username = if($WebAppPools["$WebAppPool"][7] -ne $null) {$WebAppPools["$WebAppPool"][7]}else{""}
                        $Password = if($WebAppPools["$WebAppPool"][8] -ne $null) {$WebAppPools["$WebAppPool"][8]}else{""}
                        cWebAppPoolIdentity "cWebAppPoolIdentity$random"
                        {
                            AppPoolName = "$WebAppPool"
                            IdentityType = $WebAppPools["$WebAppPool"][6]
                            Password = $Password
                            Username = $Username
                            DependsOn = "[xWebAppPool]xWebAppPool$random"
                        }
                    }
                }

                "Absent"
                {
                    xWebAppPool "xWebAppPool$random"
                    {
                        Name = "$WebAppPool"
                        Ensure = $WebAppPools["$WebAppPool"][0]
                    }
                }
            }
        }
}