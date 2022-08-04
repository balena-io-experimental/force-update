FROM alpine

RUN apk update && apk add jq bash curl

COPY pin.sh reset.sh ./

CMD [ "./pin.sh" ]
