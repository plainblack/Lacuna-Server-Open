create database lacuna;
create user 'lacuna'@'localhost' identified by 'lacuna';
grant all privileges on lacuna.* to lacuna@localhost;
flush privileges;


