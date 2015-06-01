Configuration cWebSites {
        param
        (
            [parameter(Mandatory = $true)]
            [System.Collections.Hashtable[]]
            $WebSites
        )

        Import-DscResource -ModuleName cWebAdministration

        foreach($WebSite in $WebSites)
        {
            $random=Get-Random
            cWebsite "cWebsite$random"
            {
                Name = $WebSite["Name"]
                ApplicationPool = $WebSite["ApplicationPool"]
                Ensure = $WebSite["Ensure"]
                PhysicalPath = $WebSite["PhysicalPath"]
                State = $WebSite["State"]
                DefaultPage = $WebSite["DefaultPage"]
                BindingInfo = @(
                                    foreach ($bindingInfo in $WebSite["BindingInfo"])
                                    {
                                        if ($bindingInfo.CertificateSubjectName -and $bindingInfo.CertificateStoreName)
                                        {
                                            CTCO_cWebBindingInformation
                                            {
                                                Port                  = [UInt16] $bindingInfo.Port
                                                Protocol              = $bindingInfo.Protocol
                                                IPAddress             = $bindingInfo.IPAddress
                                                HostName              = $bindingInfo.HostName
                                                CertificateSubjectName = $bindingInfo.CertificateSubjectName
                                                CertificateStoreName  = $bindingInfo.CertificateStoreName
                                            }
                                        }
                                        else
                                        {
                                            CTCO_cWebBindingInformation
                                            {
                                                Port                  = [UInt16] $bindingInfo.Port
                                                Protocol              = $bindingInfo.Protocol
                                                IPAddress             = $bindingInfo.IPAddress
                                                HostName              = $bindingInfo.HostName
                                            }
                                        }
                                    }
                                )
            }
        }
}