find ../live-bootstrap -type f -name sources | sed -E 's@^../live-bootstrap/@@' | xargs dirname | sort -u | xargs mkdir -p
find ../live-bootstrap -type f -name sources | sed -E 's@^(../live-bootstrap/)(.*)@cp \1\2 \2@' | sh -
for sources in $(find -type f -name sources); do
	mv $sources ${sources}.bak
	cat ${sources}.bak | sed -E 's@^git://[^ ]+ +(http)@\1@;s@[^ ]+/([^ /]+) _? ?(.*)@\2 \1@;s@([^ ]+) +([^ ]+).*@\2 \1 \2@' | awk '{gsub(/\?/, "%3F", $1); print}' | sed 's@^@https://s3.eu-central-2.wasabisys.com/nixos-bootstrap-distfiles/@' > $sources
	rm ${sources}.bak
done
