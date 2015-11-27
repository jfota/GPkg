
# Implicit targets
SHELL := /bin/bash

# Download
$(BUILD_DIR)/%/.download:
	mkdir -p $($(PKG)_INSTALL_DIR) $($(PKG)_DL_DIR)
	cd $($(PKG)_DL_DIR) && git clone $(GITHUB_REPO)/$($(PKG)_REPO_NAME).git .
	cd $($(PKG)_DL_DIR) && git checkout $($(PKG)_BRANCH_NAME)
	touch $@

#
# Make binary tar
#
$(BUILD_DIR)/%/.tar.gz:
	cd $($(PKG)_PACKAGE_DIR)/ && tar -cvzf $(DIST_DIR)/$($(PKG)_NAME)-$($(PKG)_PKG_VERSION).$(TIMESTAMP).tar.gz *

#
# Make binary RPMs
#
$(BUILD_DIR)/%/.rpm:
	mkdir -p $($(PKG)_RPDIR)/{SPECS,INSTALL,SOURCES,BUILD,RPMS/noarch} $(DIST_DIR)
	mv $($(PKG)_PACKAGE_DIR)/* $($(PKG)_RPDIR)/SOURCES/
	cp -r $($(PKG)_RPSPECS)/*.spec $($(PKG)_RPDIR)/SPECS
	find $($(PKG)_RPDIR)/SPECS -type f -exec \
		sed -i 's|__PREFIX__|$(INSTALLATION_PREFIX)|g' {} \;
	find $($(PKG)_RPDIR)/SPECS -type f -exec \
		sed -i 's|__VERSION__|$($(PKG)_PKG_VERSION)|g' {} \;
	find $($(PKG)_RPDIR)/SPECS -type f -exec \
		sed -i 's|__HADOOP_VERSION_0__|$(HADOOP_VERSION_0)|g' {} \;
	find $($(PKG)_RPDIR)/SPECS -type f -exec \
		sed -i 's|__HADOOP_VERSION_1__|$(HADOOP_VERSION_1)|g' {} \;
	find $($(PKG)_RPDIR)/SPECS -type f -exec \
		sed -i 's|__RELEASE_BRANCH__|$($(PKG)_BRANCH_NAME)\n|g' {} \;
	find $($(PKG)_RPDIR)/SPECS -type f -exec \
		sed -i 's|__RELEASE_VERSION__|$($(PKG)_PKG_VERSION).$(TIMESTAMP)|g' {} \;
	find $($(PKG)_RPDIR)/SPECS -type f -exec \
		sed -i 's|__INSTALL__|$(INSTALLATION_PREFIX)/$($(PKG)_PKG_NAME)/$($(PKG)_PKG_NAME)-$($(PKG)_PKG_VERSION)|g' {} \;
	rpmbuild --bb --define "_topdir $($(PKG)_RPDIR)" \
		--buildroot=$($(PKG)_RPDIR)/SOURCES \
		$($(PKG)_RPDIR)/SPECS/*
	mv $($(PKG)_RPDIR)/RPMS/*/*rpm $(DIST_DIR)
	touch $@ 

#
# Make binary DEBIANs
#
$(BUILD_DIR)/%/.deb:
	mkdir -p $($(PKG)_DEB_DIR) $(DIST_DIR)
	cp -r $($(PKG)_DEB_SPECS)/* $($(PKG)_DEB_DIR) 
	find $($(PKG)_DEB_DIR) -type f -exec \
		sed -i 's|__PREFIX__|$(INSTALLATION_PREFIX)|g' {} \;
	find $($(PKG)_DEB_DIR) -type f -exec \
		sed -i 's|__VERSION__|$($(PKG)_PKG_VERSION)|g' {} \;
	find $($(PKG)_DEB_DIR) -type f -exec \
		sed -i 's|__HADOOP_VERSION_0__|$(HADOOP_VERSION_0)|g' {} \;
	find $($(PKG)_DEB_DIR) -type f -exec \
		sed -i 's|__HADOOP_VERSION_1__|$(HADOOP_VERSION_1)|g' {} \;
	find $($(PKG)_DEB_DIR) -type f -exec \
		sed -i 's|__RELEASE_BRANCH__|$($(PKG)_BRANCH_NAME)\n|g' {} \;
	find $($(PKG)_DEB_DIR) -type f -exec \
		sed -i 's|__RELEASE_VERSION__|$($(PKG)_PKG_VERSION).$(TIMESTAMP)|g' {} \;
	find $($(PKG)_DEB_DIR) -type f -exec \
		sed -i 's|__INSTALL__|$(INSTALLATION_PREFIX)/$($(PKG)_PKG_NAME)/$($(PKG)_PKG_NAME)-$($(PKG)_PKG_VERSION)|g' {} \;
	find $(@D)/package -type f -exec md5sum \{\} \; 2> /dev/null | \
                sed -e "s|$(@D)/package||" -e "s| \/| |" | \
                grep -v DEBIAN > $($(PKG)_DEB_DIR)/md5sums
	fakeroot dpkg-deb --build $(@D)/package $(DIST_DIR)
	touch $@


##
## Package make function
##
# $1 is the target prefix, $2 is the variable prefix
define PACKAGE

# The default PKG_NAME will be the target prefix
$(2)_NAME           ?= $(1)

# For deb packages, the name of the package itself
$(2)_PKG_NAME       ?= $$($(2)_NAME)

# The default PKG_RELEASE will be 1 unless specified
$(2)_RELEASE        ?= 1

$(2)_BUILD_DIR      = $(BUILD_DIR)/$(1)
$(2)_PACKAGE_DIR    = $(BUILD_DIR)/$(1)/package
$(2)_INSTALL_DIR    = $(BUILD_DIR)/$(1)/package$(INSTALLATION_PREFIX)/$($(2)_PKG_NAME)/$($(2)_PKG_NAME)-$($(2)_PKG_VERSION)
$(2)_DEB_DIR        = $(BUILD_DIR)/$(1)/package/DEBIAN
$(2)_RPDIR        = $(BUILD_DIR)/$(1)/rpm
$(2)_DEB_SPECS      = $(BASE_DIR)/specs/$(1)/deb
$(2)_RPSPECS      = $(BASE_DIR)/specs/$(1)/rpm
$(2)_OUTPUT_DIR     = $(OUTPUT_DIR)/$(1)
$(2)_DL_DIR         = $(DL_DIR)/$(1)
$(2)_SOURCE_DIR     = $$($(2)_BUILD_DIR)/source


# Define the file stamps
$(2)_TARGET_DL       = $$($(2)_BUILD_DIR)/.download
$(2)_TARGET_BUILD    = $$($(2)_BUILD_DIR)/.build
$(2)_TARGET_DEB      = $$($(2)_BUILD_DIR)/.deb
$(2)_TARGET_RPM      = $$($(2)_BUILD_DIR)/.rpm
$(2)_TARGET_TAR      = $$($(2)_BUILD_DIR)/.tar.gz
$(2)_TARGET_DEPLOY   = $$($(2)_BUILD_DIR)/.deploy

# We download target when the source is not in the download directory
$(1)-download: $$($(2)_TARGET_DL)

# build target
$(1)-build: $$($(2)_TARGET_BUILD)

# Create a *.tar.gz package
$(1)-tar.gz: $(1)-download $$($(2)_TARGET_BUILD) $$($(2)_TARGET_TAR)

# Create a *.rpm package
$(1)-rpm: $(1)-download $$($(2)_TARGET_BUILD) $$($(2)_TARGET_RPM)

# Create a *.deb package
$(1)-deb: $(1)-download $$($(2)_TARGET_BUILD) $$($(2)_TARGET_DEB)

# Deploy artifacts to Maven repo
$(1)-deploy: $(1)-download $$($(2)_TARGET_BUILD) $$($(2)_TARGET_DEPLOY)

$(1): $(1)-$(PACKAGE)

####
# Helper targets -version -help etc
$(1)-version:
	@echo "Base: $$($(2)_PKG_VERSION)"

$(1)-help:
	@awk 'BEGIN {printf ("  %-25s [ %s, %s, %s,\n%-29s %s, %s, %s ]\n", "$(1)", "$(1)", "$(1)-clean", "$(1)-clobber", "", "$(1)-deploy", "$(1)-info", "$(1)-version" ) }'

$(1)-clean:
	rm -rf $(BUILD_DIR)/$(1)/.{build,deb,rpm,deploy} $(DIST_DIR)/$(1)*

$(1)-clobber:
	rm -rf $(BUILD_DIR)/$(1) $(DL_DIR)/$(1) $(DIST_DIR)/$(1)*

$(1)-info:
	@echo "Definitions for package $(1):"
	@echo
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_NAME",            "$$($(2)_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_REPO_NAME",       "$$($(2)_REPO_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_VERSION",         "$$($(2)_VERSION)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_RELEASE_VERSION", "$$($(2)_RELEASE_VERSION)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_PKG_NAME",        "$$($(2)_PKG_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_PKG_VERSION",     "$$($(2)_PKG_VERSION)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2) GIT REPO",        "$(GITHUB_REPO)/$$($(2)_REPO_NAME).git" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_BRANCH_NAME",     "$$($(2)_BRANCH_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_IMAGE_NAME",      "$$($(2)_IMAGE_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_IMAGE_DIST",      "$$($(2)_IMAGE_DIST)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_PACKAGE_DIR",     "$$($(2)_PACKAGE_DIR)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_INSTALL_DIR",     "$$($(2)_INSTALL_DIR)" ) }'
	@echo


$(1)-macros:
	@echo
	@echo "Macros for package $(1):"
	@echo
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__PREFIX__",           "$(INSTALLATION_PREFIX)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__VERSION__",          "$$($(2)_PKG_VERSION)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__HADOOP_VERSION_0__", "$(HADOOP_VERSION_0)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__HADOOP_VERSION_1__", "$(HADOOP_VERSION_1)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__RELEASE_BRANCH__",   "$$($(2)_BRANCH_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__RELEASE_VERSION__",  "$$($(2)_PKG_VERSION).$(TIMESTAMP)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__INSTALL__",          "$(INSTALLATION_PREFIX)/$$($(2)_PKG_NAME)/$$($(2)_PKG_NAME)-$$($(2)_PKG_VERSION)" ) }'
	@echo


# Implicit rules with PKG variable
$$($(2)_TARGET_DL): PKG=$(2)
$$($(2)_TARGET_TAR) $$($(2)_TARGET_RPM) $$($(2)_TARGET_DEB): PKG=$(2)
$$($(2)_TARGET_TAR) $$($(2)_TARGET_RPM) $$($(2)_TARGET_DEB): PKG_BASE_VERSION=$$($(2)_PKG_VERSION)
$$($(2)_TARGET_TAR) $$($(2)_TARGET_RPM) $$($(2)_TARGET_DEB): PKG_PKG_VERSION=$$($(2)_PKG_VERSION)
$$($(2)_TARGET_TAR) $$($(2)_TARGET_RPM) $$($(2)_TARGET_DEB): PKG_BUILD_DIR=$$($(2)_BUILD_DIR)


TARGETS += $(1)
TARGETS_DEB += $(1)-deb
TARGETS_RPM += $(1)-rpm
TARGETS_TAR += $(1)-tar.gz
TARGETS_HELP += $(1)-help
TARGETS_CLEAN += $(1)-clean
TARGETS_DEPLOY += $(1)-deploy

endef



##
## Role packages
## 
# $1 is the target prefix, $2 is the variable prefix
define ROLES

# The default PKG_NAME will be the target prefix
$(2)_NAME           ?= $(1)

# For deb packages, the name of the package itself
$(2)_PKG_NAME       ?= $$($(2)_NAME)

# The default PKG_RELEASE will be 1 unless specified
$(2)_RELEASE        ?= 1

$(2)_BUILD_DIR      = $(BUILD_DIR)/$(1)
$(2)_PACKAGE_DIR    = $(BUILD_DIR)/$(1)/package
$(2)_INSTALL_DIR    = $(BUILD_DIR)/$(1)/package$(INSTALLATION_PREFIX)/$($(2)_PKG_NAME)/$($(2)_PKG_NAME)-$($(2)_PKG_VERSION)
$(2)_DEB_DIR        = $(BUILD_DIR)/$(1)/package/DEBIAN
$(2)_RPDIR        = $(BUILD_DIR)/$(1)/rpm
$(2)_DEB_SPECS      = $(BASE_DIR)/specs/$(1)/deb
$(2)_RPSPECS      = $(BASE_DIR)/specs/$(1)/rpm
$(2)_OUTPUT_DIR     = $(OUTPUT_DIR)/$(1)
$(2)_DL_DIR         = $(DL_DIR)/$(1)

# Define the file stamps
$(2)_TARGET_BUILD   = $$($(2)_BUILD_DIR)/.build
$(2)_TARGET_DEB     = $$($(2)_BUILD_DIR)/.deb
$(2)_TARGET_RPM     = $$($(2)_BUILD_DIR)/.rpm
$(2)_TARGET_TAR     = $$($(2)_BUILD_DIR)/.tar.gz

# build target
$(1)-build:  $$($(2)_TARGET_BUILD)

# Create a *.tar.gz package
$(1)-tar.gz: $$($(2)_TARGET_BUILD) $$($(2)_TARGET_TAR)

# Create a *.rpm package
$(1)-rpm: $$($(2)_TARGET_BUILD) $$($(2)_TARGET_RPM)

# Create a *.deb package
$(1)-deb: $$($(2)_TARGET_BUILD) $$($(2)_TARGET_DEB)

$(1): $(1)-$(PACKAGE)

####
# Helper targets -version -help etc
$(1)-version:
	@echo "Base: $$($(2)_PKG_VERSION)"

$(1)-help:
	@awk 'BEGIN {printf ("  %-25s [ %s, %s, \n%-29s %s, %s, %s ]\n", "$(1)", "$(1)", "$(1)-clean", "", "$(1)-clobber", "$(1)-version", "$(1)-info" ) }'

$(1)-clean:
	rm -rf $(BUILD_DIR)/$(1) $(DIST_DIR)/$(1)*

$(1)-clobber:
	rm -rf $(BUILD_DIR)/$(1) $(DL_DIR)/$(1) $(DIST_DIR)/$(1)*

$(1)-info:
	@echo "Definitions for package $(1):"
	@echo
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_NAME",            "$$($(2)_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_VERSION",         "$$($(2)_VERSION)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_RELEASE_VERSION", "$$($(2)_RELEASE_VERSION)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_PKG_NAME",        "$$($(2)_PKG_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_PKG_VERSION",     "$$($(2)_PKG_VERSION)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_BUILD_DIR",       "$$($(2)_BUILD_DIR)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_PACKAGE_DIR",     "$$($(2)_PACKAGE_DIR)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "$(2)_INSTALL_DIR",     "$$($(2)_INSTALL_DIR)" ) }'
	@echo

$(1)-macros:
	@echo
	@echo "Macros for package $(1):"
	@echo
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__PREFIX__",           "$(INSTALLATION_PREFIX)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__VERSION__",          "$$($(2)_PKG_VERSION)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__HADOOP_VERSION_0__", "$(HADOOP_VERSION_0)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__HADOOP_VERSION_1__", "$(HADOOP_VERSION_1)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__RELEASE_BRANCH__",   "$$($(2)_BRANCH_NAME)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__RELEASE_VERSION__",  "$$($(2)_PKG_VERSION).$(TIMESTAMP)" ) }'
	@awk 'BEGIN {printf ("  %-30s: %s\n", "__INSTALL__",          "$(INSTALLATION_PREFIX)/$$($(2)_PKG_NAME)/$$($(2)_PKG_NAME)-$$($(2)_PKG_VERSION)" ) }'
	@echo


# Implicit rules with PKG variable
$$($(2)_TARGET_TAR) $$($(2)_TARGET_RPM) $$($(2)_TARGET_DEB): PKG=$(2)
$$($(2)_TARGET_TAR) $$($(2)_TARGET_RPM) $$($(2)_TARGET_DEB): PKG_BASE_VERSION=$$($(2)_VERSION)
$$($(2)_TARGET_TAR) $$($(2)_TARGET_RPM) $$($(2)_TARGET_DEB): PKG_PKG_VERSION=$$($(2)_PKG_VERSION)
$$($(2)_TARGET_TAR) $$($(2)_TARGET_RPM) $$($(2)_TARGET_DEB): PKG_BUILD_DIR=$$($(2)_BUILD_DIR)

TARGETS += $(1)
TARGETS_DEB += $(1)-deb
TARGETS_RPM += $(1)-rpm
TARGETS_TAR += $(1)-tar.gz
TARGETS_HELP += $(1)-help
TARGETS_CLEAN += $(1)-clean

endef
