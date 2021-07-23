XML2RFC_CACHE_DIR ?= $(HOME)/.cache/xml2rfc

TOOL_PREFIX        = $(DOCKER) run --rm --user=`id -u`:`id -g` -v `pwd`:/rfc -v $(XML2RFC_CACHE_DIR):/var/cache/xml2rfc paulej/rfctools:8

DOCKER            ?= docker
MD2RFC            ?= $(TOOL_PREFIX) md2rfc
XML2RFC           ?= $(TOOL_PREFIX) xml2rfc
MMARK             ?= $(TOOL_PREFIX) mmark
SED               ?= sed
RM_F		      ?= rm -f
MKDIR_P		      ?= mkdir -p

SOURCE_DATE       := $(shell (TZ=UTC git log -n 1 --date=iso-strict-local --pretty=format:%ad 2> /dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ" ) | sed 's/+00:00$$/Z/')
SOURCE_VERSION    := $(shell git describe --dirty --always --match "--PoIsOn--" 2> /dev/null)

# -------------

SRC   := n6drc-arngll.md
XML   := $(patsubst %.md,%.xml,$(patsubst %.md.in,%.xml,$(SRC)))
TXT   := $(patsubst %.md,%.txt,$(patsubst %.md.in,%.txt,$(SRC)))
HTML  := $(patsubst %.md,%.html,$(patsubst %.md.in,%.html,$(SRC)))

all: $(XML) $(TXT) $(HTML)

clean:
	$(RM_F) $(XML) $(TXT) $(HTML) $(patsubst %.md.in,%.md,$(wildcard draft-*.md.in))

$(XML2RFC_CACHE_DIR):
	$(MKDIR_P) "$(XML2RFC_CACHE_DIR)"

%.md: %.md.in
	$(SED) 's/@SOURCE_VERSION@/$(SOURCE_VERSION)/g;s/@SOURCE_DATE@/$(SOURCE_DATE)/g' < $< > $@

%.xml: %.md
	$(MMARK) -2 $< | sed 's/<note anchor="[^"]*"/<note/;s/<?rfc toc="yes"?>/<?rfc toc="yes"?><?rfc private="yes"?>/' > $@

%.html: %.xml $(XML2RFC_CACHE_DIR)
	$(XML2RFC) --html $<

%.txt: %.xml $(XML2RFC_CACHE_DIR)
	$(XML2RFC) --text $<

# -------------

n6drc-arngll.xml: \
	n6drc-arngll.md \
	$(NULL)
