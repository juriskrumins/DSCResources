Configuration cMSMQQueueACLs {
        param
        (
            [parameter(Mandatory=$true)]
            [hashtable[]]$MSMQQueueACLs,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cMSMQ
        foreach($MSMQQueueACL in $MSMQQueueACLs)
        {
            $random=Get-Random
            cMSMQQueueACL "cMSMQQueueACL$random"
            {
                Id = "cMSMQQueueACL$random"
                DomainAdministratorCredential = $DomainAdministratorCredential
                MessageQueueAccessRights = $MSMQQueueACL["MessageQueueAccessRights"]
                MessageQueueAccessType = $MSMQQueueACL["MessageQueueAccessType"]
                QueueName = $MSMQQueueACL["QueueName"]
                Username = $MSMQQueueACL["Username"]
            }
        }
}