Configuration cFilesContents {
        param
        (
            [parameter(Mandatory=$true)]
            $FilesContents
        )

        foreach($FileContents in $FilesContents)
        {
            $random=Get-Random
            File "File$random"
            {
                DestinationPath = $FileContents["DestinationPath"]
                Checksum = "SHA-512"
                Contents = $FileContents["Contents"]
                Type = "File"
            }
        }
}