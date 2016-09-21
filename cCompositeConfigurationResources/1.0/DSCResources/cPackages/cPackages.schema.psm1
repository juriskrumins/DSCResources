Configuration cPackages {
        param
        (
            [parameter(Mandatory=$true)]
            $Packages

        )
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        
        foreach($Package in $Packages)
        {
            Package "Package$(Get-Random)"
            {
                Name = "$($Package["Name"])"
                Path = "$($Package["Path"])"
                ProductId = "$($Package["ProductId"])"
                Ensure = "$($Package["Ensure"])"
                Arguments = "$($Package["Arguments"])"
            }
        }
}