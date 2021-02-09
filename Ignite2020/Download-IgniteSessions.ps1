Param (
    ## The directory into which the user wishes to download the files.    
    [Parameter(Mandatory = $false)]
    [string]$directory = $PSScriptRoot,
    ## Optional parameter allowing the user to specifiy the code (or comma seperated codes) of the video(s) they wish to download.
    [Parameter(Mandatory = $false)]
    [string]$sessionCodes = "",
    ## Optional parameter allowing the user to Filter sessions 
    [Parameter(Mandatory = $false)]
    [string]$Product = "", # Microsoft 365, Azure, Dynamics 365
    [string]$Topic = "", # too many to enumerate
    [string]$Level = "" # 100, 200, 300, 400
)

#Regions Functions
function CheckPathLength($path) {
    while ($path.Length -gt 230) {
        $path = Read-Host("The directory entered is too long.`nEnter a new directory or press Enter to use the location of this script");
        if ($path -eq "") { $path = $PSScriptRoot };
    }
    return $path;
}

function CheckPathSyntaxValid($path) {
    while (-Not (Test-Path $path -IsValid)) {
        $path = Read-Host("The syntax of the directory is invalid.`nPlease enter a valid directory or press Enter to use the location of this script")
        if ($path -eq "") { $path = $PSScriptRoot };
    }
    return $path;
}

function CheckPathExists($path) {
    if (-Not (Test-Path -Path $path)) {
        Write-Host("The directory entered does not exist`nCreate directory?");
        $createDirectoryResponse = "invalid";
        while (($createDirectoryResponse -ne "Y") -or ($createDirectoryResponse -ne "y") -or ($createDirectoryResponse -ne "N") -or ($createDirectoryResponse -ne "n")) {
            $createDirectoryResponse = Read-Host("'y' or 'n'");
            if (($createDirectoryResponse -eq "Y") -or ($createDirectoryResponse -eq "y")) {
                New-Item $path -type directory > $null;
                return $path;
            }
            elseif (($createDirectoryResponse -eq "N") -or ($createDirectoryResponse -eq "n")) {
                $enteredPath = Read-Host("Enter another directory");
                while ($path -eq $enteredPath) {
                    $enteredPath = Read-Host("You have entered the same path.`nEnter another directory or press Enter to use the location of this script");
                }
                if ($path -eq "") { $path = $PSScriptRoot };
                return $enteredPath;
            }
        }
    }
    return $path;
}

function DownloadDirectory($path) {
    $repeatLoop = $true;
    while ($repeatLoop) {
        $repeatLoop = $false

        $newPath = CheckPathLength $path;
        if ($newPath -ne $path) { $repeatLoop = $true; $path = $newPath; continue; }

        $newPath = CheckPathSyntaxValid $path;
        if ($newPath -ne $path) { $repeatLoop = $true; $path = $newPath; continue; }

        $newPath = CheckPathExists $path;
        if ($newPath -ne $path) { $repeatLoop = $true; $path = $newPath; continue; }
    }
    $directory = $newPath;
}

function FetchSessionData() {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host("Pulling session data...");
    $sessionsJson = Invoke-WebRequest -Uri $api -Method 'GET';
    $sessions = $sessionsJson | ConvertFrom-Json;
    return $sessions
}

function FilterSessions($sessions, $sessionCodes) {
    if ($sessionCodes.length -eq 0) {
        Write-Host("All sessions containing slides and/or videos will be downloaded");
        return $sessions;
    }
    else {
        $splitSessionCodes = $sessionCodes.Split(",");
        $filteredSessions = @();
        $codesOfSessionsFound = @();
        foreach ($s in $sessions) {
            if ($splitSessionCodes -contains $s.sessionCode) {
                $filteredSessions += $s;
                $codesOfSessionsFound += $s.sessionCode;
            }
        }
        if ($filteredSessions.Count -eq 0) {
            Write-Host("None of the session codes entered could be found. This program will now terminate.");
            Exit;

        }
        if ($splitSessionCodes.Count -ne $codesOfSessionsFound.Count) {
            Write-Host("Some of the session codes entered could not be found. The following sessions will not be downloaded:");
            foreach ($sc in $splitSessionCodes) {
                if (-not ($codesOfSessionsFound -contains $sc)) {
                    Write-Host($sc);
                }
            }
        }
        return $filteredSessions;
    }
}

function CleanFilename($filename) {
    return $filename.Replace(":", "-").Replace("?", "").Replace("/", "-").Replace("<", "").Replace("|", "").Replace('"', "").Replace("*", "")
}

function DownloadSession($sessionObject, $sessionSearchCount, $directory) {
    if (($sessionObject.slideDeck.Length -ne 0) -or ($sessionObject.downloadVideoLink.Length -ne 0)) {
        $code = $sessionObject.sessionCode;
        $title = $sessionObject.title;

        if ($code.Length -eq 0) {
            $code = "NoCodeSession$sessionSearchCount"
        }
        if ($title.Length -eq 0) {
            $title = "NoTitleSession$sessionSearchCount";
        }

        Write-Host("===== $title ($code) =====");

        #Create directory.'
        if ( $s.products -contains "Microsoft 365" ) {
            $BaseFolder = Join-Path -Path $directory -ChildPath "M365";
        }
        elseif ($s.products -contains "Dynamics 365") {
            $BaseFolder = Join-Path -Path $directory -ChildPath "D365";
        }
        elseif ($s.products -contains "Azure") {
            $BaseFolder = Join-Path -Path $directory -ChildPath "Azure"
        }
        else {
            $BaseFolder = Join-Path -Path $directory -ChildPath "General"
        }
        if (-not (Test-Path $Basefolder)) {
            Write-Host "Folder ($BaseFolder) doesn't exist. Creating it..."  ;
            New-Item $BaseFolder -type directory | Out-Null;
        }
        $TopicFolder = Join-Path -Path $BaseFolder -ChildPath $s.Topic;
        if (-not (Test-Path $TopicFolder)) {
            Write-Host "Folder ($TopicFolder) doesn't exist. Creating it..."  ;
            New-Item $TopicFolder -type directory | Out-Null;
        }
        $title = CleanFilename $s.title
        $Folder = $TopicFolder
        if (-not (Test-Path $folder)) {
            Write-Host "Folder ($folder) doesn't exist. Creating it..."  ;
            New-Item $Folder -type directory | Out-Null;
        }
        
        $LevelDescription = ""
        if ($s.level -eq "Foundational (100)") {
            $LevelDescription = "100"
        }
        elseif ($s.level -eq "Intermediate (200)") {
            $LevelDescription = "200"
        }
        elseif ($s.level -eq "Advanced (300)") {
            $LevelDescription = "300"
        }
        elseif ($s.level -eq "Expert (400)") {
            $LevelDescription = "400"
        }
        else {
            $LevelDescription = "NoLvl"
        }

        $videoFile = "$folder\$title($LevelDescription).mp4";
        $slideFile = "$folder\$title($LevelDescription).pptx";

        #Video download.
        if ($sessionObject.downloadVideoLink.Length -ne 0) {
            if (!(test-path $videoFile)) {
                Write-Host "Downloading video: $title ($code).";
                Start-BitsTransfer -Source $sessionObject.downloadVideoLink -Destination $videoFile;
            }
            else {
                Write-Host "Video exists: $videoFile"
            }
        }
        else {
            Write-Host "The session $title ($code) does not contain a video recording."
        }

        #Slides download.
        if ($sessionObject.slideDeck.Length -ne 0) {
            if (!(test-path $slideFile)) {
                Write-Host "Downloading slides for: $title ($code).";
                Start-BitsTransfer -Source $sessionObject.slideDeck -Destination $slideFile;
            }
            else {
                Write-Host "Slides exist: $slideFile"
            }
        }
        else {
            Write-Host "The session $title ($code) does not contain a slide deck."
        }

        Write-Host "Downloading data for: $title ($code).";
        Write-Host("`r`n");
        return $true;
    }
    return $false;
}

#End Region 

#Region Variables
$api = 'https://api.myignite.microsoft.com/api/session/all'

#End Region

#Region Script
DownloadDirectory $directory;
$sessions = FetchSessionData;

If ($sessionCodes -eq "") {
    if ($Product -ne "") {
        $sessions = $sessions | Where-Object { ($_.products -contains $Product) }
    }
    if ($Topic -ne "") {
        $sessions = $sessions | Where-Object { ($_.Topic -eq $Topic) }
    }
    if ($Level -eq "100") {
        $sessions = $sessions | Where-Object { ($_.level -eq "Foundational (100)") }
    }
    if ($Level -eq "200") {
        $sessions = $sessions | Where-Object { ($_.level -eq "Intermediate (200)") }
    }
    if ($Level -eq "300") {
        $sessions = $sessions | Where-Object { ($_.level -eq "Advanced (300)") }
    }
    if ($Level -eq "400") {
        $sessions = $sessions | Where-Object { ($_.level -eq "Expert (400)") }
    }
}
else {
    $sessions = FilterSessions $sessions $sessionCodes;
}

$sessionSearchCount = 0;
$sessionDownloadCount = 0;

foreach ($s in $sessions) {
    if (DownloadSession $s $sessionDownloadCount $directory) {
        $sessionDownloadCount++;
        $metaData += "Session ID: " + $s.sessionId;
        $metaData += "`tSession Code: " + $s.sessionCode;
        $metaData += "`tSession Title: " + $s.title;
        $metaData += "`rSession Description: " + $s.description;
        $metaData += "`r`n`r`n"
    }
    $sessionSearchCount ++;
}
$dataFile = "$directory\download-report.txt";
Out-File -FilePath $dataFile -InputObject $metaData -Encoding ASCII;
Write-Host("$sessionSearchCount session(s) searched.");
Write-Host("$sessionDownloadCount session(s) downloaded.")

#End Region
