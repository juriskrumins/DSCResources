Configuration cScheduleTasks {
        param
        (
            [parameter(Mandatory=$true)]
            $ScheduleTasks
        )


        Import-DscResource -ModuleName cScheduledTask

        foreach($ScheduleTask in $ScheduleTasks)
        {
            cScheduleTask "cScheduleTask$(Get-Random)"
            {
                Ensure = $ScheduleTask["Ensure"]
                TaskName = $ScheduleTask["TaskName"]
                TaskPath = $ScheduleTask["TaskPath"]
                Execute = $ScheduleTask["Execute"]
                Argument = $ScheduleTask["Argument"]
                ScheduledAt = $ScheduleTask["ScheduledAt"]
                Daily = $ScheduleTask["Daily"]
                Runlevel = $ScheduleTask["Runlevel"]
                Disable = $ScheduleTask["Disable"]
            }
        }
}