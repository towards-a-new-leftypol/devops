#Instructions

To use docker to set up a development environment, just drop site.conf, Dockerfile, and docker-compose into the top level folder of leftypol_lainchan. Then modify your .gitignore file to include these files so you don't commit them to source control. Obviously you must install docker/docker compose for the following instructions to work.

- Warning: you may have to modify config or instance config to use the ip address and username of dockerized database server (172.20.0.2,root,M9q5lO0RxJVh) in order to get it to work. Make sure not to commit these changes to source control either. you can use something like 'git update-index --assume-unchanged <filename>' to make it easier to not commit these modified config files to source control.

- Warning: you may have an error when installing using install.php due to the typehint there. You can modify the install.php file on line 27 from 'function checkMd5Exec(bool $can_exec)' to 'function checkMd5Exec($can_exec)', removing the typehint and making it so you can install.

- Warning: you may get an error that says index too big when you install. This isn't fatal and you can continue with the installation.

##Commands

- Once you get everything set up use 'docker-compose build'
- then use 'docker-compose up' to start the application and navigate to localhost:8080