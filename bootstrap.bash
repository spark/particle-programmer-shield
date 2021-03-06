#!/bin/bash
# This script installs modern Ruby, Chef, and git clones the cookbook to the machine and runs it.
#
# Usage
# ====
#
#   curl -sSL https://raw.githubusercontent.com/spark/chef-particle-base/master/bootstrap.bash | sudo bash
export GIT_CLONE_PATH="/opt/particle-base/git_clone"
export BUILD_DIR=/opt/particle-base/bootstrap/tmp
export COOKBOOKS_PATH="${HOME}/.chef/cookbooks"
set -e

###
# MAIN PROGRAM
###
main() {
  if is_osx; then
    echo 'Detected osx'
    install_on_osx
  elif is_rpi; then
    echo 'Detected Raspberry Pi'
    install_on_rpi
  else
    echo "OS not supported by bootstrap script"
    exit 1
  fi
}

###
# OS X HELPERS
##
is_osx() {
  [[ `uname | grep -i darwin` ]]
}
install_on_osx() {
  echo 'installing ruby + chef via ChefDK'
  export OSX_VERSION="10.11"
  export DMG_FILE="chefdk-0.12.0-1.dmg"
  make_and_cd_to_build_dir
  idempotently_get_chefdk_dmg
  install_dmg
  git_clone_particle_base
  install_cookbooks
  run_chef_client
}
idempotently_get_chefdk_dmg() {
  if [[ -e "$DMG_FILE" ]]; then
    echo "$DMG_FILE exists, not re-downloading"
  else
    curl -L "https://packages.chef.io/stable/mac_os_x/${OSX_VERSION}/${DMG_FILE}" > "$DMG_FILE"
  fi
}
install_dmg() {
  open $DMG_FILE
  echo "Click your way through the installer yo."
}

install_cookbooks() {
  (cd "$GIT_CLONE_PATH" && sudo chef exec berks vendor $COOKBOOKS_PATH)
}
###
# RPI HELPERS
##
is_rpi() {
  [[ `lsb_release -si | grep 'debian|Raspbian'` ]]
}
install_on_rpi() {
  echo 'Building ruby from source and installing chef via rubygems'
  make_and_cd_to_build_dir
  apt-get update

  # Build and install Ruby
  apt-get purge ruby1.9 -y
  apt-get install build-essential libyaml-dev libssl-dev libreadline-dev -y
  rm -rf ruby-2.2.2.tar.gz # done to make it idempotent
  wget http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz
  tar -xvzf ruby-2.2.2.tar.gz
  cd ruby-2.2.2
  ./configure --enable-shared --disable-install-doc --disable-install-rdoc --disable-install-capi
  make install

  # Install gems
  echo "gem: --no-document" >> ~/.gemrc
  gem install chef --no-ri --no-rdoc --version 12.8.1
  gem install bundler --no-ri --no-rdoc

  git_clone_particle_base
  run_chef_client
}

###
# COMMON FUNCTIONS
###
git_clone_particle_base() {
  if [[ -d "$GIT_CLONE_PATH" ]]; then
    echo "$GIT_CLONE_PATH already exists, destroying it"
    rm -rf $GIT_CLONE_PATH
  fi
  mkdir -p "$GIT_CLONE_PATH"
  git clone https://github.com/spark/chef-particle-base.git "$GIT_CLONE_PATH"
}
run_chef_client() {
  cd $COOKBOOKS_PATH
  cd .. # we need to be one up from the cookbooks path in localmode
  chef-client --local --override-runlist 'recipe[particle_base]'
}
make_and_cd_to_build_dir() {
  mkdir -p $BUILD_DIR
  cd $BUILD_DIR
}

main
