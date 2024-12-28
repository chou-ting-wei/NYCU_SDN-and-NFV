FROM alpine:3.18
LABEL maintainer="N0BALL"

RUN apk update
RUN apk add --no-cache iproute2 tcpdump mtr iputils ndisc6 iperf

ENTRYPOINT ["/bin/ash", "-c", "while sleep 3600; do :; done"]
