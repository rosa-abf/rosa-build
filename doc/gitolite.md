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

* git clone git@gitolite:gitolite-admin
