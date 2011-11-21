for f in `ls /srv/rosa_build/current/tmp/mount`
do
  mkdir "/srv/rosa_build/shared/downloads/$f"
  mount --bind "/home/share/platforms/$f" "/srv/rosa_build/shared/downloads/$f"
  rm -f "/srv/rosa_build/current/tmp/mount/$f"
done