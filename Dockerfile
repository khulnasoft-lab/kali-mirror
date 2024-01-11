FROM kalilinux/kali-rolling

# Install required packages
RUN apt-get update && \
    apt-get install -y wget rsync cron nginx

# Set up FTPSync configuration
COPY etc/ftpsync.conf.sample /etc/ftpsync-kali.conf
RUN sed -i 's/MIRRORNAME=`hostname -f`/MIRRORNAME="kali-mirror"/' /etc/ftpsync-kali.conf && \
    sed -i 's#TO="/srv/mirrors/kali/"#TO="/var/www/html/kali/"#' /etc/ftpsync-kali.conf && \
    sed -i 's/RSYNC_PATH="kali"/RSYNC_PATH="kali-archive"/' /etc/ftpsync-kali.conf && \
    sed -i 's/RSYNC_HOST="archive.kali.org"/RSYNC_HOST="rsync.kali.org"/' /etc/ftpsync-kali.conf

# Unpack FTPSync
RUN wget https://archive.kali.org/ftpsync.tar.gz && \
    tar zxf ftpsync.tar.gz && \
    mv ftpsync /usr/local/bin/

# Set up cron job for periodic mirroring
RUN echo "0 * * * * /usr/local/bin/ftpsync -c /etc/ftpsync-kali.conf" | crontab -

# Configure Nginx
COPY nginx/kali-mirror /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/kali-mirror /etc/nginx/sites-enabled/ && \
    rm /etc/nginx/sites-enabled/default

# Expose ports
EXPOSE 80

CMD service cron start && nginx -g "daemon off;"
