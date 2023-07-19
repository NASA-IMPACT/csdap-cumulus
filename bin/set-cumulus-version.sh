#!/usr/bin/env bash

if [[ -z ${1} ]]; then
  echo "ERROR: Cumulus version not specified"
  echo
  echo "Usage:"
  echo
  echo "    ${0} VERSION"
  echo
  echo "For a list of versions, see https://github.com/nasa/cumulus/releases"
  echo "Note that the list of releases is in reverse chronological order, but"
  echo "the latest release (at the top of the list) is not necessarily the"
  echo "newest version.  It may be a patch release, so you may need to scroll"
  echo "down the list to find the newest version, if that's what you want."
  echo
  exit 1
fi

# If the specified version includes the `v` prefix, remove it.
if [[ "${1}" =~ ^v ]]; then
  _version=${1:1}
else
  _version=${1}
fi

echo "Modified Cumulus version to ${_version} in the following files:"
echo

# Update the Cumulus version in the Terraspace helper function.

perl -i -pe "s/\"v.+\"/\"v${_version}\"/" config/helpers/cumulus_version_helper.rb
echo "- ${_}"

# Update the Cumulus version number for the Node.js dependencies, except for the
# @cumulus/cumulus-message-adapter-js dependency, which is versioned separately
# from the rest of the Cumulus dependencies.

for _filename in package.json scripts/package.json; do
  perl -i -pe "s/(\@cumulus\/(?!cumulus-message-adapter-js)[^\/]+\"\s*:\s*)\"([^~]?[0-9]+(?:\.[0-9]+){2})\"/\$1\"${_version}\"/" "${_filename}"
  echo "- ${_}"
done
