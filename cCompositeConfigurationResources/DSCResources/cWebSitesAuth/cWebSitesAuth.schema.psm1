Configuration cWebSitesAuth {
        param
        (
            [parameter(Mandatory = $true)]
            [System.Collections.Hashtable[]]
            $WebSitesAuth
        )

        Import-DscResource -ModuleName cWebAdministration

        foreach($WebSiteAuth in $WebSitesAuth)
        {
            $random=Get-Random
            switch ($WebSiteAuth["AuthType"])
            {
                "Anonymous" {
                                cWebSiteAuthAnonymousAuthentication "cWebSiteAuthAnonymousAuthentication$random"
                                {
                                    Enabled = $WebSiteAuth["Enabled"]
                                    logonMethod = $WebSiteAuth["logonMethod"]
                                    SiteName = $WebSiteAuth["SiteName"]
                                    Password = $WebSiteAuth["Password"]
                                    UserName = $WebSiteAuth["UserName"]
                                }
                }
                "Forms" {
                                cWebSiteAuthFormsAuthentication "cWebSiteAuthFormsAuthentication$random"
                                {
                                    Mode = $WebSiteAuth["Mode"]
                                    SiteName = $WebSiteAuth["SiteName"]
                                    Cookieless = $WebSiteAuth["Cookieless"]
                                    defaultUrl = $WebSiteAuth["defaultUrl"]
                                    loginUrl = $WebSiteAuth["loginUrl"]
                                    Name = $WebSiteAuth["Name"]
                                    protection = $WebSiteAuth["protection"]
                                    requireSSL = $WebSiteAuth["requireSSL"]
                                    slidingExpiration = $WebSiteAuth["slidingExpiration"]
                                    timeout = $WebSiteAuth["timeout"]
                                }
                }
                "AspNetImpersonation" {
                                cWebSiteAuthAspNetImpersonationAuthentication "cWebSiteAuthAspNetImpersonationAuthentication$random"
                                {
                                    Enabled = $WebSiteAuth["Enabled"]
                                    SiteName = $WebSiteAuth["SiteName"]
                                    password = $WebSiteAuth["password"]
                                    userName = $WebSiteAuth["userName"]
                                }
                }
                "Windows" {
                                cWebSiteAuthWindowsAuthentication "cWebSiteAuthWindowsAuthentication$random"
                                {
                                    Enabled = $WebSiteAuth["Enabled"]
                                    SiteName = $WebSiteAuth["SiteName"]
                                    authPersistNonNTLM = $WebSiteAuth["authPersistNonNTLM"]
                                    authPersistSingleRequest = $WebSiteAuth["authPersistSingleRequest"]
                                    useAppPoolCredentials = $WebSiteAuth["useAppPoolCredentials"]
                                    useKernelMode = $WebSiteAuth["useKernelMode"]
                                }
                }
                "Basic" {
                                cWebSiteAuthBasicAuthentication "cWebSiteAuthBasicAuthentication$random"
                                {
                                    Enabled = $WebSiteAuth["Enabled"]
                                    SiteName = $WebSiteAuth["SiteName"]
                                    defaultLogonDomain = $WebSiteAuth["defaultLogonDomain"]
                                    logonMethod = $WebSiteAuth["logonMethod"]
                                    realm = $WebSiteAuth["realm"]
                                }
                }
            }
        }
}