===================== Setup gitolite

--------------- As root (sudo su -) on server

* urpmi.addmedia --distrib --mirrorlist '$MIRRORLIST'
* urpmi git
* useradd git
* passwd git

--------------- As user who will manage gitolite

* scp -o preferredauthentications=password ~/.ssh/id_rsa.pub git@gitolite:/tmp/ga_admin.pub

--------------- As git user (su - git) on server

* git clone git://github.com/sitaramc/gitolite
* cd gitolite
* src/gl-system-install
* gl-setup /tmp/ga_admin.pub

--------------- As user who will manage gitolite

* cd /share # /var/rosa
* git clone git@gitolite:gitolite-admin
* ln -s /home/git/repositories git_projects
* sudo chmod -R +r /home/git/repositories

--------------- Settings for .gitolite.rc

* $REPO_UMASK = 0022;

--------------- Setup hooks

* cd /home/git/.gitolite/hooks/common
* mv update.secondary.sample update.secondary
* mkdir update.secondary.d
* touch update.secondary.d/update.auto-build
* chmod +x update.secondary update.secondary.d/update.auto-build
