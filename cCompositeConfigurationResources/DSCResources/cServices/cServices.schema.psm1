Configuration cServices {
        param
        (
            [parameter(Mandatory=$true)]
            $Services
        )

        foreach($Service in $Services)
        {
            $random=Get-Random
            Service "Service$random"
            {
                Name=$Service["Name"]
                BuiltInAccount=$Service["BuiltInAccount"]
                StartupType=$Service["StartupType"]
                State=$Service["State"]
            }
        }
}