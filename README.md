# Download-IgniteSessions
Powershell script to download on demand content from Ignite

## The original I based this on 
If you want to use the original to download all Ignite videos and slide decks, download the original Powershell script [here](https://myignite.techcommunity.microsoft.com/Download-Resources.zip).

## Why
I created this script because I had a need for filtering the bulk of content based on Products, Topic and Level of the sessions. 
And because I wanted a clear overview in a logical folder hierarchy as well as the content be named with the more descriptive title instead of the session code. 

## Examples
You want to checkout the catalog to see what fiters to use, than use the Fetch-SessionData.ps1 script and pipe it into Out-GridView.

```
.\Fetch-SessionData.ps1 | Out-GridView
```

An example of the script with all filtering parameters: 

```
.\Download-IgniteSessions.ps1 -product "Microsoft 365" -Topic "Tooling" -Level 100 -Directory "c:\ignite"
```

You can still run the script as the original to download all content into a give directory. 
To do so run the following: 

```
.\Download-IgniteSessions.ps1 -Directory "c:\ignite"
```

To download a set of sessions, supply the session code like this:

```
.\Download-IgniteSessions.ps1 -Directory "c:\ignite" -sessionCodes "KEY,TK01,TK02,BRK3016"
```