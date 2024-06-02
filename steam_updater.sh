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

mv_pak() {
	if [ -d PAK* ]; then
		mv PAK* $REPO_NAME
	else
		mv pak* $REPO_NAME
	fi
}

upload_content(){
	cd "$DIR/steam/repos/$REPO_NAME"
	echo "Upload new version to branch..."
	select yn in "124.1" "124.0" "nightly" "Exit"; do
		case $yn in
			"124.0" )
				sed -i 's/"setlive".*$/"setlive"   "124.0"/g' app_build_434520.vdf
				break;;
			"124.1" )
				sed -i 's/"setlive".*$/"setlive"   "124.1"/g' app_build_434520.vdf
				break;;
			"nightly" ) 
				sed -i 's/"setlive".*$/"setlive"   "nightly"/g' app_build_434520.vdf
				break;;
			"Exit" ) 
				rm -rf "$DIR/steam/repos/$REPO_NAME/content"
				rm -rf "$DIR/steam/repos/$REPO_NAME/output"
				exit; break;;
		esac
	done
	bash $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/repos/$REPO_NAME/app_build_434520.vdf" +quit
	upload_content
}

DIR=$(pwd)
STEAM_CMD="$DIR/steam/sdk/tools/ContentBuilder/builder_linux/steamcmd.sh"
STEAM_USER="simutransbuild"
STEAM_PASS=$1

echo "IMPORTANT: Remember that this utility can't be used for updating the 'default' branch. You still need to use the web interface for that."

select yn in "pak64" "pak64.german" "pak128" "pak128.german" "pak192.comic" "Cancel"; do
    case $yn in
		"pak64" )
			REPO_NAME=pak64;
			break;;
		"pak64.german" ) 
			REPO_NAME=pak64.german; 
			break;;
		"pak128" ) 
			REPO_NAME=pak128; 
			break;;
		"pak128.german" ) 
			REPO_NAME=pak128.german; 
			break;;
		"pak192.comic" ) 
			REPO_NAME=pak192.comic; 
			break;;
		"Cancel" ) exit; break;;
    esac
done

echo "Please introduce the pakset download URL (zip)"
read URL

cd "$DIR/steam/repos/$REPO_NAME"
mkdir -p content
cd content
wget $URL
unzip *.zip
rm *.zip

if [ -d simutrans ]; then
	cd simutrans
	mv_pak
	mv $REPO_NAME ../$REPO_NAME
	cd ..
	rm -rf simutrans
else
	mv_pak
fi

if [ "$REPO_NAME" = "pak64" ]; then
	echo "Please introduce the addons download URL (zip)"
	read URL
	wget $URL
	unzip *.zip
	rm *.zip
	mv simutrans/addons/pak/* $REPO_NAME/
	rm -rf simutrans
fi

upload_content
