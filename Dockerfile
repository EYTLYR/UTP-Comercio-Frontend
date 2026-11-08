FROM ubuntu:24.04 AS build
ARG FLUTTER_VERSION=3.47.9
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics && flutter precache --web
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY lib/ lib/
COPY web/ web/
COPY assets/ assets/
# Solo configuración pública del frontend; nunca usar el .env del backend.
COPY .env .env
RUN flutter build web --release --no-pub --no-web-resources-cdn --dart-define=APP_ENV=production

FROM nginx:stable-alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web/ /usr/share/nginx/html/
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
