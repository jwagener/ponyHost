# ponyHost #
## Description ##

ponyHost lets you to easily create Amazon S3 website buckets,
push files to them and make them available under a *.ponyho.st or custom domain.
A small HTTP server is also included.

## Installation ##

To use ponyHost all you need to have is an Amazon S3 
account and the [access key id and secret](https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key).

The installation is as simple as:

      $ gem install ponyhost

## Commands ##
### Create ###

      $ ponyhost create your-site

  Will create the S3 bucket with a website configuration.
  Per default index.html will be the index document and 404.html the error document.
  
  If the passed name doesn't include a '.' the default domain 'ponyho.st' will be used and your bucket will be named
  'your-site.ponyho.st'.
  
  If you prefer to use a custom domain just pass the name accordingly.
  
      $ ponyhost create foo.yoursite.com
      
  You'll have to setup a DNS CNAME record for foo.yoursite.com to s3-website-us-east-1.amazonaws.com.
  It's also possible to use a naked domain like yoursite.com. 
  For that you have to point the @ record for yoursite.com to
  one of the IP's that s3-website-us-east-1.amazonaws.com points to (72.21.207.127) (not so good, but works :)

### Push ###

      $ ponyhost push your-site

  Will compare the md5 sum for each file in the current directory with the remote file and push the file if necessary.
  Currently it won't delete files in the bucket.

### Server ###

      $ ponyhost server
  
  Runs a very basic HTTP server for the current directory on http://localhost:9090
  
### Destroy ###
      
      $ ponyhost destroy your-site

  Will delete the bucket and all files on S3.

## ToDo ##

* Implement a autopush command
* Implement a robust HTTP server
* Support other availability zones
* Delete files in bucket
