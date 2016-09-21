Configuration cADComputers {
        param
        (
            [parameter(Mandatory=$true)]
            $ADComputers,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cActiveDirectory

        foreach($ADComputer in $ADComputers.Keys)
        {
            $random=Get-Random
            if($ADComputers["$ADComputer"] -eq "")
            {
                cADComputer "cADComputer$random"
                {
                    ComputerName = "$ADComputer"
                    PsDscRunAsCredential = $DomainAdministratorCredential
                }
            }
            else
            {
                cADComputer "cADComputer$random"
                {
                    ComputerName = "$ADComputer"
                    PsDscRunAsCredential = $DomainAdministratorCredential
                    OUPath = $ADComputers["$ADComputer"]
                }
            }
        }
}