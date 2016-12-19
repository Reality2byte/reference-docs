all: main.go
	go build main.go

cleancli:
	rm -f main
	rm -rf $(shell pwd)/gen_kubectl/includes
	rm -rf $(shell pwd)/gen_kubectl/build
	rm -rf $(shell pwd)/gen_kubectl/manifest.json

cleanapi:
	rm -f main
	rm -rf $(shell pwd)/gen_open_api/build
	rm -rf $(shell pwd)/gen_open_api/includes
	rm -rf $(shell pwd)/gen_open_api/manifest.json

brodocs:
	docker build . -t pwittrock/brodocs
	docker push pwittrock/brodocs

cli: cleancli
	go run main.go --yaml-file gen_kubectl/kubectl.yaml --doc-type kubectl --template-dir gen_kubectl/ --toc-file gen_kubectl/toc.yaml --build-dir gen_kubectl/
	docker run -v $(shell pwd)/gen_kubectl/includes:/source -v $(shell pwd)/gen_kubectl/build:/build -v $(shell pwd)/gen_kubectl/:/manifest pwittrock/brodocs

// Usage: TAG="vN" make pushcli
pushcli: cli
	cd gen_kubectl && docker build . -t pwittrock/cli-docs:$(TAG)
	docker push pwittrock/cli-docs:$(TAG)

pushcliconfig:
	cd configs && kubectl apply -f kubectldocs.yaml

api: cleanapi
	go run main.go --yaml-file gen_open_api/config.yaml --doc-type open-api --template-dir gen_open_api/ --build-dir gen_open_api/ --open-api-dir gen_open_api/openapi-spec/
	docker run -v $(shell pwd)/gen_open_api/includes:/source -v $(shell pwd)/gen_open_api/build:/build -v $(shell pwd)/gen_open_api/:/manifest pwittrock/brodocs

// Usage: TAG="vN" make pushapi
pushapi: api
	cd gen_open_api && docker build . -t pwittrock/api-docs:$(TAG)
	docker push pwittrock/api-docs:$(TAG)

pushapiconfig:
	cd configs && kubectl apply -f apidocs.yaml

resource: cleanapi
	go run main.go --build-operations=false --yaml-file=gen_open_api/config.yaml --doc-type open-api --template-dir gen_open_api/ --build-dir gen_open_api/ --open-api-dir gen_open_api/openapi-spec/
	docker run -v $(shell pwd)/gen_open_api/includes:/source -v $(shell pwd)/gen_open_api/build:/build -v $(shell pwd)/gen_open_api/:/manifest pwittrock/brodocs

// Usage: TAG="vN" make pushresource
pushresource: resource
	cd gen_open_api && docker build . -t pwittrock/resource-docs:$(TAG)
	docker push pwittrock/resource-docs:$(TAG)

pushresourceconfig:
	cd configs && kubectl apply -f resourcedocs.yaml

pushstagingapiconfig:
	cd configs && kubectl apply -f stagingapidocs.yaml