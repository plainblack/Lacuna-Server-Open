create database reboot;
create user 'lacuna'@'%' identified by 'lacuna';
grant all privileges on reboot.* to 'lacuna'@'%';
flush privileges;


