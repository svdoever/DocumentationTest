# PublishDocumentation.ps1 - Create documentation page for a GitHub project
# Author: Serge van den Oever [Macaw]
# Given a Readme.md in the master branch, publish a documentation page index.html on a gh-pages branch
# using http://www.DocumentUp.com where the content of the page is completely included in index.html
# to optimize SEO.

# Create a temporary directory (http://joelangley.blogspot.co.uk/2009/06/temp-directory-in-powershell.html)
function CreateTempDir
{
   $tmpDir = [System.IO.Path]::GetTempPath()
   $tmpDir = [System.IO.Path]::Combine($tmpDir, [System.IO.Path]::GetRandomFileName())
  
   [System.IO.Directory]::CreateDirectory($tmpDir) | Out-Null

   $tmpDir
}

# Publish the documentation to the repository
git add Readme.md
git commit -m "Updated the documentation"
git push

# Get the url of the repository
$remoteGitRepositoryUrl = git config --get remote.origin.url
if ($remoteGitRepositoryUrl -eq $null)
{
    Write-Host "Execute this script within the folder of a GIT repository."
    exit -1
}

$currentGitBranch = (git symbolic-ref HEAD).split('/')[-1]

# Ensure the creation of a g-=page branch for the documentation pages
git ls-remote --exit-code . origin/gh-pages
if (-not $?)
{
    # Repository does not exist yet, create one from the master one
    git push origin origin:refs/heads/gh-pages
}

# Checkout gh-pages branch to temp folder
$ghpagesRepoFolder = CreateTempDir
Write-Host "Temporary folder for gh-pages repository: $ghpagesRepoFolder"
git clone $remoteGitRepositoryUrl --branch gh-pages --single-branch $ghpagesRepoFolder
Push-Location $ghpagesRepoFolder

# Cleanup all files except the index.html file
git rm -rf *
git reset index.html

# $remoteGitRepositoryUrl is in format https://github.com/MacawNL/WebMatrix.Executer.git
$githubBaseUrl = $remoteGitRepositoryUrl.Replace(".git", "")
$documentupBaseUrl = $githubBaseUrl.Replace("https://github.com", "http://documentup.com")

# Open the current documentation in a browser window
[System.Diagnostics.Process]::Start($githubBaseUrl + "/blob/master/Readme.md")

# Force recompile of documentation using http://documentup.com
[System.Diagnostics.Process]::Start($documentupBaseUrl + "/recompile")
Write-Output "Sleeping for 5 second to wait for recompile of Readme.md at DocumentUp.com"
Start-Sleep -s 5
$wc = New-Object System.Net.WebClient
$wc.DownloadString($documentupBaseUrl) > .\index.html
git add index.html
git commit -m "Updated DocumentUp version of Readme.md"
git push
Pop-Location
# Remove-Item -Path $ghpagesRepoFolder -Force -Recurse
Write-Host "Done."




