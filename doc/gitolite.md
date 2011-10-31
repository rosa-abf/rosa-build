===================== Setup gitolite

--------------- As root (sudo su -) on server

* urpmi.addmedia --distrib --mirrorlist '$MIRRORLIST'
* urpmi git
* useradd git
* passwd git
* mkdir /share/git_projects
* sudo chown git:git /share/git_projects

--------------- As user who will manage gitolite

* scp -o preferredauthentications=password ~/.ssh/id_rsa.pub git@gitolite:/tmp/ga_admin.pub

--------------- As git user (su - git) on server

* git clone git://github.com/sitaramc/gitolite
* cd gitolite
* src/gl-system-install
* gl-setup ~/ga_admin.pub # /tmp/ga_admin.pub

--------------- Settings for .gitolite.rc during install

* $REPO_UMASK = 0022;
* $REPO_BASE = "/home/share/git_projects";
* $GIT_PATH = "/opt/local/bin"; # if you have several git versions

--------------- As user who will manage gitolite

* cd /share # /var/rosa
* git clone git@localhost:gitolite-admin

--------------- Setup hooks

* cd /home/git/.gitolite/hooks/common
* mv update.secondary.sample update.secondary
* mkdir update.secondary.d
* touch update.secondary.d/update.auto-build
* chmod +x update.secondary update.secondary.d/update.auto-build
* gl-setup

--------------- Code for update.auto-build

#!/bin/sh
if [ "$GL_REPO" != "gitolite-admin" ]; then
  curl "http://localhost:3000/projects/auto_build?git_repo=$GL_REPO&git_user=$GL_USER"
fi
