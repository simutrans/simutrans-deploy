#!/bin/bash 
# Usage: steam_updater "steam_password"
#
# Interactive script to update Steam repositories of Simutrans
# 1) You will be asked for pakset
# 2) Pakset will be downloaded and unzipped 
# 3) You will be asked for the branch to use
#
# The default branch is NOT available, because it can only be updated manually at:
#
# https://partner.steamgames.com/apps/builds/434520
#
# However for ease of use you can upload to the current point release branch, then merge it with the default branch
#
# If you want to upload to a new branch, first you need to create it from Steamworks.
# 
# ¡Downloads URLs need to be updated manually in this script!

mv_pak() {
	if [ -d PAK* ]; then
		mv PAK* $PAK_NAME
	else
		mv pak* $PAK_NAME
	fi
}

upload_content(){
	cd "$DIR/steam/repos/$PAK_NAME"
	echo "Upload new version to branch..."
	select yn in "122.0" "nightly" "Done"; do
		case $yn in
			"122.0" ) 
				sed -i 's/"setlive".*$/"setlive"   "122"/g' app_build_434520.vdf
				break;;
			"nightly" ) 
				sed -i 's/"setlive".*$/"setlive"   "nightly"/g' app_build_434520.vdf
				break;;
			"Done" ) exit; break;;
		esac
	done
	bash $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/repos/$PAK_NAME/app_build_434520.vdf" +quit
	upload_content
}

DIR=$(pwd)
STEAM_CMD="$DIR/steam/sdk/tools/ContentBuilder/builder_linux/steamcmd.sh"
STEAM_USER="simutransbuild"
STEAM_PASS=$1

echo "IMPORTANT: Remember that this utility can't be used for updating the 'default' branch. Yo still need to use the web interface for that."

select yn in "pak128.german" "Cancel"; do
    case $yn in
		"pak128.german" ) 
			PAK_NAME=pak128.german; 
			URL="https://pak128-german.de/PAK128.german_VS2.1.beta.zip";
			break;;
		"Cancel" ) exit; break;;
    esac
done

cd "$DIR/steam/repos/$PAK_NAME"
mkdir -p pak
cd pak
wget $URL
unzip *.zip
rm *.zip

if [ -d simutrans ]; then
	cd simutrans
	mv_pak
	mv $PAK_NAME ../$PAK_NAME
	cd ..
	rm -rf simutrans
else
	mv_pak
fi

upload_content
rm -rf "$DIR/steam/repos/$PAK_NAME/pak"
