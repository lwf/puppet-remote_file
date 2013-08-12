require 'digest/md5'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'

Puppet::Type.type(:remote_file).provide(:ruby) do
  desc "remote_file using Net::HTTP from Ruby's standard library."

  mk_resource_methods

  def create
    get @resource[:source]
  end

  def destroy
    File.unlink @resource[:name]
  end

  def exists?
    if File.file? @resource[:name]
      if cs = @resource[:checksum]
        Digest::MD5.file(@resource[:name]) == cs
      else
        true
      end
    end
  end

  private

  def get(url, i=0)
    p = URI.parse url
    case p.scheme
    when /https?/
      http_get p, i
    when "file"
      FileUtils.copy p.path, @resource[:name]
    end
  end

  def http_get(p, i=0)
    if i > 5
      raise InfiniteRedirect.new "Redirected more than 5 times, aborting."
    end
    c = Net::HTTP.new(p.host, p.port)
    c.use_ssl = p.scheme == "https" ? true : false
    c.request_get(p.path) do |req|
      case req.code
      when /30[12]/
        get req['location'], i+1
      when "200"
        File.open(@resource[:name], 'w') do |fh|
          req.read_body { |buf| fh.write buf }
          fh.flush
        end
      end
    end
  end
end
