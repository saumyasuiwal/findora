$ErrorActionPreference = 'Stop'
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

Write-Host "--- 1. Testing Public Routes ---"
$publicRoutes = @('/home', '/items', '/how-it-works', '/about', '/login', '/register', '/forgot-password')
foreach ($r in $publicRoutes) {
    $res = Invoke-WebRequest -Uri ("http://localhost:8080/findora" + $r) -WebSession $session
    Write-Host "[PUBLIC SUCCESS] $r => Status: $($res.StatusCode), Length: $($res.Content.Length)"
}

Write-Host "`n--- 2. Testing Student Login & Routes ---"
$body = @{
    email = 'alex.rivers@campus.edu'
    password = 'Password@123'
}

$loginResp = Invoke-WebRequest -Uri 'http://localhost:8080/findora/login' -Method POST -Body $body -WebSession $session
Write-Host "Student Login followed redirect => Status: $($loginResp.StatusCode), Final URL: $($loginResp.BaseResponse.ResponseUri)"

$studentRoutes = @(
    '/student/dashboard',
    '/student/reports',
    '/student/matches',
    '/student/claims',
    '/student/notifications',
    '/student/profile',
    '/student/report-lost',
    '/student/report-found'
)

foreach ($r in $studentRoutes) {
    try {
        $res = Invoke-WebRequest -Uri ("http://localhost:8080/findora" + $r) -WebSession $session
        Write-Host "[STUDENT SUCCESS] $r => Status: $($res.StatusCode), Length: $($res.Content.Length)"
    } catch {
        Write-Host "[STUDENT ERROR] $r => $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $txt = $reader.ReadToEnd()
            Write-Host "Details: $($txt.Substring(0, [Math]::Min(500, $txt.Length)))"
        }
    }
}

Write-Host "`n--- 3. Testing Admin Login & Routes ---"
$adminSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

$adminBody = @{
    email = 'admin@findora.campus.edu'
    password = 'Password@123'
}

$adminLoginResp = Invoke-WebRequest -Uri 'http://localhost:8080/findora/login' -Method POST -Body $adminBody -WebSession $adminSession
Write-Host "Admin Login followed redirect => Status: $($adminLoginResp.StatusCode), Final URL: $($adminLoginResp.BaseResponse.ResponseUri)"

$adminRoutes = @(
    '/admin/dashboard',
    '/admin/reports',
    '/admin/claims',
    '/admin/returns',
    '/admin/users',
    '/admin/analytics',
    '/admin/locations',
    '/admin/audit-log'
)

foreach ($r in $adminRoutes) {
    try {
        $res = Invoke-WebRequest -Uri ("http://localhost:8080/findora" + $r) -WebSession $adminSession
        Write-Host "[ADMIN SUCCESS] $r => Status: $($res.StatusCode), Length: $($res.Content.Length)"
    } catch {
        Write-Host "[ADMIN ERROR] $r => $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $txt = $reader.ReadToEnd()
            Write-Host "Details: $($txt.Substring(0, [Math]::Min(500, $txt.Length)))"
        }
    }
}
