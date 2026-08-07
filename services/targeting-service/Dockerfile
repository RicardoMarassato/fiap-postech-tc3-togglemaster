FROM python:3.14-alpine3.24 AS builder

WORKDIR /app
RUN apk add --no-cache ca-certificates

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools && \
    pip install --no-cache-dir gunicorn>=23.0.0 && \
    pip install --no-cache-dir -r requirements.txt

FROM python:3.14-alpine3.24

WORKDIR /app
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S -G appgroup appuser

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/local/lib/python3.14/site-packages /usr/local/lib/python3.14/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY --chown=appuser:appgroup . .
USER appuser

EXPOSE 8003
CMD ["python", "app.py"]
