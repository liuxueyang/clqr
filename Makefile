# Copyright (C) 2008, 2009, 2010, 2011 Bert Burgemeister
#
# Permission is granted to copy, distribute and/or modify this
# document under the terms of the GNU Free Documentation License,
# Version 1.2 or any later version published by the Free Software
# Foundation; with no Invariant Sections, no Front-Cover Texts and
# no Back-Cover Texts. For details see file COPYING.

CLQR		= clqr
SEND-TO-LOG	= | tee -a lastbuild.log

LATEX		= latex 
MAKEINDEX	= makeindex -c
MPOST		= TEX=latex mpost
DVIPS		= dvips
PSNUP-A4	= psnup -W10.5cm -H29.7cm -pa4 -2
PSNUP-LETTER	= psnup -W4.25in -H11in -pletter -2
PSBOOK-ALL	= psbook
PSBOOK-FOUR	= psbook -s4
PS2PDF		= ps2pdf -dPDFSETTINGS=/prepress 
CONVERT		= convert
MONTAGE		= montage
HEAD		= head
TAIL		= tail
TOUCH		= touch
CP		= cp --verbose
RM		= rm --force --verbose
MV		= mv --force --verbose
MAKE		= make
GZIP		= gzip
GIT_REVISION	= git describe | sed 's/\(.*-.*\)-.*/\1/'
GIT_ARCHIVE	= git archive --format=tar --prefix=$(CLQR)/ HEAD | $(GZIP)
GIT_LOG		= git log
DATE		= git log HEAD^..HEAD --date=short | awk '/Date:/{print $$2}' | tr -d '\n\\' 
RSYNC		= rsync -va
SSH		= ssh

all:	letter a4

letter:	 
	$(MAKE) letter-booklets
	$(MAKE) $(CLQR)-letter-consec.pdf

a4:	
	$(MAKE) a4-booklets
	$(MAKE) $(CLQR)-a4-consec.pdf 

letter-booklets:	$(CLQR)-letter-booklet-all.pdf $(CLQR)-letter-booklet-four.pdf

a4-booklets:	 $(CLQR)-a4-booklet-all.pdf $(CLQR)-a4-booklet-four.pdf 

$(CLQR)-%-consec.pdf:	$(CLQR)-%-consec.ps
	$(PS2PDF) $< $@ $(SEND-TO-LOG)

$(CLQR)-letter-booklet-%.pdf:	$(CLQR)-letter-booklet-%.ps
	$(PS2PDF) -sPAPERSIZE=letter $< $@ $(SEND-TO-LOG)

$(CLQR)-a4-booklet-%.pdf:	$(CLQR)-a4-booklet-%.ps
	$(PS2PDF) -sPAPERSIZE=a4 $< $@ $(SEND-TO-LOG)

$(CLQR)-letter-booklet-%.ps:	$(CLQR)-letter-signature-%.ps color-black.flag
	$(PSNUP-LETTER) $< > $@ $(SEND-TO-LOG)

$(CLQR)-a4-booklet-%.ps:	$(CLQR)-a4-signature-%.ps color-black.flag
	$(PSNUP-A4) $< > $@ $(SEND-TO-LOG)

$(CLQR)-%-signature-all.ps:	$(CLQR)-%-consec.ps
	$(PSBOOK-ALL) $< $@ $(SEND-TO-LOG)

$(CLQR)-%-signature-four.ps:	$(CLQR)-%-consec.ps
	$(PSBOOK-FOUR) $< $@ $(SEND-TO-LOG)

$(CLQR)-%-consec.ps:	$(CLQR)-%.dvi color-colorful.flag
	$(DVIPS) -o $@ $< $(SEND-TO-LOG)

$(CLQR)-%.dvi:	$(CLQR).tex $(CLQR)-*.tex $(CLQR).*.tex $(CLQR)-types-and-classes.1 paper-%.flag revision-number
	$(TOUCH) $(CLQR).ind $(SEND-TO-LOG)
	$(LATEX) $(CLQR).tex $(SEND-TO-LOG)
	$(LATEX) $(CLQR).tex $(SEND-TO-LOG)
	$(MAKEINDEX) -s $(CLQR).ist $(CLQR).idx $(SEND-TO-LOG)
	$(LATEX) $(CLQR).tex $(SEND-TO-LOG)
	$(MV) $(CLQR).dvi $@ $(SEND-TO-LOG)

$(CLQR)-types-and-classes.1 $(CLQR)-types-and-classes.2 \
$(CLQR)-types-and-classes.3 $(CLQR)-types-and-classes.4 \
$(CLQR)-types-and-classes.5:	$(CLQR)-types-and-classes.mp $(CLQR).macros.tex clqr.packages.tex
	$(MPOST) $< $(SEND-TO-LOG)

paper-a4.flag:	
	$(CP) paper-a4.tex paper-current.tex $(SEND-TO-LOG)
	$(RM) paper-letter.flag $(SEND-TO-LOG)
	$(TOUCH) $@

paper-letter.flag:	
	$(CP) paper-letter.tex paper-current.tex $(SEND-TO-LOG)
	$(RM) paper-a4.flag $(SEND-TO-LOG)
	$(TOUCH) $@

color-colorful.flag:	
	$(CP) color-colorful.tex color-current.tex $(SEND-TO-LOG)
	$(RM) color-black.flag $(SEND-TO-LOG)
	$(TOUCH) $@

color-black.flag:	
	$(CP) color-black.tex color-current.tex $(SEND-TO-LOG)
	$(RM) color-colorful.flag $(SEND-TO-LOG)
	$(TOUCH) $@

revision-number:
	$(GIT_REVISION) | tee REVISION.tex > html/release-revision.txt
	$(DATE) | tee DATE.tex > html/release-date.txt

clean:
	$(RM) *.dvi *.toc *.aux *.log *.idx *.ilg *.ind *.out *.ps *.pdf *~ html/*~ \
	*.flag *.jpg html/*.jpg *.tar.gz REVISION.tex DATE.tex \
	      html/latest-changes.html html/release-revision.txt html/release-date.txt \
	      *.[12345] *.mpx mpxerr.tex paper-current.tex color-current.tex
	$(RM) -r gh-pages


# Project hosting, Berlios

publish:
	$(MAKE) html/sample-frontcover.jpg \
		html/sample-firstpage-all.jpg html/sample-firstpage-four.jpg \
		html/sample-firstpage-consec.jpg html/sample-source.jpg \
		html/latest-changes.html \
		$(CLQR).tar.gz
	$(MAKE) letter a4
	$(MAKE) publishclean
	$(RSYNC) --delete ./ trebb@shell.berlios.de:/home/groups/ftp/pub/clqr/clqr/ $(SEND-TO-LOG)
	$(RSYNC) ./html/ trebb@shell.berlios.de:/home/groups/clqr/htdocs/ $(SEND-TO-LOG)

html/sample-frontcover.jpg:	$(CLQR)-a4-consec.pdf
	$(CONVERT) $<'[0]' -verbose -resize 40% temp.jpg $(SEND-TO-LOG)
	$(MONTAGE) temp.jpg -tile 1x1 -geometry +1+1 -background gray $@ $(SEND-TO-LOG)
	$(RM) temp.jpg

html/sample-firstpage-%.jpg:	$(CLQR)-a4-booklet-%.pdf
	$(CONVERT) $<'[0]' -verbose -resize 15% temp.jpg $(SEND-TO-LOG)
	$(MONTAGE) temp.jpg -tile 1x1 -geometry +1+1 -background gray $@ $(SEND-TO-LOG)
	$(RM) temp.jpg

html/sample-firstpage-consec.jpg:	$(CLQR)-a4-consec.pdf
	$(CONVERT) $<'[0]' -verbose -resize 15% temp.jpg $(SEND-TO-LOG)
	$(MONTAGE) temp.jpg -tile 1x1 -geometry +1+1 -background gray $@ $(SEND-TO-LOG)
	$(RM) temp.jpg

html/sample-source.jpg:	$(CLQR)-numbers.tex
	$(HEAD) -n 57  $< | $(TAIL) -n 40 | $(CONVERT) -font Courier -crop 120x80+30+2 +repage label:@- temp.jpg $(SEND-TO-LOG)
	$(MONTAGE) temp.jpg -tile 1x1 -geometry +1+1 -background gray $@ $(SEND-TO-LOG)
	$(RM) temp.jpg

html/latest-changes.html:	$(CLQR).tex $(CLQR)-*.tex 
	if $(GIT_LOG) -5 --pretty=format:"<p><i>%ci</i>%n<br />%s%n<br />%b</p>" > $@; then true; else true; fi $(SEND-TO-LOG)

# Github

gh-publish:
	$(RM) -r gh-pages
	mkdir gh-pages
	$(MAKE) gh-pages/$(CLQR)-a4-booklet-all.pdf \
		gh-pages/$(CLQR)-a4-booklet-four.pdf \
		gh-pages/$(CLQR)-a4-consec.pdf \
		gh-pages/$(CLQR)-letter-booklet-all.pdf \
		gh-pages/$(CLQR)-letter-booklet-four.pdf \
		gh-pages/$(CLQR)-letter-consec.pdf \
		gh-pages/sample-frontcover.jpg \
		gh-pages/sample-firstpage-all.jpg \
		gh-pages/sample-firstpage-four.jpg \
		gh-pages/sample-firstpage-consec.jpg \
		gh-pages/sample-source.jpg \
		gh-pages/$(CLQR).tar.gz \
		gh-pages/404.html \
		gh-pages/CNAME \
		gh-pages/README \
		gh-pages/download.html \
		gh-pages/favicon.ico \
		gh-pages/index.html \
		gh-pages/license.html \
		gh-pages/new-pure.css \
		gh-pages/printing.html \
		gh-pages/robots.txt \
		gh-pages/source.html
	cd gh-pages; git init; git add ./; git commit -a -m "gh-pages pseudo commit"; git push git@github.com:trebb/clqr.git +master:gh-pages

gh-pages/sample-%.jpg: html/sample-%.jpg
	$(CP) $< $@

gh-pages/index.html: html-template/index.html html/latest-changes.html
	sed -e "/<h3>Latest Changes<\/h3>/ r html/latest-changes.html" html-template/index.html > $@

gh-pages/download.html: html-template/download.html revision-number
	sed -e "/This is revision/ r REVISION.tex" -e "/<!- date of commit \/>/ r DATE.tex" html-template/download.html > $@

gh-pages/%.pdf: %.pdf
	$(CP) $< $@

gh-pages/%.tar.gz: %.tar.gz
	$(CP) $< $@

gh-pages/%: html-template/%
	$(CP) $< $@

$(CLQR).tar.gz:	$(CLQR).tex $(CLQR)-*.tex 
	if $(GIT_ARCHIVE) > $(CLQR).tar.gz; then true; else true; fi $(SEND-TO-LOG)

publishclean:
	$(RM) $(CLQR).{aux,idx,ilg,ind,log,out,toc} *.ps *.dvi $(CLQR)-types-and-classes.{log,mpx,1,2,3,4,5} *~ html/*~
