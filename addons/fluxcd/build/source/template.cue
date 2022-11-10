package main

import "strings"

// controller images prefix
_base:    *"" | string
registry: *"" | string
if parameter.registry != _|_ {
	registry: parameter.registry
}

if registry != "" && !strings.HasSuffix(registry, "/") {
	_base: registry + "/"
}
if registry == "" || strings.HasSuffix(registry, "/") {
	_base: registry
}

_targetNamespace: parameter.namespace

gitOpsController: [...] | []

kustomizeResourcesCustomResourceDefinition: [...] | []

parameter: {}

if parameter.onlyHelmComponents != _|_ && parameter.onlyHelmComponents == false {
	gitOpsController: [imageautomationcontrollerDeployment, imagereflectorcontrollerDeployment, kustomizecontrollerDeployment]
	kustomizeResourcesCustomResourceDefinition: [imagepoliciesCustomResourceDefinition, imagerepositoriesCustomResourceDefinition, imageupdateautomationsCustomResourceDefinition, kustomizationsCustomResourceDefinition]
}

if parameter.onlyHelmComponents == _|_ {
	gitOpsController: [imageautomationcontrollerDeployment, imagereflectorcontrollerDeployment, kustomizecontrollerDeployment]
	kustomizeResourcesCustomResourceDefinition: [imagepoliciesCustomResourceDefinition, imagerepositoriesCustomResourceDefinition, imageupdateautomationsCustomResourceDefinition, kustomizationsCustomResourceDefinition]
}

output: {
	apiVersion: "core.oam.dev/v1beta1"
	kind:       "Application"
	spec: {
		components: [
			{
				type: "k8s-objects"
				name: "fluxcd-ns"
				properties: objects: [{
					apiVersion: "v1"
					kind:       "Namespace"
					metadata: name: _targetNamespace
				}]
			},
			{
				type: "k8s-objects"
				name: "fluxcd-rbac"
				properties: objects: [
					// auto-generated from original yaml files
					clusterRoleBinding,
				]
			},
			{
				type: "k8s-objects"
				name: "fluxcd-CustomResourceDefinitions"
				properties: objects: [
							// auto-generated from original yaml files
							bucketsCustomResourceDefinition,
							gitrepositoriesCustomResourceDefinition,
							helmchartsCustomResourceDefinition,
							helmreleasesCustomResourceDefinition,
							helmrepositoriesCustomResourceDefinition,
							ocirepositoriesCustomResourceDefinition,
				] + kustomizeResourcesCustomResourceDefinition
			},
			{
				type: "k8s-objects"
				name: "fluxcd-controllers"
				properties: objects: [
					helmcontrollerDeployment,
					sourcecontrollerDeployment,
				] + gitOpsController
			},
			{
				type: "k8s-objects"
				name: "fluxcd-services"
				properties: objects: [
					sourcecontrollerService,
				]
			},
		]
		policies: [
			{
				type: "shared-resource"
				name: "namespace"
				properties: rules: [{
					selector: resourceTypes: ["Namespace"]
				}]
			},
			{
				type: "topology"
				name: "deploy-fluxcd-ns"
				properties: {
					namespace: _targetNamespace
					if parameter.clusters != _|_ {
						clusters: parameter.clusters
					}
					if parameter.clusters == _|_ {
						clusterLabelSelector: {}
					}
				}
			},
			{
				type: "garbage-collect"
				name: "not-gc-CustomResourceDefinition"
				properties: {
					rules: [{
						selector: resourceTypes: ["CustomResourceDefinition"]
						strategy: "never"
					},
					]
				}
			},
			// {
			// 	type: "apply-once"
			// 	name: "not-keep-CustomResourceDefinition"
			// 	properties: {
			// 		rules: [{
			// 			selector: resourceTypes: ["CustomResourceDefinition"]
			// 			strategy: {
			// 				path: ["*"]
			// 			}
			// 		},
			// 		]
			// 	}
			// },
		]
	}
}
