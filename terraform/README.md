# Terraform

This folder contains multiple terraform scripts to make different configurations
on AWS.

 - ec2-instance: One EC2 instance, inside a VPC, with a public ip
 - ec2-with-bastion: One EC2 instance with the port 80 open, but with ssh open
   on another VPC, where there is a bastion which is the only point of entry to
   connect to the web server.
 - elasticbeanstalk-php: A simple Elastic Beanstalk php application, where it's
   possible to deploy multiple versions of it from the eb command line.
 - load-balancer-web: A php web application that runs on multiple servers behind
   a load balancer.
