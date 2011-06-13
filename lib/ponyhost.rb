require 'yaml'
require 'aws/s3'
require 'socket'
require 'digest/md5'

# monkey patch to add website to extract significant parameter
class AWS::S3::Authentication::CanonicalString
  def extract_significant_parameter
    request.path[/[&?](acl|torrent|logging|website)(?:&|=|$)/, 1]
  end
end


class PonyHost
  S3_CREDENTIAL_FILES = ["~/.s3website.yml", "./.s3website.yml"]
  DEFAULT_DOMAIN = "lolcat.biz"
  VERSION = "0.1"
  class << self 
    

    def obtain_credentials
      credential_file = File.expand_path("~/.s3website")
      if File.exists?(credential_file)
        return YAML.load_file(credential_file)
      else
        puts "AWS Credentials file '#{credential_file}' missing. We'll create one:"
        #http://aws.amazon.com/account/
        credentials = {}
        puts "Your AWS Access Key ID:"
        credentials[:access_key_id] = STDIN.gets.chop
        puts "Your AWS Access Key Secret:"
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
      s=TCPServer.new(port);
      puts "Server running on http://localhost:#{port}"
      loop do 
        _ = s.accept
        requested_filename = _.gets.split[1]
        requested_filename = "/index.html" if requested_filename == "/"
        begin
          data = File.read(".#{requested_filename}")
          status = 200
        rescue 
          status = 404
          if File.exists?("404.html")
            data = File.read("404.html")
          else
            data = "#{requested_filename} not found and no 404.html error page either."
          end
        end
        status_msg = status == 200 ? "OK" : "NOT FOUND"
        _ << "HTTP/1.0 #{status} #{status_msg}\r\n\r\n#{data}";

        puts %Q{[#{Time.now}] "GET #{requested_filename}" #{status}} 
        _.close
      end
    end

    def md5sum(file_name)
      Digest::MD5.hexdigest(File.read(file_name))
    end

    def flat_list_directory(dir, path = "")
      list = []
      dir.each do |entry|
        unless [".", ".."].include?(entry)
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