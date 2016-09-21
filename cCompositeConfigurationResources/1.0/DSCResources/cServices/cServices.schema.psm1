Configuration cServices {
        param
        (
            [parameter(Mandatory=$true)]
            $Services
        )

        foreach($Service in $Services)
        {
            $random=Get-Random
            if($Service["BuiltInAccount"] -ne $null)
            {
                Service "Service$random"
                {
                    Name=$Service["Name"]
                    BuiltInAccount=$Service["BuiltInAccount"]
                    StartupType=$Service["StartupType"]
                    State=$Service["State"]
                }
            }
            else
            {
                Service "Service$random"
                {
                    Name=$Service["Name"]
                    StartupType=$Service["StartupType"]
                    State=$Service["State"]
                }
            }
        }
}