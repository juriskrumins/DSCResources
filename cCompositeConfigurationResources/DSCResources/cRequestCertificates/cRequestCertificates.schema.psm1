Configuration cRequestCertificates {
        param
        (
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable[]]$Certificates

        )

        Import-DscResource -ModuleName cComputerManagement

        foreach($Certificate in $Certificates)
        {
            $random=Get-Random
            cComputerRequestCertificate "cComputerRequestCertificate$random"
            {
                Id = "cComputerRequestCertificate$random"
                StoreLocation = $Certificate["StoreLocation"]
                StoreName = $Certificate["StoreName"]
                SubjectName = $Certificate["SubjectName"]
                Template = $Certificate["Template"]
            }
        }
}