##############################################
# Primeiro estágio: Build da aplicação
##############################################
FROM php:8.2-cli AS build

# Define diretório de trabalho
WORKDIR /app

# Copia a aplicação para o container de build
COPY app/ ./

# Instalar dependências com Composer
# RUN apt-get update && apt-get install -y git unzip
# COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# RUN composer install --no-dev --optimize-autoloader

# Ajusta permissões de arquivos e pastas
RUN find . -type d -exec chmod 755 {} \; && \
    find . -type f -exec chmod 644 {} \;

##############################################
# Segundo estágio: Runtime otimizado
##############################################
FROM php:8.2-apache AS runtime

# Definir porta customizada, para evitar rodar Apache como root
ENV APACHE_LISTEN_PORT=8080

# Atualiza configuração do Apache para usar a porta 8080
RUN sed -i "s/Listen 80/Listen ${APACHE_LISTEN_PORT}/" /etc/apache2/ports.conf \
    && sed -i "s/:80/:${APACHE_LISTEN_PORT}/" /etc/apache2/sites-available/000-default.conf

# Copiar os arquivos necessários do stage de build para a imagem final
COPY --from=build /app /var/www/html

# Ajusta permissões para o usuário não-root
RUN chown -R www-data:www-data /var/www/html

# Altera usuário ativo
USER www-data

# Expõe a porta configurada
EXPOSE 8080

# Explicação: O Apache usa um processo master para escutar na porta configurada
# e forks de workers rodando como www-data para servir as requisições.
# Rodar o container como www-data reduz a superfície de ataque.
CMD ["apache2-foreground"]
