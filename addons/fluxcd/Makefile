mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
current_dir_abs := $(dir $(mkfile_path))

ifeq ("", "$(wildcard $(which go)} )")
	export OS=$(shell uname -s | tr '[:upper:]' '[:lower:]' )
    export ARCH=$(shell uname -m | tr '[:upper:]' '[:lower:]' )
else
    export OS=$(shell go env GOOS)
    export ARCH=$(shell go env GOARCH)
endif
ifeq ("x86_64", "${ARCH}")
    export ARCH="amd64"
endif

GIT_COMMIT		:= $(shell git describe --dirty=-unsupported --always --tags || echo pre-commit)
ADDON_VERSION 	?= $(GIT_COMMIT)


# fluxcd component versions
HELM_CONTROLLER_VERSION				?= v0.24.0
IMAGE_AUTOMATION_CONTROLLER_VERSION	?= v0.25.0
IMAGE_REFLECTOR_CONTROLLER_VERSION	?= v0.22.0
KUSTOMIZE_CONTROLLER_VERSION		?= v0.20.0
SOURCE_CONTROLLER_VERSION			?= v0.29.0

CONTROLLERS := helm-controller image-automation-controller image-reflector-controller kustomize-controller source-controller

export KUBEVELA_VERSION=v1.5.6
export KUBEVELA ?= $(shell which vela)
ifeq ("", "$(wildcard ${KUBEVELA})")
export KUBEVELA = ${current_dir_abs}/.bin/vela
endif

export YQ_VERSION=v4.27.5
export YQ ?= $(shell which yq)
ifeq ("", "$(wildcard ${YQ})")
export YQ = ${current_dir_abs}.bin/yq
endif

.DEFAULT_GOAL: addon

.build:
	mkdir -p .build/

.bin:
	mkdir -p .bin/

.PROXY: clean
clean: clean-build clean-assets

.PROXY: clean-build
clean-build:
	rm -rf .build/

.PROXY: clean-assets
clean-assets:
	rm -rf .bin/

# #$(CONTROLLERS): .build #
# 	$(eval CONTROLLER_PACKAGE_NAME := $(shell echo '$@' | tr '[:upper:]' '[:lower:]' | tr '-' '_'))
# 	$(eval CONTROLLER_NAME := $(shell echo '$@' | tr '[:lower:]' '[:upper:]' | tr '-' '_'))
# 	$(eval CONTROLLER_VERSION := $(${CONTROLLER_NAME}_VERSION))
# 	$(eval COMPONENT_PATH := .build/${ADDON_VERSION}/resources/components/$@)
# 	mkdir -p ${COMPONENT_PATH}
# 	curl --location https://github.com/fluxcd/$@/releases/download/$(CONTROLLER_VERSION)/$@.crds.yaml -o ${COMPONENT_PATH}/crds.yaml
# 	curl --location https://github.com/fluxcd/$@/releases/download/$(CONTROLLER_VERSION)/$@.deployment.yaml -o ${COMPONENT_PATH}/deployment.yaml
#	$(eval CONTROLLER_NAME := $(shell echo '$*' | tr '[:lower:]' '[:upper:]' | tr '-' '_'))
#	$(eval CONTROLLER_VERSION := $(${CONTROLLER_NAME}_VERSION))

$(CONTROLLERS): %: .build/${ADDON_VERSION}/downloads/crds/%.yaml
$(CONTROLLERS): %: .build/${ADDON_VERSION}/downloads/deployments/%.yaml

.build/${ADDON_VERSION}/downloads/crds/%.yaml .build/${ADDON_VERSION}/downloads/deployments/%.yaml:
	$(eval CONTROLLER_NAME := $(shell echo '$*' | tr '[:lower:]' '[:upper:]' | tr '-' '_'))
	$(eval CONTROLLER_VERSION := $(${CONTROLLER_NAME}_VERSION))
	echo "Downloading files for ${CONTROLLER_NAME} ${CONTROLLER_VERSION}"
	mkdir -p .build/${ADDON_VERSION}/downloads/crds
	mkdir -p .build/${ADDON_VERSION}/downloads/deployments
	curl --location https://github.com/fluxcd/$*/releases/download/$(CONTROLLER_VERSION)/$*.crds.yaml -o .build/${ADDON_VERSION}/downloads/crds/$*.yaml
	curl --location https://github.com/fluxcd/$*/releases/download/$(CONTROLLER_VERSION)/$*.deployment.yaml -o .build/${ADDON_VERSION}/downloads/deployments/$*.yaml

.build/${ADDON_VERSION}/fluxcd-${ADDON_VERSION}: $(CONTROLLERS)
	mkdir -p .build/${ADDON_VERSION}/fluxcd-${ADDON_VERSION}/resources/crds/

	cd .build/${ADDON_VERSION}/downloads/crds/ && \
	cue import *.yaml -p main -l 'strings.ToCamel(strings.Split(metadata.name, ".")[0]+kind)' -f -R && \
	cue fmt ./... && \
	mv *.cue ../../fluxcd-${ADDON_VERSION}/resources/crds/

	mkdir -p .build/${ADDON_VERSION}/fluxcd-${ADDON_VERSION}/resources/components/

	cd .build/${ADDON_VERSION}/downloads/deployments/ && \
	cue import *.yaml -p main -l 'strings.ToCamel(strings.Replace(metadata.name, "-", "", -1)+kind)' -f -R && \
	cue fmt ./... && \
	mv *.cue ../../fluxcd-${ADDON_VERSION}/resources/components/

	cd .build/${ADDON_VERSION}/fluxcd-${ADDON_VERSION}/ && \
	cp ${current_dir_abs}/build/source/metadata.yaml ./ && \
	cp ${current_dir_abs}/build/source/parameter.cue ./ && \
	cp ${current_dir_abs}/build/source/template.cue ./ && \
	cp -R ${current_dir_abs}/build/source/definitions ./ && \
	cp -R ${current_dir_abs}/build/source/schemas ./ && \
	cp -R ${current_dir_abs}/build/source/resources/rbac ./resources/


.build/fluxcd-${ADDON_VERSION}.tar.gz: vela-assets .build/${ADDON_VERSION}/fluxcd-${ADDON_VERSION} 
	cd .build/ && \
	${KUBEVELA} addon package ${ADDON_VERSION}/fluxcd-${ADDON_VERSION}


.PHONY: addon
addon: .build/fluxcd-${ADDON_VERSION}.tar.gz
	echo "Addon package is located at .build/fluxcd-${ADDON_VERSION}.tar.gz"
	
vela-assets: .bin
ifeq ("", "$(wildcard ${KUBEVELA} )")
	@{ \
	TMP_DIR=$$(mktemp -d) ;\
	cd $${TMP_DIR} ;\
	set -e ; \
	echo "OS: $${OS}, ARCH: $${arch}, VERSION: $${KUBEVELA_VERSION}" ; \
	curl -L "https://github.com/oam-dev/kubevela/releases/download/$${KUBEVELA_VERSION}/vela-$${KUBEVELA_VERSION}-linux-amd64.tar.gz" -o "vela.tar.gz" && \
	tar -xvf vela.tar.gz --strip-components 1 && \
    mv vela ${KUBEVELA} && \
    chmod +x ${KUBEVELA} ; \
	rm -rf $${TMP_DIR} ;\
	}
endif
	${KUBEVELA} version

yq-assets: .bin
ifeq ("", "$(wildcard ${YQ} )")
	@{ \
		TMP_DIR=$$(mktemp -d) ;\
		cd $${TMP_DIR} ;\
		set -e ; \
		echo "OS: $${OS}, ARCH: $${ARCH}, VERSION: $${YQ_VERSION}" ; \
		export YQ_DOWNLOAD_BINARY=yq_$${OS}_$${ARCH} ; \
		curl -sLO https://github.com/mikefarah/yq/releases/download/$${YQ_VERSION}/$${YQ_DOWNLOAD_BINARY} ; \
		mv $${YQ_DOWNLOAD_BINARY} $${YQ} ; \
		chmod +x $${YQ} ; \
		rm -rf $${TMP_DIR} ; \
	}
endif
	${YQ} --version
