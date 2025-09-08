Frigate NVR

```sh
docker rm frigate -f
docker compose up -d
docker logs -f --tail 100 frigate

docker logs -f --tail 100 ofelia
docker logs -f ofelia | Select-String 'rclone-summary'
```

```sh
cd C:\frigate
.\reset_frigate.ps1
.\reset-frigate.ps1 -FullReset
```