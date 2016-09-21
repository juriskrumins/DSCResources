function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.String[]]
        $UpdateID,
        [parameter(Mandatory = $true)]
        [ValidateSet('Install','Uninstall')]
        [System.String]
        $UpdateApprovalAction,
        [parameter(Mandatory = $true)]
        [System.String]
        $TargetGroupName,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $StartSynchronization=$false
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting WSUS update list with $UpdateApprovalAction action for computer target group $TargetGroupName ..."
        $WSUSServer=Get-WSUSServer -ErrorAction Stop
        $ComputerTargetGroup=$WSUSServer.GetComputerTargetGroups() | Where-Object {$_.Name -eq "$TargetGroupName"}
        if($ComputerTargetGroup)
        {
            $updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope -ErrorAction Stop
            $updateScope.UpdateApprovalActions = "All"
            $ComputerTargetGroupUpdateID = ($WSUSServer.GetUpdateApprovals($updateScope) | Where-Object {$_.ComputerTargetGroupID -eq [guid]"$($ComputerTargetGroup.id)" -and $_.Action -eq "$UpdateApprovalAction"}).UpdateID.UpdateID
            $returnValue.Add('Id',$Id)
            $returnValue.Add('UpdateID',$ComputerTargetGroupUpdateID)
            $returnValue.Add('UpdateApprovalAction',$UpdateApprovalAction)
            $returnValue.Add('TargetGroupName',$TargetGroupName)
            $returnValue.Add('StartSynchronization',$StartSynchronization)
        }
        else
        {
            Write-Verbose -Message "Can't find computer target group $TargetGroupName "
        }
    }
    catch
    {
        Write-Error -Message 'Error occured. $_'
    }
    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.String[]]
        $UpdateID,
        [parameter(Mandatory = $true)]
        [ValidateSet('Install','Uninstall')]
        [System.String]
        $UpdateApprovalAction,
        [parameter(Mandatory = $true)]
        [System.String]
        $TargetGroupName,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $StartSynchronization=$false
    )
    try
    {
        $currentState = Get-TargetResource -Id $ID -UpdateID $UpdateID -UpdateApprovalAction $UpdateApprovalAction -TargetGroupName $TargetGroupName -StartSynchronization $StartSynchronization
        if ( $currentState.Count -ne 0 )
        {
            $updatesToAdd = @()
            if($StartSynchronization)
            {
                Write-Verbose -Message "Starting update list synchronization from upstream server."
                $WSUSServer = Get-WsusServer -ErrorAction Stop
                $WSUSSubscription = $WSUSServer.GetSubscription()
                $WSUSSubscription.StartSynchronization()
                while($WSUSSubscription.GetSynchronizationStatus() -eq "Running")
                {
                    Start-Sleep -Seconds 2
                }
            }
            Write-Verbose -Message "Got WSUS update list with $UpdateApprovalAction action for computer target group $TargetGroupName."
            if($currentState.UpdateID -eq $null)
            {
                Write-Verbose -Message "Current UpdateID list for computer target group $TargetGroupName is empty."
                Write-Verbose -Message "Updates to add to approved for $UpdateApprovalAction updates list: $($UpdateID -join ',')"
                $updatesToAdd = $UpdateID
            }
            else
            {
                $diff=Compare-Object -ReferenceObject $UpdateID -DifferenceObject $currentState.UpdateID
                if($diff -eq $null -or ( $diff -ne $null -and ($diff | Where-Object {$_.SideIndicator -eq '<='}).InputObject.Count -eq 0))
                {
                    Write-Verbose -Message "All required updates are approved for $UpdateApprovalAction. Resource is in desired state. Nothing to do."
                }
                else
                {
                    Write-Verbose -Message "Updates to add to approved for $UpdateApprovalAction updates list: $(($diff | Where-Object {$_.SideIndicator -eq '<='}).InputObject -join ',') "
                    $updatesToAdd = ($diff | Where-Object {$_.SideIndicator -eq '<='}).InputObject
                }
            }
            Foreach($updID in $updatesToAdd)
            {
                Approve-WsusUpdate -Action $UpdateApprovalAction -TargetGroupName $TargetGroupName -Update (Get-WSUSUpdate -UpdateId $updID -ErrorAction Stop) -ErrorAction Stop -Confirm:$false
                Write-Verbose -Message "Update $updID added to approved update list with action $UpdateApprovalAction for $TargetGroupName computer target group"
            }
        }
        else
        {
            Write-Verbose -Message "Can't get WSUS update list with $UpdateApprovalAction action for computer target group $TargetGroupName. Nothing to do."
        }
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.String[]]
        $UpdateID,
        [parameter(Mandatory = $true)]
        [ValidateSet('Install','Uninstall')]
        [System.String]
        $UpdateApprovalAction,
        [parameter(Mandatory = $true)]
        [System.String]
        $TargetGroupName,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $StartSynchronization=$false
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -Id $ID -UpdateID $UpdateID -UpdateApprovalAction $UpdateApprovalAction -TargetGroupName $TargetGroupName -StartSynchronization $StartSynchronization
        if ( $currentState.Count -ne 0 )
        {
            Write-Verbose -Message "Got WSUS update list with $UpdateApprovalAction action for computer target group $TargetGroupName."
            if($currentState.UpdateID -eq $null)
            {
                Write-Verbose -Message "Current UpdateID list for computer target group $TargetGroupName is empty."
                Write-Verbose -Message "Updates  in desired UpdateID list, but not approved for $UpdateApprovalAction on $TargetGroupName target group: $($UpdateID -join ',')"
                $returnValue = $false
            }
            else
            {
                $diff=Compare-Object -ReferenceObject $UpdateID -DifferenceObject $currentState.UpdateID
                if($diff -eq $null -or ( $diff -ne $null -and ($diff | Where-Object {$_.SideIndicator -eq '<='}).InputObject.Count -eq 0))
                {
                    Write-Verbose -Message "All required updates are approved for $UpdateApprovalAction. Resource is in desired state"
                }
                else
                {
                    Write-Verbose -Message "Updates  in desired UpdateID list, but not approved for $UpdateApprovalAction on $TargetGroupName target group: $(($diff | Where-Object {$_.SideIndicator -eq '<='}).InputObject -join ',') "
                    $returnValue = $false
                }
            }
        }
        else
        {
            Write-Verbose -Message "Can't get WSUS update list with $UpdateApprovalAction action for computer target group $TargetGroupName."
            $returnValue=$false
        }
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
    }
    $returnValue
}

Export-ModuleMember -Function *-TargetResource