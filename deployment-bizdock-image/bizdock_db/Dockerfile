FROM mariadb:10.1.12

MAINTAINER Marc Schaer <marc.schar@the-agile-factory.com>

RUN sed -i "s|\[mysqld\]|\[mysqld\]\nmax_connections = 500\ninnodb_buffer_pool_size = 1073741824\ninnodb_file_per_table=ON\nsymbolic-links=1\n|g" /etc/mysql/my.cnf
RUN sed -i "s/port[ \t]*=[ \t0-9]*/port = 3306/g" /etc/mysql/my.cnf
