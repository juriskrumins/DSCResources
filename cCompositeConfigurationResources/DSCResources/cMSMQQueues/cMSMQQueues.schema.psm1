Configuration cMSMQQueues {
        param
        (
            [parameter(Mandatory=$true)]
            [hashtable[]]$MSMQQueues,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cMSMQ
        foreach($MSMQQueue in $MSMQQueues)
        {
            $random=Get-Random
            cMSMQQueue "cMSMQQueue$random"
            {
                DomainAdministratorCredential = $DomainAdministratorCredential
                QueueName = $MSMQQueue["QueueName"]
                QueueType = $MSMQQueue["QueueType"]
                Transactional = $MSMQQueue["Transactional"]
            }
        }
}