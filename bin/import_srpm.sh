#!/usr/bin/env sh
# import_srpm.sh: Import SRPM packages to git repo
# Input data
srpm_path=$1
git_path=$2
git_branch=$3
script=$4
token=$5
file_store_url=$6
name=$(rpm -q --qf '[%{Name}]' -p $srpm_path)
version=$(rpm -q --qf '[%{Version}-%{Release}]' -p $srpm_path)
tmp_dir=/tmp/$name-$version-$RANDOM

# Clone destination repo
mkdir -p $tmp_dir
git clone $git_path $tmp_dir

# Switch to import branch
cd $tmp_dir
git branch --track $git_branch origin/$git_branch # Try track remote
git checkout -b $git_branch

# Remove all files except .git
rm -rf $tmp_dir/*
mv $tmp_dir/.git $tmp_dir/git
rm -rf $tmp_dir/.*
mv $tmp_dir/git $tmp_dir/.git

# Unpack srpm
rpm2cpio $srpm_path > srpm.cpio
cpio -idv < srpm.cpio
rm -f srpm.cpio

# Remove archives
BUNDLE_GEMFILE=/rosa-build/Gemfile bundle exec ruby $script $token $file_store_url

# Commit and push changes
git add -A .
git commit -m "Automatic import for version $version"
git branch $git_branch # Ensure branch exists
git push origin $git_branch

# Cleanup
rm -rf $tmp_dir
