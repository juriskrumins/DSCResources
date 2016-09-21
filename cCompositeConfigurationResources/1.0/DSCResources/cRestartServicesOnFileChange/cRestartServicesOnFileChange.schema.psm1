Configuration cRestartServicesOnFileChange {
        param
        (
            [parameter(Mandatory=$true)]
            $RestartServicesOnFileChange
        )

        Import-DscResource -ModuleName cComputerManagement

        foreach($RestartServiceOnFileChange in $RestartServicesOnFileChange)
        {
            $random=Get-Random
            cRestartServiceOnFileChange "cRestartServiceOnFileChange$random"
            {
                File = $RestartServiceOnFileChange["File"]
                ServiceName = $RestartServiceOnFileChange["ServiceName"]
            }
        }
}