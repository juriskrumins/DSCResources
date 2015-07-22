Configuration cWebIISRemoteManagement {
        param
        (
            [parameter(Mandatory = $true)]
            [SYstem.Boolean]$Enable=$false
        )

        Import-DscResource -ModuleName PSDesiredStateConfiguration
        $random=Get-Random
        If($Enable)
        {
            Registry "Registry$random"
            {
                Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WebManagement\Server"
                ValueName = "EnableRemoteManagement"
                Ensure = "Present"
                ValueData = "1"
                ValueType = "Dword"
            }
            Service "Service$random"
            {
                Name = "WMSVC"
                StartupType = "Automatic"
                State = "Running"
                DependsOn = "[Registry]Registry$random"
            }        
        }
        else
        {
            Registry "Registry$random"
            {
                Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WebManagement\Server"
                ValueName = "EnableRemoteManagement"
                Ensure = "Present"
                ValueData = "0"
                ValueType = "Dword"
            }
            Service "Service$random"
            {
                Name = "WMSVC"
                StartupType = "Disabled"
                State = "Stopped"
            }       
        }
}