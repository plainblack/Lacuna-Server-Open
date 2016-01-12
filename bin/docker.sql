create database lacuna;
create user 'lacuna'@'%' identified by 'lacuna';
grant all privileges on lacuna.* to 'lacuna'@'%';
flush privileges;


