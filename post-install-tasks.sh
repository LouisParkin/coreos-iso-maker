#!/bin/bash

export RUNMODE=$1
export VERSION=$2

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

echo "RUNMODE = $RUNMODE"
echo "VERSION = $VERSION"

# -----------------------------------------------------------------------------
# Anything you want to happen after the OS starts up (every time)...
# can be put here.
# -----------------------------------------------------------------------------
