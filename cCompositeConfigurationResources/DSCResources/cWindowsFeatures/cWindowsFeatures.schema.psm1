Configuration cWindowsFeatures {
        param
        (
            [parameter(Mandatory=$true)]
            $WindowsFeatures

        )
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        $i=0
        foreach($WindowsFeature in $WindowsFeatures.keys)
        {
            $ResourceName="WindowsFeature$($i)"
            WindowsFeature "$ResourceName"
            {
                Name = "$WindowsFeature"
                Ensure = $WindowsFeatures["$WindowsFeature"][0]
                IncludeAllSubFeature = $WindowsFeatures["$WindowsFeature"][1]
            }
            $i++
        }
}