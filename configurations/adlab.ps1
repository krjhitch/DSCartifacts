configuration CreateFirstDC { 
    param ( 
         [Parameter(Mandatory)][String] $DomainName,
         [Parameter(Mandatory)][System.Management.Automation.PSCredential] $Admincreds,
         [Int]$RetryCount       = 6,
         [Int]$RetryIntervalSec = 10
     ) 
     Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory
     
     [System.Management.Automation.PSCredential] $DomainCreds = New-Object System.Management.Automation.PSCredential("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
 
     node 'localhost' {
         WindowsFeature 'ADDSInstall' { 
             Name = "AD-Domain-Services" 
         } 
 
         xADDomain 'FirstDC' {
             DomainName                    = $DomainName
             DomainAdministratorCredential = $DomainCreds
             SafemodeAdministratorPassword = $DomainCreds
             DependsOn                     = "[WindowsFeature]ADDSInstall"
         } 
 
         LocalConfigurationManager {
             ConfigurationMode  = 'ApplyOnly'
             RebootNodeIfNeeded = $true
         }
     }
 }
 
 configuration AddAdditionalDCs {
    param ( 
         [Parameter(Mandatory)][String] $DomainName,
         [Parameter(Mandatory)][System.Management.Automation.PSCredential] $Admincreds
    ) 
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory
     
    [System.Management.Automation.PSCredential] $DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
 
     node 'localhost' {
         xADDomainController 'AdditionalDC' {
             DomainName = $DomainName
             DomainAdministratorCredential = $DomainCreds
             SafemodeAdministratorPassword = $DomainCreds
         }
 
         LocalConfigurationManager 
         {
             ConfigurationMode = 'ApplyOnly'
             RebootNodeIfNeeded = $true
         }
    }
 } 