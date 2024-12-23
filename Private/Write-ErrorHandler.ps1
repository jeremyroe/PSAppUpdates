function Write-ErrorHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter()]
        [string]$CustomMessage,
        
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [switch]$ThrowError
    )
    
    $errorMessage = if ($CustomMessage) {
        "$CustomMessage`nError: $($ErrorRecord.Exception.Message)"
    } else {
        $ErrorRecord.Exception.Message
    }
    
    Write-AppLog -Message $errorMessage -Level Error -LogPath $LogPath
    Write-Verbose "Stack Trace: $($ErrorRecord.ScriptStackTrace)"
    
    if ($ThrowError) {
        throw $errorMessage
    }
} 