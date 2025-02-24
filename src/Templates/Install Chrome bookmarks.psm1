# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

$BookmarksToAdd = @"
[
    {
        "name": "Imported",
        "bookmarks": [
            {
                "name": "Search Engines",
                "bookmarks": [
                    {
                        "name": "Google",
                        "url": "https://www.google.com"
                    },
                    {
                        "name": "Bing",
                        "url": "https://www.bing.com"
                    },
                    {
                        "name": "DuckDuckGo",
                        "url": "https://www.duckduckgo.com"
                    }
                ]
            },
            {
                "name": "Social Media",
                "bookmarks": [
                    {
                        "name": "Facebook",
                        "url": "https://www.facebook.com"
                    },
                    {
                        "name": "Twitter",
                        "url": "https://www.twitter.com"
                    },
                    {
                        "name": "LinkedIn",
                        "url": "https://www.linkedin.com"
                    }
                ]
            },
            {
                "name": "Video Platforms",
                "bookmarks": [
                    {
                        "name": "YouTube",
                        "url": "https://www.youtube.com"
                    },
                    {
                        "name": "Vimeo",
                        "url": "https://www.vimeo.com"
                    },
                    {
                        "name": "Dailymotion",
                        "url": "https://www.dailymotion.com"
                    }
                ]
            },
            {
                "name": "Development Resources",
                "bookmarks": [
                    {
                        "name": "Stack Overflow",
                        "url": "https://www.stackoverflow.com"
                    },
                    {
                        "name": "GitHub",
                        "url": "https://www.github.com"
                    },
                    {
                        "name": "MDN Web Docs",
                        "url": "https://developer.mozilla.org"
                    }
                ]
            }
        ]
    }
]
"@ | ConvertFrom-Json


function Test-ChromeIsInstalled {
	$paths = @(
		"$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
		"$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
		"$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
	)

	foreach ($path in $paths) {
		if (Test-Path $path) {
			return $true
		}
	}

	return $false
}


function Get-ModuleName {
	return "Import Google Bookmarks"
}

function Test-Execute {
	if (-not(Test-ChromeIsInstalled)) {
		throw "Chrome is not installed. Please install Chrome before running this script."
	}

	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	# Function to get Chrome timestamp
	function Get-ChromeTimestamp {
		$utcNow = [DateTime]::UtcNow
		$epoch = [datetime]::Parse("1601-01-01T00:00:00Z")
		return [long][math]::Round(($utcNow.ToUniversalTime() - $epoch).TotalMilliseconds * 1000)
	}

	# Function to get or create Chrome bookmarks
	function Get-OrCreateBookmarks {
		param (
			[string]$Path
		)

		$defaultBookmarksJson = @"
        {
           "checksum": "",
           "roots": {
              "bookmark_bar": {
                 "children": [],
                 "date_added": "",
                 "date_last_used": "0",
                 "date_modified": "",
                 "guid": "",
                 "id": "1",
                 "name": "Bookmarks bar",
                 "type": "folder"
              },
              "other": {
                 "children": [],
                 "date_added": "",
                 "date_last_used": "0",
                 "date_modified": "0",
                 "guid": "",
                 "id": "2",
                 "name": "Other bookmarks",
                 "type": "folder"
              },
              "synced": {
                 "children": [],
                 "date_added": "",
                 "date_last_used": "0",
                 "date_modified": "0",
                 "guid": "",
                 "id": "3",
                 "name": "Mobile bookmarks",
                 "type": "folder"
              }
           },
           "version": 1
        }
"@

		if (Test-Path $Path) {
			return Get-Content -Path $Path -Raw | ConvertFrom-Json
		}

		# Create the necessary directory if it does not exist
		$dirPath = [System.IO.Path]::GetDirectoryName($Path)
		if (-not (Test-Path $dirPath)) {
			Write-Host "Creating directory: $dirPath"
			New-Item -ItemType Directory -Force -Path $dirPath
		}

		$chromeBookmarks = $defaultBookmarksJson | ConvertFrom-Json
		foreach ($rootKey in @("bookmark_bar", "other", "synced")) {
			if ($chromeBookmarks.roots.$rootKey) {
				$chromeBookmarks.roots.$rootKey.date_added = Get-ChromeTimestamp
				$chromeBookmarks.roots.$rootKey.date_modified = "0"
				$chromeBookmarks.roots.$rootKey.date_last_used = "0"
				$chromeBookmarks.roots.$rootKey.guid = [guid]::NewGuid()
			}
		}

		return $chromeBookmarks
	}

	# Function to get maximum id from Chrome bookmarks
	function Get-MaxId {
		param (
			[object]$ChromeBookmarks
		)

		$maxId = 0

		# Iterate through the roots: bookmark_bar, other, and synced
		foreach ($root in @("bookmark_bar", "other", "synced")) {
			if ($ChromeBookmarks.roots.$root) {
				$maxId = [math]::Max($maxId, (Get-MaxIdFromItems -Items $ChromeBookmarks.roots.$root.children))
			}
		}

		return $maxId
	}

	# Function to get maximum id from bookmark item list
	function Get-MaxIdFromItems {
		param (
			[array]$Items
		)

		$maxId = 0
		foreach ($node in $Items) {
			if ($node.id -match '^\d+$') {
				$id = [int]$node.id
				if ($id -gt $maxId) {
					$maxId = $id
				}
			}

			if ($node.PSObject.Properties.name -match 'children') {
				$childMax = Get-MaxIdFromItems -Items $node.children
				if ($childMax -gt $maxId) {
					$maxId = $childMax
				}
			}
		}

		return $maxId
	}

	# Function to convert bookmarks to Chrome format
	function Convert-ToChromeBookmark {
		param (
			[object]$Item,
			[int]$Depth = 0
		)

		$indent = ' ' * ($Depth * 2)

		$entry = @{}

		if ($Item.PSObject.Properties.name -match 'bookmarks') {
			Write-Host "$indent$($Item.name) (Folder)"

			$entry = @{
				"id"             = [string]$script:nextItemId
				"guid"           = [guid]::NewGuid()
				"type"           = "folder"
				"name"           = $Item.name
				"date_added"     = Get-ChromeTimestamp
				"date_modified"  = "0"
				"date_last_used" = "0"
				"children"       = @()
			}

			$script:nextItemId++

			foreach ($child in $Item.bookmarks) {
				$childBookmark = Convert-ToChromeBookmark -Item $child -Depth ($Depth + 1)
				$entry.children += $childBookmark
			}
		}
		elseif ($Item.PSObject.Properties.name -match 'url') {
			# Chrome discards URLs without scheme, so warn and ignore
			if ($Item.url -notmatch "^https?://") {
				Write-Warning "Skipping '$($Item.name)' with invalid URL (no http/https scheme): $($Item.url)"
				continue
			}

			Write-Host "$indent$($Item.name) (Bookmark)"
			$entry = @{
				"id"             = "$script:nextItemId"
				"guid"           = [guid]::NewGuid()
				"type"           = "url"
				"name"           = $Item.name
				"url"            = $Item.url
				"date_added"     = Get-ChromeTimestamp
				"date_modified"  = Get-ChromeTimestamp
				"date_last_used" = "0"
			}

			$script:nextItemId++
		}

		return $entry
	}

	# Kill Chrome process
	Stop-Process -Name 'chrome' -Force -ErrorAction Ignore

	# Define Chrome bookmarks root path
	$chromeBookmarksRootPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Google\Chrome\User Data\Default"

	# Remove Bookmarks.bak if exists
	$chromeBookmarksBakPath = Join-Path -Path $chromeBookmarksRootPath -ChildPath "Bookmarks.bak"
	if (Test-Path $chromeBookmarksBakPath) {
		Remove-Item $chromeBookmarksBakPath -Force
	}

	# Get or create bookmarks file
	$chromeBookmarksPath = Join-Path -Path $chromeBookmarksRootPath -ChildPath "Bookmarks"
	$chromeBookmarks = Get-OrCreateBookmarks -Path $chromeBookmarksPath

	# Remove checksum if exists
	if ($chromeBookmarks.PSObject.Properties.name -match 'checksum') {
		$chromeBookmarks.PSObject.Properties.Remove('checksum')
	}

	# Determine initial ID counter
	$nextItemId = (Get-MaxId $chromeBookmarks) + 1

	$processedBookmarks = foreach ($item in $BookmarksToAdd) {
		Convert-ToChromeBookmark -Item $item
	}

	$chromeBookmarks.roots.bookmark_bar.children += @($processedBookmarks)

	# Save updated JSON
	$chromeBookmarks | ConvertTo-Json -Depth 100 | Set-Content -Path $chromeBookmarksPath -Encoding UTF8
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
