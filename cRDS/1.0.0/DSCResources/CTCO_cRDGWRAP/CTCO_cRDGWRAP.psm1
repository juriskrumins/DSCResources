#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]$PolicyName,

		[parameter(Mandatory = $true)]
		[System.Int32]$Status,

		[parameter(Mandatory = $true)]
		[System.String[]]$PortNumbers,

		[parameter(Mandatory = $true)]
		[System.Int32]$ComputerGroupType,

		[parameter(Mandatory = $true)]
		[System.String]$ComputerGroup,

		[parameter(Mandatory = $true)]
		[System.String[]]$UserGroups
	)

    $returnValue=@{}
    try
    {
        Import-Module -Name RemoteDesktopServices -ErrorAction Stop
        Write-Verbose -Message "Checking if Remote Access Policy $PolicyName exists"
        $GatewayServerRAP = Get-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)" -ErrorAction SilentlyContinue
        if($GatewayServerRAP -ne $null)
        {
            Write-Verbose -Message "Remote Access Policy $PolicyName found"
            $returnValue.Add('PolicyName',$($GatewayServerRAP.Name))
            $returnValue.Add('Status',$((Get-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\Status" -ErrorAction SilentlyContinue).CurrentValue))
            $returnValue.Add('PortNumbers',$(@(Get-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\PortNumbers" -ErrorAction SilentlyContinue).CurrentValue -split ','))
            $returnValue.Add('ComputerGroupType',$((Get-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\ComputerGroupType" -ErrorAction SilentlyContinue).CurrentValue))
            $returnValue.Add('ComputerGroup',$((Get-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\ComputerGroup" -ErrorAction SilentlyContinue).CurrentValue))
            $returnValue.Add('UserGroups',$(@(Get-ChildItem -Path "RDS:\GatewayServer\RAP\$($PolicyName)\UserGroups" -ErrorAction SilentlyContinue).Name))
        }
        else
        {
            Write-Verbose -Message "Can't find Remote Access Policy $PolicyName "
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured.$_"
    }
    return $returnValue;


}
#endregion Get-TargetResource

#region Test-TargetResource
function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]$PolicyName,

		[parameter(Mandatory = $true)]
		[System.Int32]$Status,

		[parameter(Mandatory = $true)]
		[System.String[]]$PortNumbers,

		[parameter(Mandatory = $true)]
		[System.Int32]$ComputerGroupType,

		[parameter(Mandatory = $true)]
		[System.String]$ComputerGroup,

		[parameter(Mandatory = $true)]
		[System.String[]]$UserGroups
	)

    $returnValue=$true
    try
    {
        $CurrentRDRAP=Get-TargetResource -PolicyName $PolicyName -Status $Status -PortNumbers $PortNumbers -ComputerGroupType $ComputerGroupType -ComputerGroup $ComputerGroup -UserGroups $UserGroups
        if($CurrentRDRAP.Count -ne 0)
        {
            if($CurrentRDRAP["PolicyName"] -ne $PolicyName)
            {
                Write-Verbose -Message "Policy name property is not in it's desired state."
                $returnValue=$false
            }
            if($CurrentRDRAP["Status"] -ne $Status)
            {
                Write-Verbose -Message "Policy Status property is not in it's desired state."
                $returnValue=$false
            }            
            if(-not ((Compare-Object -ReferenceObject $PortNumbers -DifferenceObject $CurrentRDRAP["PortNumbers"]) -eq $null))
            {
                Write-Verbose -Message "Policy PortNumbers property is not in it's desired state."
                $returnValue=$false
            }
            if($CurrentRDRAP["ComputerGroupType"] -ne $ComputerGroupType)
            {
                Write-Verbose -Message "Policy ComputerGroupType property is not in it's desired state."
                $returnValue=$false
            }
            if($CurrentRDRAP["ComputerGroup"] -ne $ComputerGroup)
            {
                Write-Verbose -Message "Policy ComputerGroup property is not in it's desired state."
                $returnValue=$false
            }
            if(-not ((Compare-Object -ReferenceObject $UserGroups -DifferenceObject $CurrentRDRAP["UserGroups"]) -eq $null))
            {
                Write-Verbose -Message "Policy UserGroups property is not in it's desired state."
                $returnValue=$false
            }
        }
        else
        {
            Write-Verbose -Message "Remote Access Policy $PolicyName not found."
            $returnValue=$false
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $_"
    }
    return $returnValue
}
#endregion Test-TargetResource

#region Set-TargetResource
function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]$PolicyName,

		[parameter(Mandatory = $true)]
		[System.Int32]$Status,

		[parameter(Mandatory = $true)]
		[System.String[]]$PortNumbers,

		[parameter(Mandatory = $true)]
		[System.Int32]$ComputerGroupType,

		[parameter(Mandatory = $true)]
		[System.String]$ComputerGroup,

		[parameter(Mandatory = $true)]
		[System.String[]]$UserGroups
	)

    try
    {
        Import-Module -Name RemoteDesktopServices -ErrorAction Stop
        $CurrentRDRAP=Get-TargetResource -PolicyName $PolicyName -Status $Status -PortNumbers $PortNumbers -ComputerGroupType $ComputerGroupType -ComputerGroup $ComputerGroup -UserGroups $UserGroups
        if($CurrentRDRAP.Count -eq 0)
        {
            Write-Verbose -Message "Remote Access Policy $PolicyName not found. Going to create it."
            New-Item -Path  "RDS:\GatewayServer\RAP" -Name $PolicyName -ComputerGroupType $ComputerGroupType -ComputerGroup $ComputerGroup -UserGroups $UserGroups -Port $PortNumbers -ErrorAction Stop
            Write-Verbose -Message "Setting Remote Access Policy $PolicyName status."
            Set-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\Status" -Value $Status -Force
            Write-Verbose -Message "Remote Access Policy $PolicyName has been created."
        }
        else
        {
            Write-Verbose -Message "Remote Access Policy $PolicyName found. Going to reset all parameters to it's desired state."
            Set-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\Status" -Value $Status -Force
            switch ($ComputerGroupType)
            {
                1 {
                    Set-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\ComputerGroupType" -Value $ComputerGroupType -ComputerGroup $ComputerGroup -Force
                  }
                2 {
                    Set-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\ComputerGroupType" -Value $ComputerGroupType -Force
                  }
            }
            Set-Item -Path "RDS:\GatewayServer\RAP\$($PolicyName)\PortNumbers" -Value $PortNumbers
            $CurrentUserGroups=(Get-ChildItem -Path "RDS:\GatewayServer\RAP\$($PolicyName)\UserGroups").Name
            $diff=Compare-Object -ReferenceObject $UserGroups -DifferenceObject $CurrentUserGroups
            if(-not ($diff -eq $null))
            {
                if($diff.Where{$_.SideIndicator -eq "<="}.Count -ne 0)
                {
                    Write-Verbose -Message "Adding groups to Remote Access Policy  UserGroups property: $($diff.Where{$_.SideIndicator -eq "<="}.InputObject)"
                    Foreach($UserGroup in $diff.Where{$_.SideIndicator -eq "<="}.InputObject)
                    {
                        New-Item -Path  "RDS:\GatewayServer\RAP\$PolicyName\UserGroups" -Name "$UserGroup" -ErrorAction Stop
                    }
                }
                if($diff.Where{$_.SideIndicator -eq "=>"}.Count -ne 0)
                {
                    Write-Verbose -Message "Removing groups from Remote Access Policy UserGroups property: $($diff.Where{$_.SideIndicator -eq "=>"}.InputObject)"
                    Foreach($UserGroup in $diff.Where{$_.SideIndicator -eq "=>"}.InputObject)
                    {
                        Remove-Item -Path  "RDS:\GatewayServer\RAP\$PolicyName\UserGroups\$UserGroup" -ErrorAction Stop
                    }
                }
            }
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $_"
    }
}
#endregion Set-TargetResource

Export-ModuleMember -Function *-TargetResource