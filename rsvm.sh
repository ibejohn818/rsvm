# Rust Version Manager
# ====================
#
# To use the rsvm command source this file from your bash profile.

RSVM_VERSION="0.1.0"

# Auto detect the NVM_DIR
if [ ! -d "$RSVM_DIR" ]
then
  export RSVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}) && pwd)
fi

if [ -e "$RSVM_DIR/current/dist/bin" ]
then
  PATH=$RSVM_DIR/current/dist/bin:$PATH
fi

rsvm_use()
{
  if [ -e "$RSVM_DIR/$1" ]
  then
    echo -n "Activating rust $1 ... "

    rm -rf $RSVM_DIR/current
    ln -s $RSVM_DIR/$1 $RSVM_DIR/current
    source $RSVM_DIR/rsvm.sh

    echo "done"
  else
    echo "The specified version $1 of rust is not installed..."
    echo "You might want to install it with the following command:"
    echo ""
    echo "rsvm install $1"
  fi
}

rsvm_current()
{
  target=`echo echo $(readlink .rsvm/current)|tr "/" "\n"`
  echo ${target[@]} | awk '{print$NF}'
}

rsvm_ls()
{
  local VERSION_PATTERN="(nightly|[0-9]\.[0-9]+(\.[0-9]+)?(-alpha)?)"
  local DIRECTORIES=$(find $RSVM_DIR -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; \
    | egrep ^$VERSION_PATTERN \
    | sort)

  echo "Installed versions:"
  echo ""

  if [ $(echo $DIRECTORIES | wc -l) = 0 ]
  then
    echo '  -  None';
  else
    for line in $(echo $DIRECTORIES | tr " " "\n")
    do
      if [ `rsvm_current` = "$line" ]
      then
        echo "  =>  $line"
      else
        echo "  -   $line"
      fi
    done
  fi
}

rsvm_init_folder_structure()
{
  echo -n "Creating the respective folders for rust $1 ... "

  mkdir -p "$RSVM_DIR/$1/src"
  mkdir -p "$RSVM_DIR/$1/dist"

  echo "done"
}

rsvm_install()
{
  local CURRENT_DIR=`pwd`
  local version


  if [[ $1 = "nightly" ]]
  then
    version=nightly.`date "+%Y%m%d%H%M%S"`
  else
    version=$1
  fi
  rsvm_init_folder_structure $version
  cd "$RSVM_DIR/$version/src"

  local ARCH=`uname -m`
  local OSTYPE=`uname`
  if [ "$OSTYPE" = "Linux" ]
  then
    PLATFORM=$ARCH-unknown-linux-gnu
  fi

  if [ -f "rust-$1-$PLATFORM.tar.gz" ]
  then
    echo "Sources for rust $version already downloaded ..."
  else
    echo -n "Downloading sources for rust $version ... "
    curl -o "rust-$1-$PLATFORM.tar.gz" "https://static.rust-lang.org/dist/rust-$1-$PLATFORM.tar.gz"
    echo "done"
  fi

  if [ -e "rust-$1" ]
  then
    echo "Sources for rust $version already extracted ..."
  else
    echo -n "Extracting source ... "
    tar -xzf "rust-$1-$PLATFORM.tar.gz"
    mv "rust-$1-$PLATFORM" "rust-$1"
    echo "done"
  fi

  cd "rust-$1"

  sh install.sh --prefix=$RSVM_DIR/$version/dist

  echo ""
  echo "And we are done. Have fun using rust $version."

  cd $CURRENT_DIR
}

rsvm_ls_remote()
{
  local VERSION_PATTERN="(nightly|[0-9]\.[0-9]+(\.[0-9]+)?(-alpha)?)"
  ARCH=`uname -m`
  OSTYPE=`uname`
  local VERSIONS
  if [ "$OSTYPE" = "Linux" ]
  then
    PLATFORM=$ARCH-unknown-linux-gnu
    # TODO OTHER PLATFORM
  fi
  VERSIONS=$(curl -s http://static.rust-lang.org/dist/index.html -o - \
    | command egrep -o "rust-$VERSION_PATTERN-$PLATFORM.tar.gz" \
    | command uniq \
    | command egrep -o "$VERSION_PATTERN" \
    | command sort)
  echo $VERSIONS
}

rsvm()
{
  local VERSION_PATTERN="(nightly|[0-9]\.[0-9]+(\.[0-9]+)?(-alpha)?)"

  echo ''
  echo 'Rust Version Manager'
  echo '===================='
  echo ''

  case $1 in
    ""|help|--help|-h)
      echo 'Usage:'
      echo ''
      echo '  rsvm help | --help | -h       Show this message.'
      echo '  rsvm install <version>        Download and install a <version>. <version> could be for example "0.12.0".'
      # echo '  rsvm uninstall <version>      Uninstall a <version>.'
      echo '  rsvm use <version>            Activate <version> for now and the future.'
      echo '  rsvm ls | list                List all installed versions of rust.'
      echo '  rsvm ls-remote                List remote versions available for install.'
      echo ''
      echo "Current version: $RSVM_VERSION"
      ;;
    --version|-v)
      echo "v$RSVM_VERSION"
      ;;
    install)
      if [ -z "$2" ]
      then
        # whoops. no version found!
        echo "Please define a version of rust!"
        echo ""
        echo "Example:"
        echo "  rsvm install 0.12.0"
      elif ([[ "$2" =~ ^$VERSION_PATTERN$ ]])
      then
        rsvm_install "$2"
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm install 0.12.0"
      fi
      ;;
    ls|list)
      rsvm_ls
      ;;
    ls-remote)
      rsvm_ls_remote
      ;;
    use)
      if [ -z "$2" ]
      then
        # whoops. no version found!
        echo "Please define a version of rust!"
        echo ""
        echo "Example:"
        echo "  rsvm use 0.12.0"
      elif ([[ "$2" =~ ^[0-9]+\.[0-9]+\.?[0-9]*$ ]])
      then
        rsvm_use "v$2"
      elif ([[ "$2" =~ ^(nightly\.[0-9]+|v[0-9]+\.[0-9]+\.?[0-9]*)$ ]])
      then
        rsvm_use "$2"
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm use 0.12.0"
      fi
      ;;
  esac

  echo ''
}
# vim: et ts=2 sw=2
