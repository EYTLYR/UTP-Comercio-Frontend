# Frontend web en Docker

La imagen incluye la aplicación Flutter web de producción, su configuración pública y Nginx. El servidor no necesita Flutter, código fuente, `.env` ni compilar nada. PostgreSQL y el backend continúan siendo servicios independientes.

## Construir en tu equipo

Con Docker Desktop en modo contenedores Linux, desde la raíz del frontend:

```powershell
docker compose -f compose.build.yaml build
docker save -o nearby-frontend.tar nearby-frontend:server
```

El Dockerfile utiliza Flutter 3.47.9, compatible con el Dart 3.13.7 exigido por el proyecto. Compila en release y fuerza `APP_ENV=production`, ocultando los controles de desarrollo. Incluye los recursos del motor web para servirlos desde la propia imagen.

La compilación incorpora el `.env` del frontend automáticamente. `API_BASE_URL`, si se configura allí, debe ser una URL accesible desde el navegador del usuario, no el nombre interno de un contenedor. Sin esa variable, la app usa `https://nearby-api.eytlyr.com`. Para cambiar esta configuración, reconstruye la imagen. El `.env` del frontend es público: solo debe contener configuración pública, nunca claves del backend o de PostgreSQL.

Si construyes desde una arquitectura distinta a Linux AMD64, para un servidor AMD64 usa en lugar del comando de construcción:

```powershell
docker buildx build --platform linux/amd64 --load -t nearby-frontend:server .
```

## Copiar y ejecutar en el servidor

Copia únicamente `nearby-frontend.tar` y `docker-compose.yml` a una carpeta propia del frontend. No sobrescribas el Compose del backend.

```sh
docker load -i nearby-frontend.tar
docker compose up -d
```

La web queda disponible en `http://127.0.0.1:8081` dentro del servidor; el backend puede seguir en 8080. Compose utiliza exclusivamente la imagen cargada, sin descargarla ni compilarla. Nginx del servidor mantiene los puertos 80/443 y dirige las peticiones al puerto 8081 del contenedor. El puerto 8081 se publica solo en loopback para utilizarlo mediante ese proxy.

En el bloque `server` del dominio del frontend en Nginx, configura:

```nginx
location / {
    proxy_pass http://127.0.0.1:8081;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Valida y recarga Nginx con `sudo nginx -t && sudo systemctl reload nginx`. Si el contenedor ya estaba creado con otro puerto, copia el Compose actualizado y ejecuta `docker compose up -d --force-recreate`; no necesitas reconstruir ni exportar otra vez la imagen para este cambio.

```sh
docker compose ps
docker compose logs -f web
```

No se requiere un archivo de configuración adicional para servir la web. Para acceder por dominio con cámara, micrófono y ubicación, publica el sitio con HTTPS mediante el proxy/certificado del servidor; los navegadores limitan esas funciones sobre HTTP fuera de localhost. El backend debe permitir el origen público del frontend en `NEARBY_CORS_ORIGINS`. Si la web usa HTTPS, la API también debe usar HTTPS.

## Actualizar

Reconstruye y exporta en tu equipo. Transfiere el nuevo TAR y ejecuta:

```sh
docker load -i nearby-frontend.tar
docker compose up -d --force-recreate
```

Para detenerlo: `docker compose down`.

## Sin Compose

Tras cargar la imagen, también puedes ejecutar:

```sh
docker run -d --name nearby-frontend --restart unless-stopped -p 127.0.0.1:8081:80 nearby-frontend:server
```

Utiliza esta alternativa o Compose para evitar conflictos de puerto. Nginx incluye compresión, comprobación de salud en `/healthz`, revalidación de caché y soporte de rutas de la app al recargar la página.

Referencias: [despliegue web de Flutter](https://docs.flutter.dev/deployment/web) y [contenido estático en Nginx](https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/).
