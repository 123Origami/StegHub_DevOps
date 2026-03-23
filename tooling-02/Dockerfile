FROM php:8-apache

ENV MYSQL_IP=$MYSQL_IP
ENV MYSQL_USER=$MYSQL_USER
ENV MYSQL_PASS=$MYSQL_PASS
ENV MYSQL_DBNAME=$MYSQL_DBNAME
EXPOSE 80

RUN <<-EOF
 docker-php-ext-install mysqli
 echo "ServerName localhost" >> /etc/apache2/apache2.conf
 curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
EOF
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Copy application source
COPY html /var/www
RUN chown -R www-data:www-data /var/www

CMD ["apache2-foreground"]
