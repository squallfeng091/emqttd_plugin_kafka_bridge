# rebar3 logic by Bjorn-Egil Dahlberg
# https://gist.github.com/psyeugenic/d2d53a15463b218fd20c2fe7fd73ced0
REBAR3_URL=https://s3.amazonaws.com/rebar3/rebar3

ifeq ($(wildcard rebar3),rebar3)
REBAR3 = $(CURDIR)/rebar3
endif

REBAR3 ?= $(shell test -e `which rebar3` 2>/dev/null && which rebar3 || echo "./rebar3")

ifeq ($(REBAR3),)
REBAR3 = $(CURDIR)/rebar3
endif

.PHONY: deps test build

build: $(REBAR3)
	@$(REBAR3) compile

$(REBAR3):
	wget $(REBAR3_URL) || curl -Lo rebar3 $(REBAR3_URL)
	@chmod a+x rebar3

upgrade:
	@$(REBAR3) upgrade

deps:
	@$(REBAR3) get-deps

clean:
	@$(REBAR3) clean

distclean: clean
	@$(REBAR3) delete-deps

test:
	@$(REBAR3) eunit

xref:
	@$(REBAR3) xref

ct:
	@$(REBAR3) ct

dialyzer:
	@$(REBAR3) dialyzer

release:
	@$(REBAR3) release

dist:
	@$(REBAR3) tar

# end of file
