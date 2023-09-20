# Start with the latest WordPress image.
FROM wordpress:php8.1

ENV NODE_MAJOR=20

# Set up nodejs PPA
RUN apt-get install -y ca-certificates curl gnupg
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# Install server dependencies.
RUN apt-get update && apt-get install -qq -y nodejs build-essential pkg-config libcairo2-dev libjpeg-dev libgif-dev git subversion default-mysql-client zip unzip vim libyaml-dev --fix-missing --no-install-recommends

COPY bin/install-wp-tests.sh /
RUN cat /install-wp-tests.sh | bash /dev/stdin wordpress root password mysql latest true

# Setup phpunit dependencies (needed for coverage).
RUN pecl install xdebug && \
		docker-php-ext-enable xdebug

# Download wp-cli
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod 755 /usr/local/bin/wp

# Disable PHP opcache (not great while developing)
RUN rm -rf /usr/local/etc/php/conf.d/opcache-recommended.ini

# Install composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

ENV PATH="/root/.composer/vendor/bin::${PATH}"

RUN composer global require "phpunit/phpunit=8.*"
RUN composer global require "dealerdirect/phpcodesniffer-composer-installer"
RUN composer global require wp-coding-standards/wpcs
RUN phpcs --config-set installed_paths /root/.composer/vendor/wp-coding-standards/wpcs
