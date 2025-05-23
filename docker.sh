#!/bin/bash

docker run -d --name jaeger -e COLLECTOR_ZIPKIN_HOST_PORT=:9411 -p 16686:16686 -p 14268:14268 -p 14250:14250 -p 6831:6831/udp -p 6832:6832/udp jaegertracing/all-in-one:1.50