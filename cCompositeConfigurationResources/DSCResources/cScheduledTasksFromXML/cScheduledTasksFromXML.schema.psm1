Configuration cScheduledTasksFromXML {
        param
        (
            [parameter(Mandatory=$true)]
            $ScheduledTasks,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )


        Import-DscResource -ModuleName cScheduledTask

        foreach($ScheduledTask in $ScheduledTasks.keys)
        {
            $random=Get-Random
            cScheduledTaskFromXML "cScheduledTaskFromXML$random"
            {
                DomainAdministratorCredential = $DomainAdministratorCredential
                TaskName = $ScheduledTask
                TaskPath = $ScheduledTasks["$ScheduledTask"][0]
                User = $ScheduledTasks["$ScheduledTask"][1]
                Password = $ScheduledTasks["$ScheduledTask"][2]
                XML = $ScheduledTasks["$ScheduledTask"][3]
            }
        }
}