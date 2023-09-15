$PrintSvr = "papercut.servite.wa.edu.au"
$QueueName = "Find-Me"
$PrintPath = "\\$PrintSvr\$QueueName"
# Install the printer
(New-Object -Com Wscript.Network).AddWindowsPrinterConnection($Printer)