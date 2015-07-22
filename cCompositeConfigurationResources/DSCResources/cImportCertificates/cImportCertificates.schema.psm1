Configuration cImportCertificates {
        param
        (
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable[]]$Certificates

        )

        Import-DscResource -ModuleName cComputerManagement

        foreach($Certificate in $Certificates)
        {
            $random=Get-Random
            cComputerImportCertificate "cComputerImportCertificate$random"
            {
                Base64EncodedPfx = $Certificate["Base64EncodedPfx"]
                Id = "cComputerImportCertificate$random"
                PfxPassword = $Certificate["PfxPassword"]
                StoreLocation = $Certificate["StoreLocation"]
                StoreName = $Certificate["StoreName"]
            }
        }
}