configuration CreateFirstDC { 
    param ( 
        [Parameter(Mandatory)][String] $DomainName,
        [Parameter(Mandatory)][System.Management.Automation.PSCredential] $Admincreds,
        [Int]$RetryCount = 6,
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
 
configuration AddAdditionalDC {
    param ( 
        [Parameter(Mandatory)][String] $DomainName,
        [Parameter(Mandatory)][System.Management.Automation.PSCredential] $Admincreds
    ) 
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, xDSCDomainJoin
     
    [System.Management.Automation.PSCredential] $DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
 
    node 'localhost' {
        WindowsFeature 'ADDSInstall' { 
            Name = "AD-Domain-Services" 
        } 

        xADDomainController 'AdditionalDC' {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DependsOn                     = "[WindowsFeature]ADDSInstall","[xDSCDomainJoin]Join$Domain"
        }

        xDSCDomainJoin "Join$Domain" {
            Domain     = $DomainName
            Credential = $DomainCreds
            DependsOn  = "[WindowsFeature]ADDSInstall"
        }
 
        LocalConfigurationManager {
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
    }
} 

configuration JoinAD { 
    param ( 
        [Parameter(Mandatory)][String] $DomainName,
        [Parameter(Mandatory)][System.Management.Automation.PSCredential] $Admincreds
    ) 
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, xDSCDomainJoin
    
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    node 'localhost'  {
        xDSCDomainJoin "Join$Domain" {
            Domain     = $DomainName
            Credential = $DomainCreds
        }

        LocalConfigurationManager {
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
    }
} 