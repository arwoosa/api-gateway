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
	docker run -i \
	-e FC_ENABLE=1 -e FC_PARTIALS="./partials" \
	-e FC_SETTINGS="./settings" -e FC_OUT=krakend_pretty.json \
	-v $$PWD:/etc/krakend/ devopsfaith/krakend:2.7.2 check -d -t -c ./krakend.tmpl
	docker run -i isaackuang/tools jq --compact-output <krakend_pretty.json '.' > krakend.json


merge-spec:
	docker run -i \
	-v $$PWD:/workdir 94peter/openapi-cli:v1.11 /main ms \
	-main /workdir/main_spec.yml \
	-mergeDir /workdir/all_spec/ \
	-output /workdir/doc/oosa.yml \

gen-setting-json:
	docker run -i \
	-v $$PWD:/workdir 94peter/openapi-cli:v1.11 /main ms \
	-main /workdir/main_spec.yml \
	-mergeDir /workdir/all_spec/ \
	-output /workdir/doc/temp_web_api.yml
	docker run -i \
	-v $$PWD:/workdir 94peter/openapi-cli:v1.11 /main togs \
	-spec /workdir/doc/temp_web_api.yml \
	-output /workdir/settings/endpoint.json
	rm $$PWD/doc/temp_web_api.yml

gen-oath-rule: 
	docker run -i \
	-v $$PWD:/workdir 94peter/openapi-cli:v1.11 /main tar \
	-spec /workdir/doc/oosa.yml \
	-output /workdir/doc/rules.json