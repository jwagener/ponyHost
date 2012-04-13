require 'yaml'
require 'aws/s3'
require 'webrick'
require 'digest/md5'


# monkey patch to add website to extract significant parameter
class AWS::S3::Authentication::CanonicalString
  def extract_significant_parameter
    request.path[/[&?](acl|torrent|logging|website)(?:&|=|$)/, 1]
  end
end


class PonyHost
  S3_CREDENTIAL_FILES = ["~/.ponyhost.yml"]
  S3_CREDENTIAL_LINK = "https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key"
  DEFAULT_DOMAIN = "ponyho.st"
  VERSION = "0.3.4"
  class << self 
    

    def obtain_credentials
      credential_file = File.expand_path(S3_CREDENTIAL_FILES.first)
      if File.exists?(credential_file)
        return YAML.load_file(credential_file)
      else
        puts "AWS Credentials file '#{credential_file}' is missing."
        puts "Please insert your Amazon AWS S3 credentials. You can look them up on http://j.mp/aws-keys"
        puts "In case you don't have signed up for S3 yet you can do that on http://j.mp/s3-signup"

        credentials = {}
        print "Your AWS Access Key ID: "
        credentials[:access_key_id] = STDIN.gets.chop
        print "Your AWS Access Key Secret: "
        credentials[:access_key_secret] = STDIN.gets.chop
        File.open(credential_file, "w") {|file| file.puts(credentials.to_yaml) }
        return credentials
      end
    end

    def create(bucketname)
      bucket = AWS::S3::Bucket.create(bucketname, :access => :public_read)  

      body = '<?xml version="1.0" encoding="UTF-8"?>
      <WebsiteConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
        <IndexDocument><Suffix>index.html</Suffix></IndexDocument>
        <ErrorDocument><Key>404.html</Key></ErrorDocument>
      </WebsiteConfiguration>'

      res = AWS::S3::Base.request(:put, "/#{bucketname}?website", {}, body)

      puts "Site created: http://#{bucketname}"
      puts "Push your files with: ponyhost push #{bucketname}"
    end

    def push(bucketname, directory = ".")
      bucket = AWS::S3::Bucket.find(bucketname)
      file_names = flat_list_directory(Dir.new(directory))

      file_names.each do |file_name|
        local_md5 = md5sum(file_name).chomp    
        remote_md5 = bucket[file_name] && bucket[file_name].about["etag"].gsub('"', '').chomp
        if local_md5.to_s == remote_md5.to_s
          puts "Skipping \t#{file_name}"
        else
          puts "Pushing \t#{file_name}"
          AWS::S3::S3Object.store(file_name, open(file_name), bucketname,  :access => :public_read)
        end
      end  
    end

    def list
      AWS::S3::Service.buckets.map(&:name)
    end

    def destroy(bucketname)
      AWS::S3::Bucket.delete(bucketname, :force => true)
      puts "'#{bucketname} is destroyed"
    end

    def show(bucketname)
      res = AWS::S3::Base.request(:get, "/#{bucketname}?website") rescue res = $!
      puts res  
    end

    def server(port=9090)      
      s = WEBrick::HTTPServer.new(:Port => port,  :DocumentRoot => Dir.pwd); trap('INT') { s.shutdown }; s.start
    end

    def md5sum(file_name)
      Digest::MD5.hexdigest(File.read(file_name))
    end

    def flat_list_directory(dir, path = "")
      list = []
      dir.each do |entry|
        unless [".", "..", ".git"].include?(entry)
          full_entry_path = path == "" ? entry : [path, entry].join("/")
          if File.directory?(full_entry_path)
            list += flat_list_directory(Dir.new(full_entry_path), full_entry_path)
          else
            list << full_entry_path
          end
        end
      end
      list
    end
  
    def normalize_bucketname(bucketname)
      if bucketname.include?(".")
        bucketname
      else
        "#{bucketname}.#{DEFAULT_DOMAIN}"
      end
    end    
  end
end
