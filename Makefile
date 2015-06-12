# vim:ft=make

.SUFFIXES:
.SUFFIXES:

BUILD:=
CHECK:=
DISTCLEAN:=
MAINTAINERCLEAN:=
PREREQ=

ROLE_FILES=
ROLE_FILES+= $(ROLE_DEFAULTS)
ROLE_FILES+= $(ROLE_TASKS)
ROLE_FILES+= $(ROLE_HANDLERS)

include aux/common.mk
include aux/pip.mk
include aux/ansible.mk
include aux/git.mk

TASK_DIRS:= tasks defaults handlers meta
SUB_ROLES:= base validate_input_parameters

RAW_ROLES=
RAW_ROLES+= $(foreach dir,$(TASK_DIRS),$(subst /$(dir),,$(shell find roles -type d -name '$(dir)')))
RAW_ROLES+= $(foreach dir,$(SUB_ROLES),$(shell find roles -type d -name '$(dir)'))
ROLES:= $(sort $(RAW_ROLES))

ROLE_VARS:= $(addsuffix /vars/main.yml, $(ROLES))
ROLE_DEFAULTS:= $(addsuffix /defaults/main.yml, $(ROLES))
ROLE_TASKS:= $(addsuffix /tasks/main.yml, $(ROLES))
ROLE_HANDLERS:= $(addsuffix /handlers/main.yml, $(ROLES))
ROLE_META:= $(addsuffix /meta/main.yml, $(ROLES))

ROLEBOOKS+= $(addsuffix /role.yml, $(ROLES))
PLAYBOOKS+= $(wildcard *.yml) 

JENKINS_SLAVES=

USER_EXISTS:= $(shell id $(CREATE_USER) > /dev/null 2>&1 ; echo $$?)

$(ROLE_VARS): support/vars.yml
	@if test -f $@; then \
	  $(TOUCH) $< $@; \
	  $(GIT_ADD) $@; \
	else \
	  $(MKDIR_P) $(@D); \
	  $(INSTALL) $< $@; \
	  $(GIT_ADD) $@; \
	fi

$(ROLE_META): support/meta.yml
	@if test -f $@; then \
	  $(TOUCH) $< $@; \
	  $(GIT_ADD) $@; \
	else \
	  $(MKDIR_P) $(@D); \
	  $(INSTALL) $< $@; \
	  $(GIT_ADD) $@; \
	fi

$(ROLE_FILES): support/main.yml
	@if test -f $@; then \
	  $(TOUCH) $< $@; \
	  $(GIT_ADD) $@; \
	else \
	  $(MKDIR_P) $(@D); \
	  $(INSTALL) $< $@; \
	  $(GIT_ADD) $@; \
	fi

$(ROLEBOOKS): support/role.yml $(ROLE_FILES) $(ROLE_META) $(ROLE_VARS)
	@cp $< $@
	@echo "  roles: [ '$(subst roles/,,$(@D))' ]" >> $@

BUILD+= $(ROLEBOOKS)

DIST_MAKEFILES:=

.PHONY: clean
clean:
	@find roles | grep role.yml | xargs rm

.PHONY: distclean
distclean: clean distclean-am

.PHONY: distclean-am
distclean-am:
	@rm -rf $(PREREQ)
	@rm -rf $(DISTCLEAN)

.PHONY: maintainer-clean
maintainer-clean: distclean
	@rm -rf $(MAINTAINERCLEAN)

.PHONY: print_check
print_check:
	@echo "$(CHECK)"
	@echo "$(ROLEBOOKS)"

.PHONY: check
check: all $(CHECK)

PREREQ+= public_keys/$(dirstamp)
public_keys/$(dirstamp):
	@$(MKDIR_P) $(@D)
	@$(TOUCH) $@

PREREQ+= public_keys/deploy
public_keys/deploy: public_keys/$(dirstamp)
	@cp ~/.ssh/id_rsa.pub $@

PREREQ+= public_keys/brian
public_keys/brian: public_keys/$(dirstamp)
	touch $@ 
	curl https://github.com/brianaker.keys >> $@

.PHONY: install
install: all
	$(ANSIBLE_PLAYBOOK) go.yaml

.PHONY: upgrade
upgrade: all
	$(ANSIBLE_PLAYBOOK) maintenance.yml

.PHONY: deploy
deploy: install

all: $(PREREQ) $(ROLE_FILES) $(ROLE_META) $(ROLE_VARS) $(BUILD)

.DEFAULT_GOAL:= all

.NOTPARALLEL:
