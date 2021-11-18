$ImageDir = "C:\tmp\"
$output = "C:\tmp\export"

# Lets get a list of files!
$myImages = Get-ChildItem -Path $ImageDir -File


# If only one dimension is specified, aspect ratio will be maintained
# Width is one number, for Height preface with x ie. x1080 
# > operator will only resize if the image isnt already below the specified, ie (1920x1080>)
# < operator will only resize if the image isn't already above the specified, ie (1920x1080<)

$Sizes = @(
    'x800'
    '1280'
    '1920x1080'
    '1920'
    '2560'
)

# Check and create folders
Foreach ($size in $Sizes) {

    $FolderName = Get-FolderName -Size $Size
    $FolderPath = "$output\$FolderName"

    $result = Test-Path -PathType Container $FolderPath
    #Write-Host "$size folder exists? $result"
    if ($result -eq $False) {
        #Write-Host "Creating Folder... $size"
        New-Item -ItemType Directory -Force -Path $FolderPath
    }
}

# Check and create folders
foreach ($image in $myImages) {

    Start-Resize -Image $image -Sizes $Sizes -Extension "jpg"
} 

function Start-Resize {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Image,
        [Parameter(Mandatory=$true)]
        [array]$Sizes,
        [string]$Extension = "png"
    )

    # Lets get the name and trim existing extension, incase we are changing extensions
    $imgName = [io.path]::GetFileNameWithoutExtension($Image)
        foreach ($size in $Sizes) {
        $FolderName = Get-FolderName -Size $size
        $FolderPath = "$output\$FolderName"
        magick "$ImageDir\$image" -resize $size "$FolderPath\$imgName.$Extension"
    }
}

function Get-FolderName {
    param (
    [Parameter(Mandatory=$true)][String]$Size
    )
    $Size = $Size.Replace(">","")
    $Size = $Size.Replace("<","")

    if ($Size.StartsWith("x",'CurrentCultureIgnoreCase')) {

        $Name = $Size.Replace("x","Height-")
    
    } elseif ($Size.Contains("x")) {
    
        $Name = $Size.Insert(0,"Aspect-")
    
    } else {
        
        $Name = $Size.Insert(0,"Width-")
    }
    Return $Name
}