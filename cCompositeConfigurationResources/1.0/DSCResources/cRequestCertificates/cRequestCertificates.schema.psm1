Configuration cRequestCertificates {
        param
        (
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable[]]$Certificates,
            [parameter(Mandatory=$false)]
            $Credential=$null

        )

        Import-DscResource -ModuleName cComputerManagement

        foreach($Certificate in $Certificates)
        {
            if($Credential -eq $null)
            {
                cComputerRequestCertificate "cComputerRequestCertificate$(Get-Random)"
                {
                    Id = "cComputerRequestCertificate$random"
                    StoreLocation = $Certificate["StoreLocation"]
                    StoreName = $Certificate["StoreName"]
                    SubjectName = $Certificate["SubjectName"]
                    Template = $Certificate["Template"]
                }
            }
            else
            {
                cComputerRequestCertificate "cComputerRequestCertificate$(Get-Random)"
                {
                    Id = "cComputerRequestCertificate$random"
                    StoreLocation = $Certificate["StoreLocation"]
                    StoreName = $Certificate["StoreName"]
                    SubjectName = $Certificate["SubjectName"]
                    Template = $Certificate["Template"]
                    PsDscRunAsCredential = $Credential
                }
            }
        }
}