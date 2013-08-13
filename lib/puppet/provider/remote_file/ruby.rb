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
      FileUtils.copy p.path, @resource[:name]
    end
  end

  def http_get(p, i=0)
    if i > 5
      raise InfiniteRedirect.new "Redirected more than 5 times, aborting."
    end
    c = Net::HTTP.new(p.host, p.port)
    c.use_ssl = p.scheme == "https" ? true : false
    c.request_get(p.request_uri) do |req|
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
