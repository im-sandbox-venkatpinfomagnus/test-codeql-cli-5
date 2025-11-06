# GitHub Code Scanning API Access Script
# Updated to display results in table format

# Set your variables
$token = "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"
$org = "im-sandbox-venkatpinfomagnus"
$repo = "CodeQL-Demo"
$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

Write-Host "GitHub Code Scanning API - Alert Summary" -ForegroundColor Cyan
Write-Host "Organization: $org" -ForegroundColor Yellow
Write-Host "Repository: $repo" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Gray

try {
    # Get all code scanning alerts for the specific repository
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$org/$repo/code-scanning/alerts" -Headers $headers -Method GET
    
    if ($response.Count -eq 0) {
        Write-Host "No code scanning alerts found." -ForegroundColor Green
        return
    }
    
    Write-Host "`nTotal Alerts Found: $($response.Count)" -ForegroundColor Magenta
    Write-Host ""
    
    # Display all alerts in table format
    Write-Host "ALL CODE SCANNING ALERTS:" -ForegroundColor White -BackgroundColor DarkBlue
    $response | Select-Object @{
        Name = "Alert#"; Expression = { $_.number }
    }, @{
        Name = "State"; Expression = { $_.state.ToUpper() }
    }, @{
        Name = "Severity"; Expression = { 
            if ($_.rule.severity) { $_.rule.severity.ToUpper() } else { "N/A" }
        }
    }, @{
        Name = "Rule"; Expression = { 
            if ($_.rule.name.Length -gt 40) { 
                $_.rule.name.Substring(0, 37) + "..." 
            } else { 
                $_.rule.name 
            }
        }
    }, @{
        Name = "Tool"; Expression = { $_.tool.name }
    }, @{
        Name = "File"; Expression = { 
            if ($_.most_recent_instance.location.path) {
                $path = $_.most_recent_instance.location.path
                if ($path.Length -gt 30) {
                    "..." + $path.Substring($path.Length - 27)
                } else {
                    $path
                }
            } else { "N/A" }
        }
    }, @{
        Name = "Line"; Expression = { 
            if ($_.most_recent_instance.location.start_line) {
                $_.most_recent_instance.location.start_line
            } else { "N/A" }
        }
    }, @{
        Name = "Created"; Expression = { 
            [DateTime]::Parse($_.created_at).ToString("MM/dd/yyyy")
        }
    } | Format-Table -AutoSize
    
    
    
    # Display summary by tool
    Write-Host "ALERT SUMMARY BY TOOL:" -ForegroundColor White -BackgroundColor DarkMagenta
    $response | Group-Object { $_.tool.name } | Select-Object @{
        Name = "Tool"; Expression = { $_.Name }
    }, @{
        Name = "Count"; Expression = { $_.Count }
    } | Format-Table -AutoSize
    
    # Filter and display only open alerts with more details
    $openAlerts = $response | Where-Object { $_.state -eq "open" }
    if ($openAlerts.Count -gt 0) {
        Write-Host "`nOPEN ALERTS DETAILS:" -ForegroundColor Black -BackgroundColor Red
        $openAlerts | Select-Object @{
            Name = "Alert#"; Expression = { $_.number }
        }, @{
            Name = "Severity"; Expression = { 
                if ($_.rule.severity) { $_.rule.severity.ToUpper() } else { "N/A" }
            }
        }, @{
            Name = "Rule Name"; Expression = { $_.rule.name }
        }, @{
            Name = "Description"; Expression = { 
                if ($_.rule.description -and $_.rule.description.Length -gt 60) {
                    $_.rule.description.Substring(0, 57) + "..."
                } else {
                    $_.rule.description
                }
            }
        }, @{
            Name = "File Path"; Expression = { $_.most_recent_instance.location.path }
        }, @{
            Name = "Line"; Expression = { $_.most_recent_instance.location.start_line }
        }, @{
            Name = "Created Date"; Expression = { 
                [DateTime]::Parse($_.created_at).ToString("yyyy-MM-dd HH:mm")
            }
        } | Format-Table -Wrap
    } else {
        Write-Host "`nNo open alerts found! 🎉" -ForegroundColor Green
    }
    
    # Display high severity alerts if any
    $highSeverityAlerts = $response | Where-Object { $_.rule.severity -eq "high" -or $_.rule.severity -eq "critical" }
    if ($highSeverityAlerts.Count -gt 0) {
        Write-Host "`nHIGH/CRITICAL SEVERITY ALERTS:" -ForegroundColor Yellow -BackgroundColor Red
        $highSeverityAlerts | Select-Object @{
            Name = "Alert#"; Expression = { $_.number }
        }, @{
            Name = "State"; Expression = { $_.state.ToUpper() }
        }, @{
            Name = "Severity"; Expression = { $_.rule.severity.ToUpper() }
        }, @{
            Name = "Rule"; Expression = { $_.rule.name }
        }, @{
            Name = "File"; Expression = { $_.most_recent_instance.location.path }
        }, @{
            Name = "Line"; Expression = { $_.most_recent_instance.location.start_line }
        } | Format-Table -AutoSize
    }
    
    Write-Host "`n" + "=" * 60 -ForegroundColor Gray
    Write-Host "Analysis Complete!" -ForegroundColor Green
    Write-Host "View full details at: https://github.com/$org/$repo/security/code-scanning" -ForegroundColor Blue

} catch {
    Write-Host "Error accessing GitHub API:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Message -like "*401*") {
        Write-Host "`nPossible causes:" -ForegroundColor Yellow
        Write-Host "- Invalid or expired GitHub token" -ForegroundColor Yellow
        Write-Host "- Token missing 'security_events' scope" -ForegroundColor Yellow
        Write-Host "- Token missing 'repo' scope for private repositories" -ForegroundColor Yellow
    } elseif ($_.Exception.Message -like "*404*") {
        Write-Host "`nPossible causes:" -ForegroundColor Yellow
        Write-Host "- Repository not found or no access" -ForegroundColor Yellow
        Write-Host "- Code scanning not enabled on repository" -ForegroundColor Yellow
        Write-Host "- Organization name incorrect" -ForegroundColor Yellow
    }
}
