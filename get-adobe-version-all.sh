# author: james romeo gaspar
# creation : 18 August 2023
# Adobe Version for MACs

#!/bin/bash

output=()
productsFound=false

installedProducts=$(system_profiler SPApplicationsDataType | grep -i "Adobe" | grep -E 'Location: /Applications')

while IFS= read -r line; do
if [[ "$line" =~ ^[[:space:]]+Location:[[:space:]]+(.*)$ ]]; then
appLocation="${BASH_REMATCH[1]}"
        
product=$(defaults read "$appLocation/Contents/Info.plist" CFBundleName 2>/dev/null)
version=$(defaults read "$appLocation/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
if [ -z "$version" ]; then
version=$(defaults read "$appLocation/Contents/Info.plist" CFBundleVersion 2>/dev/null)
fi
        
if [ -n "$product" ] && [ -n "$version" ]; then
output+=("$product ($version)")
productsFound=true
fi
fi
done <<< "$installedProducts"

if [ "$productsFound" = true ]; then
IFS=" | " outputStr="${output[*]}"
echo "$outputStr"
else
echo "No Adobe Application Installed"
fi

exit 0
