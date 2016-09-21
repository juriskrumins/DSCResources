Configuration cDeployDSCConfiguration {
        Param
        (
            [Parameter(Mandatory=$true)]
            [String]
            $MachineName,

            [Parameter(Mandatory=$false)]
            [String]
            $ConfigurationSourcePath='C:\Configuration\DSC',

            [Parameter(Mandatory=$false)]
            [String]
            $SysprepUnattendedXMLFile='C:\Unattend.xml',

            [Parameter(Mandatory=$false)]
            [String]
            $GuestDSCModulesUploadPath='C:\Configuration\DSC\Modules',

            [Parameter(Mandatory=$false)]
            [String]
            $GuestDSCModulesDestinationPath='C:\Program Files\WindowsPowerShell\Modules'
        )

        $Random=Get-Random
        Script "DeployDSCModules$($Random)" 
        { 
            GetScript = {
                #Do Nothing
            }
            SetScript = {
                &robocopy "$($Using:GuestDSCModulesUploadPath)" "$Using:GuestDSCModulesDestinationPath" /MIR /ZB /MOVE /R:5 /W:10 /UNILOG:C:\Configuration\DSC\robocopy.log
            }
            TestScript = {
                $ModulesCount=(Get-ChildItem "$Using:GuestDSCModulesUploadPath" -Depth 0 -Directory -ErrorAction SilentlyContinue).Count
                if((Get-Item -Path "$Using:GuestDSCModulesUploadPath" -ErrorAction SilentlyContinue) -and ($ModulesCount -ne 0))
                {
                    if(Get-Item -Path "$($Using:GuestDSCModulesUploadPath)\uploaded" -ErrorAction SilentlyContinue)
                    {
                        $false
                    }
                    else
                    {
                        $true
                    }
                }
                else 
                {
                    $true
                }
            }
        }
        Script "LCMMetaConfiguration$($Random)" 
        { 
            GetScript = {
                #Do Nothing
            }
            SetScript = {
                Move-Item -Path "$($Using:ConfigurationSourcePath)\$($Using:MachineName).meta.mof" -Destination "C:\Windows\System32\Configuration\MetaConfig.mof" -Force
            }
            TestScript = {
                if((Get-Item -Path "$($Using:ConfigurationSourcePath)\$($Using:MachineName).meta.mof" -ErrorAction SilentlyContinue))
                {
                    $false
                }
                else 
                {
                    $true
                }
            }
            DependsOn = "[Script]DeployDSCModules$($Random)"
        }
        Script "DSCConfiguration$($Random)"
        { 
            GetScript = {
                #Do Nothing
            }
            SetScript = {
                Move-Item -Path "$($Using:ConfigurationSourcePath)\$($Using:MachineName).mof" -Destination "C:\Windows\System32\Configuration\Pending.mof" -Force
            }
            TestScript = {
                if((Get-Item -Path "$($Using:ConfigurationSourcePath)\$($Using:MachineName).mof" -ErrorAction SilentlyContinue))
                {
                    $false
                }
                else 
                {
                    $true
                }
            }
            DependsOn = "[Script]DeployDSCModules$($Random)","[Script]LCMMetaConfiguration$($Random)"
        }
        #File "LCMMetaConfiguration$(Get-Random)"
        #{
        #    DestinationPath = 'C:\Windows\System32\Configuration\MetaConfig.mof'
        #    Ensure = 'Present'
        #    SourcePath = "$($ConfigurationSourcePath)\$($MachineName).meta.mof"
        #    Type = 'File'
        #    Checksum = 'SHA-512'
        #    Force = $True
        #    MatchSource = $True
        #}
        #File "DSCConfiguration$(Get-Random)"
        #{
        #    DestinationPath = 'C:\Windows\System32\Configuration\Current.mof'
        #    Ensure = 'Present'
        #    SourcePath = "$($ConfigurationSourcePath)\$($MachineName).mof"
        #    Type = 'File'
        #    Checksum = 'SHA-512'
        #    Force = $True
        #    MatchSource = $True
        #}
        File "RemoveSysprepUnattendXML$($Random)"
        {
            DestinationPath = "$($SysprepUnattendedXMLFile)"
            Type = 'File'
            Ensure = 'Absent'
            Force = $True
        }
}