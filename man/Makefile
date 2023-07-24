# Makefile
#
# bats-core manpages
#
RONN := ronn -W
PAGES := bats.1 bats.7 bats.1.gz bats.7.gz
ORG := bats-core
MANUAL := 'Bash Automated Testing System'
ISOFMT := $(shell date -I)
RM := rm -f

.PHONY: all clean

all: $(PAGES)

bats.1: bats.1.ronn
	$(RONN) --date=$(ISOFMT) --manual=$(MANUAL) --organization=$(ORG) --roff $<

bats.7: bats.7.ronn
	$(RONN) --date=$(ISOFMT) --manual=$(MANUAL) --organization=$(ORG) --roff $<

bats.1.gz: bats.1
	gzip -k $<

bats.7.gz: bats.7
	gzip -k $<

clean:
	$(RM) $(PAGES)
