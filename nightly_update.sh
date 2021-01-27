#!/bin/bash 

# Usage: nightly_update "steam_password"
#
# This script updates nightly versions of Simutrans on:
#   1) Arch Linux User Repository (you will need to be the current maintainer)
#   2) Steam (you will need access to the simutransbuild bot account)
# 
# The script first fetch the source repositories for new updates. If no updates are found, it will NOT perform any action.
# 
# If you have not initialized the repositories, run first "init.sh". 
# This will also download Steam SDK and AUR repositories used in this script.


check_svn() {
    cd $DIR/sources/$1
    if svn status -u | grep "*"; then
        svn up
        VERSION="r$(svnversion | tr -d 'A-z')"
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
        VERSION="r$(git rev-list --count HEAD).$(git rev-parse --short HEAD)"
        echo "New version $VERSION of $1 found, updating..."
        return 0
    else
        echo "No new version of $1 found."
        return 1
    fi
}

update_aur() {
    cd $DIR/aur/nightly/$1
    sed -i 's,^pkgver=r.*,pkgver='"$VERSION"',g' PKGBUILD
    makepkg --printsrcinfo > .SRCINFO
    git add .
    git commit -m "nightly build $VERSION"
    git push
    echo "Updating $1 to version $VERSION"
}

update_steam_standard(){

    # TODO: This only updates the binary, NOT the base files
    # Input:
    #   $1: platform (lin, win, mac)
    #   $2: link to zip file
    #   $3: name of the binary (simutrans.exe or simutrans)
    update_steam_standard_bin lin "https://nightly.simutrans.com/download.php?os=Linux&r=latest" simutrans
    update_steam_standard_bin win "https://nightly.simutrans.com/download.php?os=Windows&r=latest" simutrans.exe
    #TODO Mac
}
update_steam_standard_bin(){
    cd $DIR/steam/nightlies/standard
    mkdir $1
    cd $1
    mkdir src
    cd src
    if wget -O $1.zip $2 
    then
        unzip "$1.zip"
        cd ..
        mv src/$3 $3
        rm -rf src
        bash  $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/nightlies/standard/app_build_434520_$1.vdf" +quit
    else
        echo "Failed to download from $2, aborting the deploy of Simutrans for $1"
    fi
    rm -rf $DIR/steam/nightlies/standard/$1
}

update_steam_extended(){

    # TODO: This only updates the binary, NOT the base files
    # Input:
    #   $1: platform (lin, win, mac)
    #   $2: link to zip file
    #   $3: name of the binary (simutrans.exe or simutrans)
    update_steam_extended_bin lin "http://bridgewater-brunel.me.uk/downloads/nightly/linux-x64/simutrans-extended" simutrans
    update_steam_extended_bin win "http://bridgewater-brunel.me.uk/downloads/nightly/windows/Simutrans-Extended-64.exe" simutrans.exe
    #TODO Mac
}

update_steam_extended_bin(){
    cd $DIR/steam/nightlies/extended
    mkdir $1
    cd $1
    if wget -O $3 $2 
    then
        bash  $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/nightlies/extended/app_build_434520_$1.vdf" +quit
    else
        echo "Failed to download from $2, aborting the deploy of Simutrans Extended for $1"
    fi
    rm -rf $DIR/steam/nightlies/extended/$1
}

update_steam_extended_pak(){
    cd $DIR/steam/nightlies/pak128.britain-ex
    mkdir pak
    cd pak
    wget -O pak128.tar.gz "http://bridgewater-brunel.me.uk/downloads/nightly/pakset/pak128.britain-ex-nightly.tar.gz"
    mkdir pak128.britain-ex
    tar xzvf pak128.tar.gz -C pak128.britain-ex
    rm pak128.tar.gz
    cd ..
    bash  $STEAM_CMD +login "$STEAM_USER" "$STEAM_PASS" +run_app_build "$DIR/steam/nightlies/pak128.britain-ex/app_build_434520.vdf" +quit
    rm -rf $DIR/steam/nightlies/pak128.britain-ex/pak
$1
}

DIR=$(pwd)
STEAM_CMD="$DIR/steam/sdk/tools/ContentBuilder/builder_linux/steamcmd.sh"
STEAM_USER="simutransbuild"
STEAM_PASS="$1"

echo "Initializing..."
if ! ./init.sh
then
    echo "Something failed. Maybe you didn't clone the repository?"
    echo "Exiting..."
fi

echo "Updating Simutrans nightly builds"

if check_svn simutrans-svn; then
    update_aur simutrans-svn
    update_steam_standard
fi

if check_git simutrans-extended-git; then
    update_aur simutrans-extended-git
    update_steam_extended
fi

if check_git simutrans-extended-pak128.britain; then
    update_aur simutrans-extended-pak128.britain
    update_steam_extended_pak
fi
