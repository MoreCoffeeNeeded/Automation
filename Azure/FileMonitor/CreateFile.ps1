<#
.SYNOPSIS 
    Creates a file on an Azure VM.

.DESCRIPTION
    Creates a text file in a specific 'Inbox' which is then detected by a Runbook and processed.

.PARAMETER AzureSubscriptionName
    Name of the Azure subscription to connect to
    
.PARAMETER AzureOrgIdCredential
    A credential containing an Org Id username / password with access to this Azure subscription.

	If invoking this runbook inline from within another runbook, pass a PSCredential for this parameter.

	If starting this runbook using Start-AzureAutomationRunbook, or via the Azure portal UI, pass as a string the
	name of an Azure Automation PSCredential asset instead. Azure Automation will automatically grab the asset with
	that name and pass it into the runbook.
    
.PARAMETER ServiceName
    Name of the cloud service where the VM is located.

.PARAMETER VMName    
    Name of the virtual machine that you want to connect to.  

.PARAMETER VMCredentialName
    Name of a PowerShell credential asset that is stored in the Automation service.
    This credential should have access to the virtual machine.

.PARAMETER InboxPath
    The path to the Inbox location to create the file in.


.EXAMPLE
    Copy-ItemToAzureVM -AzureSubscriptionName "Visual Studio Ultimate with MSDN" -ServiceName "myService" -VMName "myVM" -VMCredentialName "myVMCred" -LocalPath ".\myFile.txt" -RemotePath "C:\Users\username\myFileCopy.txt" -AzureOrgIdCredential $cred


.EXAMPLE
    COMPONENT_SFP-CreateSimpleFile -InboxPath "Visual Studio Ultimate with MSDN" -ServiceName "myService" -VMName "myVM" -VMCredentialName "myVMCred" -InboxPath "D:\Dev\Resources\Simple File Process\0_Inbox"  -AzureOrgIdCredential $cred 

.NOTES
    Author:  Matthew Bedford
    Updated: 04/10/2016  
    Version: 0.1
    Credits: Technet Copy-ItemToAzureVM.ps1

#>
Workflow CreateFile
{
  Param(
    [parameter(Mandatory=$true)]
    [String]
    $AzureSubscriptionName,

	[parameter(Mandatory=$true)]
    [PSCredential]
    $AzureOrgIdCredential,
        
    [parameter(Mandatory=$true)]
    [String]
    $ServiceName,
        
    [parameter(Mandatory=$true)]
    [String]
    $VMName,  
        
    [parameter(Mandatory=$true)]
    [String]
    $VMCredentialName,
        
    [parameter(Mandatory=$true)]
    [String]
    $InboxPath
    )

  
  # Get credentials to Azure VM
  $Credential = Get-AutomationPSCredential -Name $VMCredentialName    
  If ($Credential -eq $null)
  {
    throw "Could not retrieve '$VMCredentialName' credential asset. Check that you created this asset in the Automation service."
  }     
    
  # Set up the Azure VM connection by calling the Connect-AzureVM runbook. You should call this runbook after
  # every CheckPoint-WorkFlow in your runbook to ensure that the connection to the Azure VM is restablished if this runbook
  # gets interrupted and starts from the last checkpoint.
  $Uri = Connect-AzureVM -AzureSubscriptionName $AzureSubscriptionName -AzureOrgIdCredential $AzureOrgIdCredential �ServiceName $ServiceName �VMName $VMName

  InLineScript
  {

    Write-Verbose ("Creating file in  $Using:InboxPath")
        
    Invoke-Command -ScriptBlock {
      # Setup file name
      $Date = Get-date -format yyyyMMdd
      $Time = get-date -format HH.mm.ss
      $Filename = "$Date`_$Time.txt"

      # CreateFile
      New-item "$Using:InboxPath\$filename" -type file -Credential $Using:Credential
    } -ConnectionUri $Using:Uri -Credential $Using:Credential  

    Write-Verbose ("Created $Filename in $Using:InboxPath on $Using:VMName")

  }
}
