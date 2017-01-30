# https://blogs.msdn.microsoft.com/powershell/2008/07/11/speeding-up-powershell-startup/
# http://stackoverflow.com/questions/4208694/how-to-speed-up-startup-of-powershell-in-the-4-0-environment
# https://msdn.microsoft.com/en-us/library/6t9t5wcf%28v=vs.110%29.aspx?f=255&MSPPError=-2147217396

# fix-powershell4-performance

Write-Host "`n fix-powershell4-performance: start `n"
$env:path = [Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
[AppDomain]::CurrentDomain.GetAssemblies() | % {
  if (! $_.location) {continue}
  $Name = Split-Path $_.location -leaf
  Write-Host -ForegroundColor Yellow "NGENing : $Name"
  ngen install $_.location | % {"`t$_"}
  Write-Host
}

New-Item -Path C:\local\status\powershell4-ngen.ok -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null

Write-Host "`n fix-powershel4-performance: end `n"
