function FetchSessionData() {
    $api = 'https://api.myignite.microsoft.com/api/session/all'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host("Pulling session data...");
    $sessionsJson = Invoke-WebRequest -Uri $api -Method 'GET';
    $sessions = $sessionsJson | ConvertFrom-Json;
    return $sessions
}
FetchSessionData