#!/bin/bash 

# Usage: nightly_update "steam_password"
#
# This script updates nightly versions of Simutrans on:
#   1) Arch Linux User Repository (you will need to be the current maintainer)
#   2) Steam (you will need access to the simutransbuild bot account and the simutrans-steam-builds repository)
# 
# The script first fetch the source repositories for new updates. If no updates are found, it will NOT perform any action.
# 
# If you have not initialized the repositories, run first "init.sh". 
# This will also download Steam SDK and AUR repositories used in this script.

UPDATE_STEAM=false
UPDATE_AUR=false
OMIT_CHECK_CHANGES=false
STEAM_DOWNLOAD_URL=https://github.com/simutrans/simutrans-steam-builds/releases/download/Nightly

while getopts 'aho:s:' opt; do
	case "$opt" in
		a)
			UPDATE_AUR=true
			;;
		o)
			OMIT_CHECK_CHANGES=true
			VERSION=${OPTARG}
			;;
		s)
			UPDATE_STEAM=true
			STEAM_PASS=${OPTARG}
			;;
		?|h)
			echo "Usage: $(basename $0) [-a] [-o revision] [-s password]"
			exit 1
	esac
done

check_svn() {
    cd $DIR/sources/$1
    if svn status -u | grep "*"; then
        svn up
        VERSION=$(svn info --show-item revision)
        echo "New version $VERSION of $1 found, updating..."
        return 0
    else
        echo "No new version of $1 found."
        return 1
    fi
}

check_git(){
    cd $DIR/sources/$1
    git fetch
    HEADHASH=$(git rev-parse HEAD)
    UPSTREAMHASH=$(git rev-parse master@{upstream})
    if [ "$HEADHASH" != "$UPSTREAMHASH" ]
    then
        git pull --rebase
        VERSION=$(git rev-list --count HEAD).$(git rev-parse --short HEAD)
        echo "New version $VERSION of $1 found, updating..."
        return 0
    else
        echo "No new version of $1 found."
        return 1
    fi
}

update_aur() {
    cd $DIR/aur/nightly/$1
    sed -i 's,^pkgver=r.*,pkgver='"r$VERSION"',g' PKGBUILD
    makepkg --printsrcinfo > .SRCINFO
    git add .
    git commit -m "nightly build $VERSION"
    git push
    echo "Updating $1 to version $VERSION"
}

update_aur_pkgsums() {
    cd $DIR/aur/nightly/$1
    updpkgsums
    rm *.tar.gz
    update_aur $1
}

build_steam_release() {
    cd $DIR/steam/simutrans-steam-builds
    git pull --rebase
    echo $VERSION > revision.txt
    git add revision.txt
    git commit -m "Steam build r$VERSION"
    git push
    sleep 1800 # give it enough time for the builds to finish
}

update_steam_standard() {
    declare -a arr=("434521" "434522" "434523" "434524" "434634" "434635")

    for i in "${arr[@]}"
    do
        download_steam_standard_repo "$i"
    done
    sed -i 's,"desc.*,"desc" "Standard nightly build r'$VERSION'",g' "$DIR/steam/repos/standard/app_build_434520.vdf"
    bash  $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/repos/standard/app_build_434520.vdf" +quit
    rm -rf $DIR/steam/repos/standard/content
}

download_steam_standard_repo(){
    mkdir -p "$DIR/steam/repos/standard/content/$1"
    cd "$DIR/steam/repos/standard/content/$1"
    if wget "$STEAM_DOWNLOAD_URL/$1.zip"
    then
        unzip "$1.zip"
        rm "$1.zip"
    else
        echo "Failed to download from $2, aborting the deploy of Simutrans for Steam"
        exit
    fi
}

# Input:
#   $1: platform (lin, win, mac)
#   $2: link to zip file
#   $3: name of the binary (simutrans.exe or simutrans)
update_steam_extended() {
    # TODO Mac
    update_steam_extended_bin lin "http://bridgewater-brunel.me.uk/downloads/nightly/linux-x64/simutrans-extended" simutrans
    update_steam_extended_bin win "http://bridgewater-brunel.me.uk/downloads/nightly/windows/Simutrans-Extended-64.exe" simutrans.exe
	update_steam_extended_base
}

update_steam_extended_bin() {
    mkdir -p $DIR/steam/repos/extended/content
    cd $DIR/steam/repos/extended/content
    if wget -O $3 $2 
    then
        bash  $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/repos/extended/app_build_434520_$1.vdf" +quit
    else
        echo "Failed to download from $2, aborting the deploy of Simutrans Extended for $1"
    fi
    rm -rf $DIR/steam/repos/extended/content
}

update_steam_extended_base() {
	mkdir -p $DIR/steam/repos/extended/content
	cp -r $DIR/sources/simutrans-extended-git/simutrans/* $DIR/steam/repos/extended/content/
	bash  $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/repos/extended/app_build_434520_base.vdf" +quit
	rm -rf $DIR/steam/repos/extended/content
}

update_steam_extended_pak() {
    mkdir -p $DIR/steam/repos/pak128.britain-ex/content
    cd $DIR/steam/repos/pak128.britain-ex/content
    wget -O pak128.tar.gz "http://bridgewater-brunel.me.uk/downloads/nightly/pakset/pak128.britain-ex-nightly.tar.gz"
    mkdir pak128.britain-ex
    tar xzvf pak128.tar.gz -C pak128.britain-ex
    rm pak128.tar.gz
    cd ..
    bash  $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/repos/pak128.britain-ex/app_build_434520.vdf" +quit
    rm -rf $DIR/steam/repos/pak128.britain-ex/content
}

DIR=$(pwd)
STEAM_CMD="$DIR/steam/sdk/tools/ContentBuilder/builder_linux/steamcmd.sh"
STEAM_USER="simutransbuild"
echo "Base dir: $DIR"
echo "Update AUR: $UPDATE_AUR"
echo "Update Steam: $UPDATE_STEAM"
echo "Manual Version: $OMIT_CHECK_CHANGES $VERSION"

echo "Initializing..."
if [ "$UPDATE_AUR" = true ] ; then
    if ! ./init.sh -a
    then
        echo "Something failed. Maybe you didn't clone the repository?"
        echo "Exiting..."
        exit
    fi
fi
if [ "$UPDATE_STEAM" = true ] ; then
    if ! ./init.sh -s
    then
        echo "Something failed. Maybe you didn't clone the repository?"
        echo "Exiting..."
        exit
    fi
fi


echo "Updating Simutrans nightly builds"


if [ "$OMIT_CHECK_CHANGES" = true ] || check_svn simutrans-svn ; then
	if [ "$UPDATE_AUR" = true ] ; then
		update_aur simutrans-svn
	fi
	if [ "$UPDATE_STEAM" = true ] ; then
		update_steam_standard
	fi
fi
