Function Draw-HR {
    [string]$Character = "-"
    $width = $host.UI.RawUI.BufferSize.Width -4
    Write-Host ($Character * $width)
    }



$x = 0
$i = 0
$table = foreach ( $VM in ( Get-VM ))
{
    New-Object psobject -Property @{
        vCPU = $VM.ProcessorCount
        MemAssignedMB = ($VM.MemoryAssigned)/1mb
        VMName = $VM.Name
        State = $VM.State
    }
    $i = $i + $VM.MemoryAssigned
    $x = $x + $VM.ProcessorCount
}
$i = ($i)/1gb
$table | Sort State | Format-Table -GroupBy State -Property VMName,MemAssignedMB,vCPU
$z = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb
$v = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors


Write-Host "Total VM V-CPUs Allocated: $x"
Write-Host "Total VM Memory Allocated: $([math]::Round($i,2)) GB"
Draw-HR
Write-Host "Hypervisor Total V-CPUs: $v cores"
Write-Host "Hypervisor Total Memory: $([math]::Round($z,2)) GB"
Draw-HR
Write-Host "Remaining V-CPUs Available: $($v - $x) cores"
Write-Host "Remaining Memory Available: $([math]::Round(($z - $i),2)) GB"
