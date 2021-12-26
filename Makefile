all:

setup:
	sudo apt-get install -y python3 language-pack-fr
	pip3 install -r requirements.txt

check:
	./graphit.py --help
	:
	tail -1 data.csv
	:
	./graphit.py --noshow 38
	ls -lh 38.png


FONT = Yahfie/Yahfie-Heavy.ttf
ZIPFILE = Yahfie-Normal.font.zip

xkcd.ttf: fontname.py ~/.fonts
	wget https://www.ffonts.net/$(ZIPFILE)
	unzip -p $(ZIPFILE) $(FONT) > $@
	./fontname.py xkcd $@
	cp $@ ~/.fonts/
	rm -f ~/.cache/matplotlib/fontlist-*.json
	rm -f $(ZIPFILE)

fontname.py:
	pip3 install fonttools
	wget https://github.com/chrissimpkins/fontname.py/raw/master/fontname.py
	chmod +x fontname.py

~/.fonts:
	mkdir $@

clean:
	pip uninstall -y fonttools
	rm -f xkcd.ttf fontname.py


depts = \
		31 34 13 42 69 38 76 75 59 \
		33 67 30 73 74 50 06 35 \
		idf pc gc
nonoise = \
		05 04

graphit = ./graphit.py --noshow --round --week --style fast

radar: opts = --two-months
radar:
	for dept in $(nonoise); do \
		$(graphit) $$dept $(opts) & \
	done; \
	for dept in $(depts); do \
		$(graphit) $$dept $(opts) --noise & \
	done; \
	$(graphit) met $(opts) --zoom 350 --noise & \
	$(graphit) met --full & \
	wait

help.fr:
	curl -sL https://github.com/ofa-/graphit/blob/master/help.fr.md \
	| sed '/<article/ s:>:\n:' \
	| sed '1,/<article/ d; /<\/article/,$$ d' \
	| sed 's:<svg.*</svg>::g' \
	> help.fr.md.html


figures = fig s02
figures: $(figures:%=figs.%)

figs.fig: options = --two-months
figs.s01: options = --episode-1
figs.s02: options =
figs.full: options = --full

figs.%:
	for dept in `seq 95 | grep -v 20 | sed '/^.$$/ s/^/0/'` \
			pc gc idf 2A 2B ; \
	do \
		$(graphit) $$dept --noise $(options) & \
	done; \
	$(graphit) met --zoom 350 --noise $(options) & \
	wait ; \
	mkdir -p $* ;\
	mv *.png $* ;\
	git add -f $*/*.png

figures: met-full

%-full:
	$(graphit) $* --full
	mv  $@.png full/
	git add -f full/$@.png

fetch:
	./fetch.sh

wait-for-data.csv:
	while [ `tail -1 data.csv | cut -d ';' -f2` != `date +%F` ]; do \
		sleep 1m	;\
		./fetch.sh	;\
	done

push:
	git config user.name coviiid
	git config user.email coviiid@github.users
	git commit -m "add `date +%F` graphs"
	git push origin HEAD:master


day.dc:
day.dc: day = $(shell tail -1 data.csv | cut -d\; -f2)

%.dc:
	grep $(day) data.csv | grep -v '"97' \
			| cut -f5 -d\; | xargs | tr ' ' + | bc

%.dc: day = $*


insee.%: release = 2021-12-17

insee.diff:
	diff -ru insee_dc.2021-12-10 insee_dc.$(release) |\
	egrep '^\+' | sed '1d' |\
	cut -c 1-8 | uniq -c

insee.fetch:
	: home: https://www.insee.fr/fr/statistiques/4487988
	wget $(insee.url)/$(release)_detail.zip
	mkdir insee_dc.$(release)
	cd insee_dc.$(release); unzip ../$(release)_detail.zip
	rm -f $(release)_detail.zip
	ln -sfT insee_dc.$(release) insee_dc
	[ -f insee_dc/DC_20202021_det.csv ] && \
		mv insee_dc/DC_20202021_det.csv insee_dc/DC_2020_det.csv

insee.url = https://www.insee.fr/fr/statistiques/fichier/4487988

insee.stat:
	./insee_dc.py --baseline-noise
