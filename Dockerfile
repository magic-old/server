############################################################
# Dockerfile to build Magic-Server Containers
# Powered by Magic
############################################################

# Set the base image to Ubuntu
FROM ubuntu

# File Author / Maintainer
MAINTAINER Jascha Ehrenreich <jascha@jaeh.at>

RUN apt-get install software-properties-common -y

# Install Nginx.
RUN \
  add-apt-repository -y ppa:nginx/stable && \
  apt-get update && \
  apt-get install -y nginx && \
  rm -rf /var/lib/apt/lists/* && \
  chown -R www-data:www-data /var/lib/nginx

# We are powered by Magic
RUN sed -i \
  -e 's/nginx\/.....\r/magic\/2.3.5\r/' \
  -e 's/nginx\r/magic\r/' \
  `which nginx`

# Remove the default Nginx configuration file
RUN rm -v /etc/nginx/nginx.conf

# Copy the config
ADD out/nginx/nginx.conf /etc/nginx/

RUN rm /etc/nginx/sites-enabled/*

ADD out/nginx/sites-enabled/* /etc/nginx/sites-enabled/

# Expose ports
EXPOSE 80 443

RUN nginx -t

# Set the default command to execute
# when creating a new container
CMD service nginx start
