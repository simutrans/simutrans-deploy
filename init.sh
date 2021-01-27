#!/bin/bash

# This script will:
#  1) Download simutrans sources
#  2) Download nightly updated AUR packages
#  3) Download Steam SDK
#
#  It is intended to be used before nightly_update.sh script provided in this repository
#
# git, svn, wget, unzip needed
# If you don't need AUR (for example), comment the "init_aur" line at the end

checkdir(){
    if [ ! -d $1 ]
    then
        mkdir $1
    fi
    cd $1
}

init_sources(){

    cd $DIR
    checkdir "sources"

    # Simutrans Standard
    if [ ! -d "simutrans-svn" ]
    then
        svn checkout svn://servers.simutrans.org/simutrans/trunk
        mv trunk simutrans-svn
    fi

    # Simutrans Extended
    if [ ! -d "simutrans-extended-git" ]
    then
        git clone https://github.com/jamespetts/simutrans-extended
        mv simutrans-extended simutrans-extended-git
    fi

    # PAK128.Britain (for Simutrans Extended)
    if [ ! -d "simutrans-extended-pak128.britain" ]
    then
        git clone https://github.com/jamespetts/simutrans-pak128.britain
        mv simutrans-pak128.britain simutrans-extended-pak128.britain
    fi
}

init_aur(){

    cd $DIR
    
    checkdir "aur"
    checkdir "nightly"

    # Simutrans Standard
    if [ ! -d "simutrans-svn" ]
    then
        git clone ssh://aur@aur.archlinux.org/simutrans-svn.git
    fi

    # Simutrans Extended
    if [ ! -d "simutrans-extended-git" ]
    then
        git clone ssh://aur@aur.archlinux.org/simutrans-extended-git.git
    fi

    # PAK128.Britain (for Simutrans Extended)
    if [ ! -d "simutrans-extended-pak128.britain" ]
    then
        git clone ssh://aur@aur.archlinux.org/simutrans-extended-pak128.britain.git
    fi

}

init_steam(){

    cd $DIR
    checkdir "steam"
    if [ ! -d "sdk" ]
    then
        wget -O sdk.zip https://partner.steamgames.com/downloads/steamworks_sdk.zip
        unzip sdk.zip
        rm sdk.zip
    fi

    if [ ! -d nightlies ]
    then
        return 1
    fi
}

DIR=$(pwd)
init_sources
init_aur
init_steam
