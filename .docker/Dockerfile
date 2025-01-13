FROM devopsfaith/krakend:2.1.4 as builder

WORKDIR /krakend/config
COPY . .

RUN FC_ENABLE=1 \
    FC_OUT=/krakend/config/krakend_pretty.json \
    FC_PARTIALS="/krakend/config/partials" \
    FC_SETTINGS="/krakend/config/settings" \
    krakend check -d -t -c /krakend/config/krakend.tmpl

FROM stedolan/jq:latest as minifier
WORKDIR /krakend/config
COPY --from=builder --chown=1000 /krakend/config .
RUN jq --compact-output <krakend_pretty.json '.' > krakend.json


FROM devopsfaith/krakend:2.1.4
COPY --from=minifier --chown=1000 /krakend/config/krakend.json .
COPY --from=minifier --chown=1000 /doc/ ./doc/
# COPY --from=minifier --chown=1000 /etc/krakend/plugins/ ./plugin/
# COPY --from=minifier --chown=1000 /krakend/config/script/ ./script/