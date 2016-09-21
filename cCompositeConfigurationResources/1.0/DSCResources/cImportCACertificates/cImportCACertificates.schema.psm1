Configuration cImportCACertificates {
        param
        (
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable[]]$ImportCACertificates

        )

        Import-DscResource -ModuleName cComputerManagement

        foreach($ImportCACertificate in $ImportCACertificates)
        {
            if($ImportCACertificate["PsDscRunAsCredential"])
            {
                cImportCACertificate "cImportCACertificate$(Get-Random)"
                {
                    CA = $ImportCACertificate["CA"]
                    CertStoreLocation = $ImportCACertificate["CertStoreLocation"]
                    PsDscRunAsCredential = $ImportCACertificate["PsDscRunAsCredential"]
                }
            }
            else
            {
                cImportCACertificate "cImportCACertificate$(Get-Random)"
                {
                    CA = $ImportCACertificate["CA"]
                    CertStoreLocation = $ImportCACertificate["CertStoreLocation"]
                }
            }
        }
}