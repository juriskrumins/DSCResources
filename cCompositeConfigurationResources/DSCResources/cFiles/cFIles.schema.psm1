Configuration cFiles {
        param
        (
            [parameter(Mandatory=$true)]
            [string[]]$DestinationPaths,
            [parameter(Mandatory=$true)]
            [ValidateSet("Directory","File")]
            [string]$Type,
            [parameter(Mandatory=$true)]
            [PSCredential]$Credential
        )

        foreach($DestinationPath in $DestinationPaths)
        {
            $random=Get-Random
            File "File$random"
            {
                DestinationPath = $DestinationPath
                Credential = $Credential
                Type = $Type
            }
        }
}