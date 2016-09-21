Configuration cSmbShares {
        param
        (
            [parameter(Mandatory = $true)]
            [System.Collections.Hashtable[]]
            $SmbShares
        )

        Import-DscResource -ModuleName xSmbShare

        foreach($SmbShare in $SmbShares)
        {
            $random=Get-Random
            xSmbShare "xSmbShare$random"
            {
                Name = $SmbShare["Name"]
                Path = $SmbShare["Path"]
                ChangeAccess = $SmbShare["ChangeAccess"]
                ConcurrentUserLimit = $SmbShare["ConcurrentUserLimit"]
                Description = $SmbShare["Description"]
                EncryptData = $SmbShare["EncryptData"]
                Ensure = $SmbShare["Ensure"]
                FolderEnumerationMode = $SmbShare["FolderEnumerationMode"]
                FullAccess = $SmbShare["FullAccess"]
                NoAccess = $SmbShare["NoAccess"]
                ReadAccess = $SmbShare["ReadAccess"]
            }
        }
}