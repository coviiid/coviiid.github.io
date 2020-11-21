all:

setup:
	sudo apt-get install -y python3 language-pack-fr
	pip3 install -r requirements.txt

check:
	./predictor.py --help
	:
	tail -1 data.csv
	:
	./predictor.py --noshow 38
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
		33 67 30 73 74 50 \
		idf pc gc met
nonoise = \
		05 04

graphit = ./predictor.py --round

curfew:
	unset DISPLAY; \
	for dept in $(nonoise); do \
		$(graphit) $$dept --two-months & \
	done; \
	for dept in $(depts); do \
		$(graphit) $$dept --two-months --noise & \
	done; \
	$(graphit) met --full & \
	wait

help.fr:
	curl -sL https://github.com/ofa-/predictor/blob/master/help.fr.md \
	| sed '/<article/ s:>:\n:' \
	| sed '1,/<article/ d; /<\/article/,$$ d' \
	| sed 's:<svg.*</svg>::g' \
	> help.fr.md.html


figures = fig s01 s02 full
figures: $(figures:%=figs.%)

figs.fig: options = --two-months
figs.s01: options = --episode-1
figs.s02: options =
figs.full: options = --full

figs.%:
	for dept in `seq 95 | sed '/^.$$/ s/^/0/'` \
			met pc gc idf 2A 2B ; \
	do \
		$(graphit) $$dept --noshow $(options) & \
	done; \
	wait ; \
	mkdir -p $* ;\
	mv *.png $* ;\
	git add -f $*/*.png

fetch:
	./fetch.sh

wait-for-data.csv:
	while [ `tail -1 data.csv | cut -d ';' -f2` != `date +%F` ]; do \
		sleep 1m	;\
		./fetch.sh	;\
	done

upload:
	lftp -c "open $(TARGET); mput *.png"

push:
	git config user.name coviiid
	git config user.email coviiid@github.users
	git commit -m "add `date +%F` graphs"
	git push origin HEAD:master
