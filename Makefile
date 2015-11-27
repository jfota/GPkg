BASE_DIR     := $(shell sh -c 'pwd')
DL_DIR       ?= $(BASE_DIR)/dl
DIST_DIR     ?= $(BASE_DIR)/dist
BUILD_DIR    ?= $(BASE_DIR)/build
OUTPUT_DIR   ?= $(BASE_DIR)/output
PROFILES_DIR ?= $(BASE_DIR)/profiles



REQUIRED_DIRS = $(DL_DIR) $(DIST_DIR) $(BUILD_DIR)
_MKDIRS :=$(shell for d in $(REQUIRED_DIRS); \
	do                               \
		[ -d $$d ] || mkdir -p $$d;  \
	done)

TARGETS:=
TARGETS_HELP:=
TARGETS_CLEAN:=

#
# Include the common rules, definitions and functions for building packages
#
include $(BASE_DIR)/commonrules.mk
include $(BASE_DIR)/commondefs.mk

#
# ecosystem product profile
#
PROFILE=$(MAKECMDGOALS)

ifneq (,$(findstring deb, $(MAKECMDGOALS)))
    PROFILE=$(subst -deb,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring rpm, $(MAKECMDGOALS)))
    PROFILE=$(subst -rpm,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring help, $(MAKECMDGOALS)))
    PROFILE=$(subst -help,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring info, $(MAKECMDGOALS)))
    PROFILE=$(subst -info,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring clean, $(MAKECMDGOALS)))
    PROFILE=$(subst -clean,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring tar.gz, $(MAKECMDGOALS)))
    PROFILE=$(subst -tar.gz,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring macros, $(MAKECMDGOALS)))
    PROFILE=$(subst -macros,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring version, $(MAKECMDGOALS)))
    PROFILE=$(subst -version,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring clobber, $(MAKECMDGOALS)))
    PROFILE=$(subst -clobber,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring download, $(MAKECMDGOALS)))
    PROFILE=$(subst -download,,$(MAKECMDGOALS))
endif
ifneq (,$(findstring deploy, $(MAKECMDGOALS)))
    PROFILE=$(subst -deploy,,$(MAKECMDGOALS))
endif


ifneq ($(words $(PROFILE)), 0)
     include $(BASE_DIR)/profiles/$(PROFILE).mk
else
     help:
endif




.PHONY: help
help: package-help

packages: $(TARGETS)

.PHONY: help-header
help-header:
	@echo -e "targets:"
	@awk 'BEGIN {printf ("  %-10s (remove build/output dirs)\n", "*-clean" ) }'
	@awk 'BEGIN {printf ("  %-10s (remove build/output/dl dirs)\n", "*-clobber" ) }'
	@awk 'BEGIN {printf ("  %-10s (deploy build artifacts)\n", "*-deploy" ) }'
	@awk 'BEGIN {printf ("  %-10s (display profile information)\n", "*-info" ) }'
	@awk 'BEGIN {printf ("  %-10s (display base version)\n", "*-version" ) }'
	@echo

.PHONY: package-help
package-help: help-header $(TARGETS_HELP)
	@for profile in $(shell ls -1 $(BASE_DIR)/profiles/*.mk | sed -e "s|.mk||" | tr '\n' ' ' | xargs -n1 basename); do \
		$(MAKE) $${profile}-help --no-print-directory; \
        done ; 

.PHONY: clean
clean: $(TARGETS_CLEAN)
	-rm -rf $(DIST_DIR)
	-rm -rf $(BUILD_DIR)

.PHONY: clobber
clobber: clean
	-rm -rf $(DL_DIR)

.PHONE: defs
defs:
	@echo
	@awk 'BEGIN {printf ("  %-30s: %s\n", "INSTALLATION_PREFIX", "$(INSTALLATION_PREFIX)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "TIMESTAMP",           "$(TIMESTAMP)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "GITHUB_REPO",         "$(GITHUB_REPO)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "HADOOP_VERSION_0",    "$(HADOOP_VERSION_0)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "HADOOP_VERSION_1 ",   "$(HADOOP_VERSION_1)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "M_PACKAGE",           "$(M_PACKAGE)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "M_PLATFORM",          "$(M_PLATFORM)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "M_HARDWARE",          "$(M_HARDWARE)" ) }'
	@echo


deb: $(TARGETS_DEB)

rpm: $(TARGETS_RPM)

tar: $(TARGETS_TAR)

#
# noop build.
#
$(BUILD_DIR)/noop-0.0/.build:
	mkdir -p $(NOOP_INSTALL_DIR)/
	touch $(NOOP_INSTALL_DIR)/noop
	touch $@



.DEFAULT_GOAL:= help
