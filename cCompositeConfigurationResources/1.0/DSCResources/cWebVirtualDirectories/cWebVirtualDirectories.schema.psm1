Configuration cWebVirtualDirectories {
        param
        (
            [parameter(Mandatory = $true)]
            [System.Collections.Hashtable[]]
            $WebVirtualDirectories
        )

        Import-DscResource -ModuleName cWebAdministration

        foreach($WebVirtualDirectory in $WebVirtualDirectories)
        {
            $random=Get-Random
            cWebVirtualDirectory "cWebVirtualDirectory$random"
            {
                Name = $WebVirtualDirectory["Name"]
                PhysicalPath = $WebVirtualDirectory["PhysicalPath"]
                WebApplication = $WebVirtualDirectory["WebApplication"]
                Website = $WebVirtualDirectory["Website"]
                Ensure = $WebVirtualDirectory["Ensure"]
            }
        }
}