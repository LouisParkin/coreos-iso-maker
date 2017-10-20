#!/bin/bash

export RUNMODE=$1
export VERSION=$2

NEEDHELP=0

if [ "$RUNMODE" == "help" ]; then
  NEEDHELP=1
fi

if [ "$RUNMODE" == "--help" ]; then
  NEEDHELP=1
fi

if [ $NEEDHELP == 1 ]; then
  echo "Usage: ./execute-build.sh [OPTIONS]"
  echo "Options:"
  echo "  runmode  - should be \"jenkins\" or \"normal\" "
  echo "  version  - should be the docker image tag needed for images baked into the iso"
  echo " "
  echo "Example commandline:"
  echo "./execute-build.sh jenkins latest"
  echo "./execute-build.sh normal release"
  exit 0
fi


# If the first parameter was empty, assume no parameters were given
if [ "$RUNMODE" == "" ]; then
  export RUNMODE="normal"
  echo "RUNMODE WAS BLANK"
else
  if [ "$RUNMODE" != "normal" ]; then #runmode is not normal
    if [ "$RUNMODE" != "jenkins" ]; then #runmode is also not jenkins
      # hardcode runmode to normal, take what was passed in as the version
      export RUNMODE="normal"
      export VERSION=$1
    else
      #runmode is jenkins
      echo "RUNMODE = $RUNMODE"
      echo "VERSION = $VERSION"
    fi
  else
    #runmode is normal
    echo "RUNMODE = $RUNMODE"
    echo "VERSION = $VERSION"
  fi
fi

if [ "$VERSION" == "" ]; then
  export VERSION="latest"
fi

./unsquash.sh "$RUNMODE" "$VERSION"
./resquash.sh
./build-iso.sh
