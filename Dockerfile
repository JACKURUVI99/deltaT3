FROM archlinux:latest

ENV TERM=xterm
RUN pacman -Sy --noconfirm && \
    pacman -S --noconfirm lua luarocks gcc make mysql-clients git mariadb-libs && \
    luarocks install luasocket && \
    luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql && \
    luarocks install md5
WORKDIR /app

#Copy application files
COPY server.lua .
COPY requirements.txt .
EXPOSE 8080
CMD ["lua", "server.lua"]
