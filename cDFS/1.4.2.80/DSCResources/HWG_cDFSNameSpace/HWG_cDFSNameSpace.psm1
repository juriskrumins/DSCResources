#######################################################################################
#  cDFSNameSpace :This resource is used to create, edit or remove DFS namespaces
#  for both domain and local DFS.
#  When the server is the last server in the namespace, the namespace itself will be removed. 
#######################################################################################

data LocalizedData
{
# culture="en-US"
ConvertFrom-StringData -StringData @'
GettingNamespaceMessage=Getting [{0}] DFS namespace [{1} {2}].
DFSAvailabilityMessage=DFS {0} is {2}available [{1}].
NamespaceExistsMessage=DFS namespace [{0} {1}] exists.
TestErrorMessage=[Error] {0} [{1}] and  [{2}] do not match.
NamespaceUpdatedMessage=Setting DFS namespace {0} to value "{1}".
NamespaceRequirementError=[Error] DFS Requirement {0} "{1}" was not available.
NamespaceRemoveMessage=Removing {0} from DFS namespace [{1}].
'@
}

######################################################################################
# The Get-TargetResource cmdlet.
######################################################################################
function Get-TargetResource 
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $NameSpace,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,
        
        [String]
        $ComputerName = ($ENV:COMPUTERNAME),

        [String]
        $DomainName
    )       

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingNamespaceMessage) -f $ComputerName, $DomainName, $NameSpace
    ) -join '' )

    # Create pathname
    if ($DomainName) 
    {
        $DFSRootName = $DomainName
    }
    else 
    {
        $DFSRootName = $ComputerName.ToUpper()
    }

    $Path = "\\$DFSRootName\$NameSpace"

    # get DFS root settings    
    $error.Clear()
    $DFSnRoot = Get-DfsnRoot -ComputerName $ComputerName 
    
    # $DFSnRoot is Nok, DFS is not available
    if ($error){
        $ReturnValue = @{
            Error = 'DFS root not available'
        }
        $Availability = 'not '        
    }    

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.DFSAvailabilityMessage) -f 'root', $DFSRootName, $Availability
    ) -join '' )

    # $DFSnRoot is ok, DFS is available, check if path is allready configured               
    $Result = Get-DfsnRootTarget -Path $Path -ErrorAction SilentlyContinue 

    # No DFS available
    if ($ReturnValue)
    {
        $ReturnValue += @{
            Present = 'Absent'
        }
    }

    else
    {
        $DFSnRoot = Get-DfsnRoot -Path $Path -ErrorAction SilentlyContinue    
                
        $ReturnValue = @{
            Path          = $DFSnRoot.Path
            Type          = $DFSnRoot.Type
            Properties    = $DFSnRoot.Properties
            TimeToLiveSec = $DFSnRoot.TimeToLiveSec
            State         = $DFSnRoot.State
            Description   = $DFSnRoot.Description                        
        }

        $MemberValue = 'Absent'

        # path is allready configured
        if ($Result)
        {
            # Get path members
            $Members += $Result | ForEach-Object -Process { $_.TargetPath.split('\')[2]}        
            
            # Computername allready member of dfs
            if ($Members -contains $Computername)
            {
                $MemberValue = 'Present'
            }
        }
        else
        {
            $Availability = 'not '
        }

        $ReturnValue += @{
            Members = $Members
            Present = $MemberValue
        }
        
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.DFSAvailabilityMessage) -f 'NameSpace', $Path, $Availability
        ) -join '' )

        if ($MemberValue -eq 'Absent')
        {
            $Availability = 'not '
        }

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.DFSAvailabilityMessage) -f 'ComputerName', $Path, $Availability
        ) -join '' )   
    }

    $ReturnValue

} # Get-TargetResource

######################################################################################
# The Set-TargetResource cmdlet.
######################################################################################
function Set-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $NameSpace,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,

        [String]
        $ComputerName = ($ENV:COMPUTERNAME),

        [String]
        $DomainName,
        
        [String]
        $Description
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingNamespaceMessage) -f $ComputerName, $DomainName, $NameSpace
    ) -join '' )

    # Create pathnames
    if ($DomainName) 
    {
        $DFSRootName = $DomainName
    }
    else 
    {
        $DFSRootName = $ComputerName.ToUpper()
    }

    $Path = "\\$DFSRootName\$NameSpace"
    $TargetPath = "\\$($ComputerName.ToUpper())\$NameSpace"

    # Lookup the existing namespaces    
    $DFSnRoot = Get-DfsnRoot -ComputerName $ComputerName -ErrorAction Stop       

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.DFSAvailabilityMessage) -f 'root', $DFSRootName, $Availability
    ) -join '' )

    if ($Ensure -eq 'Present')
    {
        # Set desired Configuration
        $DesiredConfiguration = @{
                Path = $Path
                State = 'online'                                 
        }

        # check if we want to use New-DfsnRoot or Set-DfsnRoot; Get DFS root Settings specified path
        $DFSnRoot = Get-DfsnRoot -Path $Path -ErrorAction SilentlyContinue

        if (!$DFSnRoot)
        {
            # New-DfsnRoot: Check share availability
            if (!$(Get-SmbShare $NameSpace -ErrorAction SilentlyContinue))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.NamespaceRequirementError) -f 'share', $NameSpace
                ) -join '' )
            }                

            else
            {
                # Add additional information
                if ($DomainName)
                {
                    $DesiredConfiguration += @{
                        Type = 'DomainV2'
                    }                    
                }
                else
                {
                    $DesiredConfiguration += @{
                        Type = 'Standalone'
                    }
                }

                if (!$Description)
                {
                    $Description = "DFS of namespace $NameSpace"
                }                    

                $DesiredConfiguration += @{
                    TargetPath  = $TargetPath
                    Description = $Description
                }

                # create New-DfsnRoot
                New-DfsnRoot @DesiredConfiguration | Out-Null                   
                $DesiredConfiguration.GetEnumerator() | ForEach-Object -Process {                
                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.NamespaceUpdatedMessage) -f $_.name, $_.value
                    ) -join '' )  
                }
            }
        }
        else
        {
            if (!$($DFSnRoot.Description))
            {
                $DesiredConfiguration += @{                    
                    Description = "DFS of namespace $NameSpace"
                }
            }

            # reset settings
            Set-DfsnRoot @DesiredConfiguration | Out-Null
            $DesiredConfiguration.GetEnumerator() | ForEach-Object -Process {                
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.NamespaceUpdatedMessage) -f $_.name, $_.value
                ) -join '' )            
            }
                    
            # Get settings root target               
            $DFSnRootTarget = Get-DfsnRootTarget -Path $Path -ErrorAction SilentlyContinue 

            # Get path members
            $Members += $DFSnRootTarget | ForEach-Object -Process { $_.TargetPath.split('\')[2]}        
            
            # Computername is no member of dfs namespace
            if ($Members -notcontains $Computername)                
            {
                # add server to namespace                    
                new-DfsnRootTarget -Path $path -TargetPath $TargetPath | Out-Null
            }
        }
    }
        
    # Remove DFS namespace if absent is set
    else
    {
        # Get settings root target               
        $DFSnRootTarget = Get-DfsnRootTarget -Path $Path -ErrorAction SilentlyContinue 

        # Get path members
        $Members += $DFSnRootTarget | ForEach-Object -Process { $_.TargetPath.split('\')[2]}        
            
        # Computername is last member of dfs namespace
        if ($Members.count -eq 1)                
        {
            # remove namespace
            Remove-DfsnRoot -Path $Path -Confirm:$false -Force | out-null
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NamespaceRemoveMessage) -f 'last server', $Path
            ) -join '' )  
        }            
        else
        {                
            # remove computername from namespace
            remove-DfsnRootTarget -Path $Path -TargetPath $TargetPath -Confirm:$false | out-null

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NamespaceRemoveMessage) -f $ComputerName, $Path
            ) -join '' )   
        }
            
        Remove-SmbShare  -Name $NameSpace -Confirm:$false | out-null
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.NamespaceRemoveMessage) -f 'share', $ComputerName
        ) -join '' )             
    }
} # Set-TargetResource

######################################################################################
# The Test-TargetResource cmdlet.
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $NameSpace,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,

        [String]
        $ComputerName = ($ENV:COMPUTERNAME),

        [String]
        $DomainName,
        
        [String]
        $Description
    )

    # Flag to signal whether settings are correct
    [Boolean] $DesiredConfigurationMatch = $true    
    
    # Gather result from the test 
    $ResultfromGet = Get-TargetResource -Namespace $NameSpace `
                                        -ComputerName $ComputerName `
                                        -DomainName $DomainName `
                                        -Ensure $Ensure
            
    # The test returned an error, display and stop
    if ($ResultfromGet.Error)
    {
        Write-Verbose -Message ("$($MyInvocation.MyCommand): [Error] $($ResultfromGet.Error)") 
        $DesiredConfigurationMatch = $false
    }
    
    else 
    {
        # Test ensure: Present / Absent
        if ($ResultfromGet.Present -ne $Ensure)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.TestErrorMessage) -f 'ensuration', $Ensure, $ResultfromGet.Present
            ) -join '' )          
            $DesiredConfigurationMatch = $false
        }
        
        if ($Ensure -like 'Present')
        {
            # Test Description
            if (($Description) -and ($ResultfromGet.Description -ne $Description)) 
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.TestErrorMessage) -f 'Descriptions', $Description, $ResultfromGet.Description
                ) -join '' )                    
                $DesiredConfigurationMatch = $false
            }
                       
            # Test Type Domain/ Standalone
            if ( (($DomainName) -and ($ResultfromGet.Type -notmatch 'Domain')) -or
                ((!$DomainName) -and ($ResultfromGet.Type -notmatch 'Standalone'))
            )
            {                    
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.TestErrorMessage) -f 'Domains', $DomainName, $($ResultfromGet.Type)
                ) -join '' ) 
                $DesiredConfigurationMatch = $false
            }        
        }
    }
               
    return $DesiredConfigurationMatch 

} # Test-TargetResource
######################################################################################

Export-ModuleMember -Function *-TargetResource

