Frigate NVR

```sh
docker rm frigate -f
docker compose up -d
docker logs -f --tail 100 frigate
```