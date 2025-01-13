VERSION=`git describe --tags`
BUILD_TIME=`date +%FT%T%z`
LDFLAGS=-ldflags "-X main.Version=$(V) -X main.BuildTime=${BUILD_TIME}"
NAME=oosa-gw

run: gen-conf
	docker run -p "8080:8080" -v $$PWD:/etc/krakend/ devopsfaith/krakend:2.7.2 run -c krakend_pretty.json

build-docker-img:
	docker build -t ${NAME}:dev .
	docker rmi -f $$(docker images --filter "dangling=true" -q --no-trunc)

push-docker:
	docker tag ${NAME}:dev  94peter/${NAME}:$(V)
	docker push 94peter/${NAME}:$(V)

gen-conf:
	docker run --rm \
	-e FC_ENABLE=1 -e FC_PARTIALS="./partials" \
	-e FC_SETTINGS="./settings" -e FC_OUT=krakend_pretty.json \
	-v $$PWD:/etc/krakend/ devopsfaith/krakend:2.7.2 check -d -t -c ./krakend.tmpl
	docker run -i isaackuang/tools jq --compact-output <krakend_pretty.json '.' > krakend.json


merge-spec:
	docker run --rm \
	-v $$PWD:/workdir 94peter/openapi-cli:v1.13 /main ms \
	-main /workdir/mainspec/${ENV}_spec.yml \
	-mergeDir /workdir/all_spec/ \
	-output /workdir/doc/${ENV}_oosa.yml \

gen-setting-json:
	docker run --rm \
	-v $$PWD:/workdir 94peter/openapi-cli:v1.13 /main togs \
	-spec /workdir/doc/${ENV}_oosa.yml \
	-output /workdir/settings/endpoint.json \
	-no-redirect-tag noRedirect

gen-oath-rule: 
	docker run --rm \
	-v $$PWD:/workdir 94peter/openapi-cli:v1.13 /main tar \
	-spec /workdir/doc/${ENV}_oosa.yml \
	-output /workdir/doc/${ENV}_rules.json