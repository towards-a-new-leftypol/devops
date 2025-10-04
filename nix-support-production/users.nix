{ config, ... }:

{
  users.mutableUsers = false;
  users.motd = ''
________                                ______ _____         
__  ___/_____________ _____________________  /____(_)_______ 
_____ \___  __ \  __ `/  ___/  _ \_  ___/_  __ \_  /___  __ \
____/ /__  /_/ / /_/ // /__ /  __/(__  )_  / / /  / __  /_/ /
/____/ _  .___/\__,_/ \___/ \___//____/ /_/ /_//_/  _  .___/ 
       /_/                                          /_/      

NixOS 25.05 - Leftychan.net production server.
  '';

  users.extraUsers.admin = {
    isNormalUser = true;
    home = "/home/admin";
    description = "Sysadmin account. SSH into this.";
    extraGroups = [ "wheel" "nginx" "lainchan" ];

    # the password is password
    hashedPassword = "$6$mV1wguq77UrIH$i/gftmJYcg.OP6d3PgTTOmE/cQqGNqpspPYdwOc04otsdqkpLj1YKoa1QWp7Z.MApwofxawlQzfSGfO4AiUN2.";
    openssh.authorizedKeys.keys = [
        # Zer0's key, add your public key here
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBu2RKq+iiu2DoaeMlwhzGGGJww0qP1miyvBJ8OoDc8145XY9kw/LFQ8FbDG8jezszfpe6T6zEbpLFgEoj/ClrA= zer0@localhos"
        # Comatoast
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCXfeugu0xKJtp2lheAGlzG1ibQKe9d7dBU9/pXzVPBq5y4Sgsq7BTuvrABjfbQVT9w5ealH9zSW/vorlt9c1xgRPkDiA0FB7JKYSFfjsnGv4BX1RhB/YeXPBn8ArNdHTrx8Mp2rT63wZQJSJdnhnC5J/iq9jbfjjbea/ABjjwbAEzkawCJPOsoB3bHsvsCTa0pj8xOJ7ERZObtZtrO/3AWMHWiR7MVG2SgpAp3JyLARh7YJjX66tobo9SWsxf3z8+Q2dA8LIeP65kRJuvVzc9cvo8eZfdwWqSFGIFHJl09VjzNL6STjonma29BpHWWEecEOcluu7Sbgzs97fCZYJIup4I75Q11LqhmWeLpI/A6BohgPgTggq03IqUcnIjI90uVSTdOdB9TJeys0KowIRQMGQlcE61vd4JLAPrQMhnrKuazU3ep1/X34xA+qKZmR8YN7ByY3K8CynZbzB7UAcsJg6mXTPXGMIPzsVZb0r7jmnvywfB0WAUGmyo+XrbvyX0= comatoast"
    ];
  };

}
