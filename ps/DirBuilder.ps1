
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

# Check if the file path is provided
if (-not $FilePath) {
    Write-Host "Please provide the path to the file containing names using -FilePath parameter."
    exit
}

# Check if the file exists
if (Test-Path $FilePath) {
    # Read the content of the file
    $names = Get-Content $FilePath

    # Loop through each name and create a directory
    foreach ($name in $names) {
        # Remove any leading or trailing whitespace
        $name = $name.Trim()

        # Create directory if the name is not empty
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            # Check if directory already exists
            if (-not (Test-Path $name -PathType Container)) {
                # Create the directory
                New-Item -ItemType Directory -Path $name -ErrorAction SilentlyContinue
                Write-Host "Directory '$name' created."
            } else {
                Write-Host "Directory '$name' already exists."
            }
        }
    }
} else {
    Write-Host "File not found at the specified path."
}
