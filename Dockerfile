# Xim Docker Image (HTTP)
# 
# Multi-stage build:
#   Stage 1: Build Kotlin/JS with Gradle (JDK)
#   Stage 2: Serve with nginx (lightweight)
#
# Build:
#   docker build -t xim .
#
# Run:
#   docker run -p 8083:80 -v "/path/to/FINAL FANTASY XI":/usr/share/nginx/html/ffxi:ro xim

# ============================================
# Stage 1: Build the Kotlin/JS application
# ============================================
FROM eclipse-temurin:17-jdk AS builder

# Install Gradle
ENV GRADLE_VERSION=7.4.2
RUN apt-get update && apt-get install -y wget unzip && \
    wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip -q gradle-${GRADLE_VERSION}-bin.zip -d /opt && \
    rm gradle-${GRADLE_VERSION}-bin.zip && \
    ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy build files first (for layer caching)
COPY build.gradle.kts settings.gradle.kts gradle.properties ./

# Download dependencies (cached layer)
RUN gradle --no-daemon dependencies || true

# Copy source code
COPY src/ src/
COPY webpack.config.d/ webpack.config.d/

# Build the production bundle
RUN gradle --no-daemon jsBrowserProductionWebpack

# ============================================
# Stage 2: Production image with nginx
# ============================================
FROM nginx:alpine

# Install envsubst for potential config templating
RUN apk add --no-cache gettext

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built JavaScript from builder stage
COPY --from=builder /build/build/dist/js/productionExecutable/xim.js /usr/share/nginx/html/
COPY --from=builder /build/build/dist/js/productionExecutable/xim.js.map /usr/share/nginx/html/

# Copy static resources from source
COPY src/jsMain/resources/index.html /usr/share/nginx/html/
COPY src/jsMain/resources/main.css /usr/share/nginx/html/
COPY src/jsMain/resources/env.json /usr/share/nginx/html/
COPY src/jsMain/resources/favicon.ico /usr/share/nginx/html/
COPY src/jsMain/resources/title_txt_01.png /usr/share/nginx/html/
COPY src/jsMain/resources/wallpaper_03.png /usr/share/nginx/html/

# Create directory for FFXI mount point
RUN mkdir -p /usr/share/nginx/html/ffxi

# Copy landsandboat to where nginx alias expects it (see nginx.conf)
# nginx maps /ffxi/landsandboat/ URL -> /usr/share/nginx/html/landsandboat/ filesystem
# This keeps landsandboat separate from the FFXI mount point
COPY src/jsMain/resources/landsandboat/ /usr/share/nginx/html/landsandboat/

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
