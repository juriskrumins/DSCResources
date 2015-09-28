Configuration cPackages {
        param
        (
            [parameter(Mandatory=$true)]
            $Packages

        )
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        
        $random=Get-Random
        foreach($Package in $Packages)
        {
            $ResourceName="Package$($random)"
            Package "$ResourceName"
            {
                Name = "$($Package["Name"])"
                Path = "$($Package["Path"])"
                ProductId = "$($Package["ProductId"])"
                Ensure = "$($Package["Ensure"])"
            }
        }
}