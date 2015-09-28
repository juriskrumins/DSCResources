Configuration cFilesFromSourcePath {
        param
        (
            [parameter(Mandatory=$true)]
            $FilesFromSourcePath
        )

        foreach($FileFromSourcePath in $FilesFromSourcePath)
        {
            $random=Get-Random
            File "File$random"
            {
                DestinationPath = $FileFromSourcePath["DestinationPath"]
                Checksum = "SHA-512"
                Force =$true
                SourcePath = $FileFromSourcePath["SourcePath"]
                Type = "File"
            }
        }
}