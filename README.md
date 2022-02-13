## TL;DR

Generate certs, start servers and run all tests
```
docker-compose run --rm cert-gen
docker-compose up -d
docker-compose run --rm client
```

## Environment setup

Generate certificates for client and app servers:

```
docker-compose run --rm cert-gen
```

Then, start app servers and NGINX instance:

```
docker-compose up -d
```
Run all the tests:

```
docker-compose run --rm client
```
## NGINX configuration

```
events {}

# Layer 4 load balancing
stream {

    # Listen on ports 443/8000, use SNI to proxy to destination address
    server {
        # List of ports we want to forward
        listen     443;
        listen     8000;

        # Forward to the same host, same port
        proxy_pass $ssl_preread_server_name:$server_port;

        # This DNS resolver needs to resolve external host names to their actual external IP
        resolver 127.0.0.11;

        # Enable SNI so that we can intercept and forward to the right destination
        ssl_preread on;
    }

    # Listen on port 8001, proxy to app2:8000
    server {
        listen     8001;
        proxy_pass app2:8000;
        resolver 127.0.0.11;
    }

    # Listen to port 8002/udp, proxy to app2:123
    server {
        listen     8002 udp;
        proxy_pass app2:123;
        resolver 127.0.0.11;
    }
}
```

## Test Cases

### Test Case 1: Request https://app1:443 with mTLS and SNI

1. Client initiates request to app1:443 with mTLS and SNI
2. DNS resolver (docker in this demo) maps `app1` to IP address of NGINX
3. Client connects to NGINX; NGINX uses SNI hostname to proxy connection to app1 server
4. Client establishes mTLS tunnel with app1 server

### Test Case 2: Request https://app2:8000 with SNI

1. Client initiates request to app2:8000 with SNI
2. DNS resolver maps `app2` to IP address of NGINX
3. Client connects to NGINX; NGINX uses SNI hostname to proxy connection to app2 server
4. Client establishes TLS session with app2 server


### Test Case 3: Request https://app2:8000 using NGINX port 8001 (no SNI)

1. Client initiates request to app2:8001
2. DNS resolver maps `app2` to IP address of NGINX
3. Client connects to NGINX; NGINX maps all requests for tcp/8001 to app2:8000
4. Client establishes TLS session with app2 server without SNI

### Test Case 4: UDP connection to app2:123 via NGINX port 8002

1. Client initiates request to app2:8002
2. DNS resolver maps `app2` to IP address of NGINX
3. Client connects to NGINX; NGINX maps all requests for udp/8002 to app2:123
4. Client is able to send/receive UDP datagrams to/from app2:123
