# syntax=docker/dockerfile:1.6
#
# Multi-stage build for a simple PHP web app
# - Uses official PHP + Apache base image
# - Copies only what is needed to the runtime image
# - Runs as a non-root user (www-data) for better security
#
# Stage 1: builder — install PHP extensions and prepare app
FROM php:8.2-apache AS builder

# Enable commonly needed PHP extensions (adjust to match the app's needs)
RUN docker-php-ext-install pdo pdo_mysql

# Enable Apache modules (rewrite is common for many PHP apps)
RUN a2enmod rewrite

WORKDIR /var/www/html

# Copy application source
# If your repo has vendor/ or build steps (Composer), add them here.
COPY . .

# Example Composer install (uncomment if the app uses Composer):
# COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Stage 2: runtime — minimal runtime image
FROM php:8.2-apache AS runtime

# Create an unprivileged user if needed; the image already has www-data
# Ensure Apache runs as www-data by default; we also set an explicit User
RUN sed -ri 's/^#?User .*/User www-data/' /etc/apache2/apache2.conf &&         sed -ri 's/^#?Group .*/Group www-data/' /etc/apache2/apache2.conf

# Security hardening: avoid exposing version signatures
RUN echo 'ServerTokens Prod\nServerSignature Off' > /etc/apache2/conf-available/security.conf &&         a2enconf security

WORKDIR /var/www/html

# Copy final app files from builder stage
COPY --from=builder /var/www/html /var/www/html

# Fix permissions: make app owned by www-data
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
USER www-data
CMD ["apache2-foreground"]
