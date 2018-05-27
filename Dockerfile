FROM ubuntu:16.04
ENV ROOT_PASSWORD="(&9&(-089-0=*7()&^)*^765%^$%^$%^4&*%*(90*"
ENV WP_DB_NAME=wordpress
ENV WP_USER_NAME=wordpress
ENV WP_USER_PASSWORD="()*09(*&9*&9*&987()&76(&*%^7%&"
RUN echo "mysql-server mysql-server/root_password password ${ROOT_PASSWORD}" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password ${ROOT_PASSWORD}" | debconf-set-selections

RUN apt-get update && apt-get -y install \
    mysql-server \
    nginx \
    php-fpm \
    php-mysql \
    curl \
    php-curl \
    php-gd \
    php-mbstring \
    php-mcrypt \
    php-xml \
    php-xmlrpc

RUN rm -rf /var/run/mysqld && mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld
RUN chmod -R 777 /var/run/mysqld
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN /etc/init.d/mysql start && \
    mysql -u root --password=${ROOT_PASSWORD} -e "\
    CREATE DATABASE ${WP_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;\
    FLUSH PRIVILEGES;\
    GRANT ALL ON wordpress.* TO '${WP_USER_NAME}'@'localhost' IDENTIFIED BY '${WP_USER_PASSWORD}';\
    FLUSH PRIVILEGES;"

RUN cd /tmp && \
    curl -O https://wordpress.org/latest.tar.gz && \
    tar xzvf latest.tar.gz && \
    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php && \
    mkdir /tmp/wordpress/wp-content/upgrade && \
    cp -a /tmp/wordpress/. /var/www/html && \
    chown -R root:www-data /var/www/html && \
    find /var/www/html -type d -exec chmod g+s {} \; && \
    chmod g+w /var/www/html/wp-content && \
    chmod -R g+w /var/www/html/wp-content/themes && \
    chmod -R g+w /var/www/html/wp-content/plugins && \
    curl -s https://api.wordpress.org/secret-key/1.1/salt/

RUN cd /etc/nginx && \
    cat nginx.conf | sed -e 's/^http {$/http {\n\tclient_max_body_size 8m;\n/' > temp_file && \
    mv temp_file nginx.conf && \
    cd /etc/php/7.0/fpm && \
    sed -e 's/^upload_max_filesize.*$/upload_max_filesize = 8M/' -e 's/^post_max_size.*$/post_max_size = 8M/' php.ini > temp_file && \
    mv temp_file php.ini

COPY get_date.sh /usr/local/bin
RUN chmod +x /usr/local/bin/get_date.sh

COPY ./startup.sh /opt/startup.sh
EXPOSE 3306

ENTRYPOINT ["/bin/bash", "/opt/startup.sh"]
CMD ["mysqld"]
