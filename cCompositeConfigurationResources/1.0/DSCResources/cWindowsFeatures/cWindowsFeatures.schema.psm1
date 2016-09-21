Configuration cWindowsFeatures {
        param
        (
            [parameter(Mandatory=$true)]
            $WindowsFeatures

        )
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        foreach($WindowsFeature in $WindowsFeatures.keys)
        {
            WindowsFeature "WindowsFeature$(Get-Random)"
            {
                Name = "$WindowsFeature"
                Ensure = $WindowsFeatures["$WindowsFeature"][0]
                IncludeAllSubFeature = $WindowsFeatures["$WindowsFeature"][1]
            }
        }
}