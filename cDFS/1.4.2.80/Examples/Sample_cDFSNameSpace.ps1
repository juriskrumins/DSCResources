Configuration DFSNamespace
{
    Import-DscResource -ModuleName 'cDFS'

    Node $NodeName
    {
        [PSCredential]$Credential = New-Object System.Management.Automation.PSCredential ("CONTOSO.COM\Administrator", (ConvertTo-SecureString $"MyP@ssw0rd!1" -AsPlainText -Force))    

        # Install the Prerequisite features first
        # Requires Windows Server 2012 R2 Full install
        WindowsFeature RSATDFSMgmtConInstall 
        { 
            Ensure = "Present" 
            Name = "RSAT-DFS-Mgmt-Con" 
        }

        WindowsFeature DFS
        {
            Name = 'FS-DFS-Namespace'
            Ensure = 'Present'
        }

       # Configure the namespace
        cDFSNameSpace DFSNameSpace
        {
            NameSpace            = 'software' 
            ComputerName         = 'fileserver1'           
            Ensure               = 'present'
            DomainName           = 'contoso.com' 
            Description          = 'DFS namespace for storing software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNameSpace Resource
    }
}
