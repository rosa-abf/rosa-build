for f in `ls /srv/rosa_build/current/tmp/mount`
do
  mkdir "/srv/rosa_build/shared/downloads/$f"
  mount --bind "/home/share/platforms/$f" "/srv/rosa_build/shared/downloads/$f"
  mv -f "/srv/rosa_build/current/tmp/mount/$f/*" "/home/share/platforms/$f"
  rm -Rf "/srv/rosa_build/current/tmp/mount/$f"
done