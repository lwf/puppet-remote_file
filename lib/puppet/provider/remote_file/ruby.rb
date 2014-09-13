require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'

require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'remote_file'

Puppet::Type.type(:remote_file).provide(:ruby, :parent => Puppet::Provider::Remote_file) do
  desc "remote_file using Net::HTTP from Ruby's standard library."

  mk_resource_methods

  def create
    get @resource[:source]
  end

  private

  def get(url, i=0)
    p = URI.parse url
    case p.scheme
    when /https?/
      http_get p, i
    when "file"
      FileUtils.copy p.path, @resource[:path]
    end
  end

  def http_get(p, i=0)
    if i > 5
      raise Puppet::Error.new "Redirected more than 5 times when trying to download #{@resource[:path]}, aborting."
    end
    c = Net::HTTP.new(p.host, p.port)
    c.use_ssl = p.scheme == "https" ? true : false
    if c.use_ssl? and @resource[:verify_peer] == false
      c.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    c.request_get(p.request_uri) do |req|
      case req.code
      when /30[12]/
        get req['location'], i+1
      when "200"
        File.open(@resource[:path], 'w') do |fh|
          req.read_body { |buf| fh.write buf }
          fh.flush
        end
      else
        raise Puppet::Error.new "Unexpected response code #{req.code}: #{req.read_body}"
      end
    end
  end
end
