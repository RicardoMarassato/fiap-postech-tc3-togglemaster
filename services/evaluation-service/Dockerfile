# APP BUILDER
FROM golang:1.21-alpine3.20 AS builder

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /out/evaluation-service .

# APP
FROM alpine:3.24

WORKDIR /app

RUN apk add --no-cache ca-certificates && \
    addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S -G appgroup appuser

COPY --from=builder --chown=appuser:appgroup /out/evaluation-service ./evaluation-service

USER appuser

EXPOSE 8004

CMD ["./evaluation-service"]
