# syntax=docker/dockerfile:1.7

ARG RUBY_VERSION=3.4.12

# ---------- build stage ----------
FROM ruby:${RUBY_VERSION}-slim AS build

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"

WORKDIR /app

# Native gems (pg / mini_magick) と asset build に必要なツールを入れる
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      git \
      gnupg \
      libpq-dev \
      libvips \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Gem を先に解決（Gemfile が変わらない限りキャッシュが効く）
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf /usr/local/bundle/cache

# アプリ全体
COPY . .

# Bootsnap precompile（起動時間短縮）
RUN bundle exec bootsnap precompile --gemfile app/ lib/ config/

# Asset precompile（画像等の sprockets アセットのみ。JS/CSS ビルドは #136 段階4 で撤去済み）。
# SECRET_KEY_BASE はビルド時のダミーで十分
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile && \
    rm -rf tmp/cache vendor/cache

# ---------- runtime stage ----------
FROM ruby:${RUBY_VERSION}-slim AS runtime

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD=libjemalloc.so.2 \
    PORT=8080

WORKDIR /app

# Runtime に必要なライブラリのみ（コンパイラは入れない）。
# 公式 ruby イメージは再ビルドまでの間に出た Debian のセキュリティ修正を含まないため、
# upgrade でビルド時点の修正を取り込む（Trivy の週次スキャンで検出された zlib など）。
# deploy-cloud-run.yml は --cache-from でビルドするため、この層がキャッシュされると
# upgrade が再実行されない。ビルドごとに異なる値（Actions の run ID と attempt）を渡し、
# 同じ日に何度ビルドしても必ずこの層から作り直す
ARG APT_CACHE_BUST=unset
RUN echo "apt cache bust: ${APT_CACHE_BUST}" && \
    apt-get update -qq && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      libjemalloc2 \
      libpq5 \
      libvips \
      tzdata && \
    rm -rf /var/lib/apt/lists/*

# 非 root ユーザで起動
RUN groupadd --system --gid 1000 app && \
    useradd --system --uid 1000 --gid app --home-dir /app --shell /usr/sbin/nologin app

COPY --from=build --chown=app:app /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=app:app /app /app

# tmp / log は実行時のみ書き込み可能にする
RUN mkdir -p tmp/pids log && chown -R app:app tmp log

USER app

EXPOSE 8080

# Cloud Run は $PORT をコンテナに渡してくる。0.0.0.0 で listen する必要がある。
# `exec` を付けて Rails プロセスを PID 1 にし、Cloud Run の SIGTERM が
# 正しく届くようにする
CMD ["bash", "-c", "exec bundle exec rails server -b 0.0.0.0 -p ${PORT}"]
