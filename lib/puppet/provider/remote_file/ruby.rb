require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'

require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'remote_file'

Puppet::Type.type(:remote_file).provide(:ruby, :parent => Puppet::Provider::Remote_file) do
  desc "remote_file using Net::HTTP from Ruby's standard library."

  mk_resource_methods

  REQUEST_TYPES = {
    'get'  => Net::HTTP::Get,
    'head' => Net::HTTP::Head,
  }

  def create
    get @resource[:source]
    validate_checksum if checksum_specified?
  end

  private

  def validate_checksum
    raise Puppet::Error.new "Inconsistent checksums. Checksum of fetched file is #{calculated_checksum}. You specified #{specified_checksum}" if calculated_checksum != specified_checksum
  end

  def specified_checksum
    @resource[:checksum]
  end

  def calculated_checksum
    Digest::MD5.file(@resource[:name]) 
  end

  def checksum_specified?
    ! specified_checksum.nil?
  end

  # Determine and begin the appropriate method of getting the target file.
  #
  def get(url)
    p = URI.parse url
    case p.scheme
    when /https?/
      http_get p, @resource[:path]
    when "file"
      FileUtils.copy p.path, @resource[:path]
    end
  end

  # Perform an HTTP GET request, saving the body in the specified download
  # path, and return the result.
  #
  def http_get(uri, download_path)

    # We'll save to a tempfile in case something goes wrong in the download
    # process. This avoids accidentally overwriting an old version, or
    # leaving a partially downloaded file in place
    begin
      tempfile = Tempfile.new('remote_file')
      response = http(uri, tempfile)

      # If download was successful, copy the tempfile over to the resource path.
      if response.kind_of?(Net::HTTPSuccess)
        tempfile.flush
        FileUtils.mv(tempfile.path, download_path)
      end
    ensure
      tempfile.close
      tempfile.unlink
      response
    end
  end

  # Use Net::HTTP to perform a request against a webserver, following
  # redirects, and return the final response. This method accepts a uri, an io
  # object to which the response body will be saved in the event of an
  # HTTPSuccess response from the webserver, and an optional hash of options.
  # The method will follow HTTPRedirect codes up to 10 times, and will return
  # the final HTTPResponse.
  #
  # @param uri [URI::HTTP] the uri to perform the request against
  # @param io_ready_to_write [IO] an open file or other IO object ready to
  #        write. The response body will be written to this object.
  # @param options [Hash] a hash of options to adjust behavior
  #
  def http(uri, io_ready_to_write, options = {})
    verb    = options[:http_method] || 'get'
    limit   = options[:limit]       || 10

    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    # Create the Net::HTTP connection and  request objects
    connection = Net::HTTP.new(uri.host, uri.port)
    request    = REQUEST_TYPES[verb.to_s.downcase].new(uri.request_uri)

    # Configure the Net::HTTP connection object
    if uri.scheme == 'https'
      connection.use_ssl = true
    end

    if connection.use_ssl? and @resource[:verify_peer] == false
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    # Configure the Net::HTTPRequest object
    if options[:headers]
      options[:headers].each {|key,value| request[key] = value }
    end

    # Connect and perform the request
    http_method = connection.method("request_#{verb.downcase}".to_sym)
    recursive_response = nil
    response = connection.start do |http|
      http.request(request) do |resp|
        # Determine and react to the request result
        case resp
        when Net::HTTPRedirection
          next_opts = options.merge(:limit => limit - 1)
          next_loc  = URI.parse(resp['location'])
          recursive_response = http(next_loc, io_ready_to_write, next_opts)
        when Net::HTTPSuccess
          resp.read_body do |chunk|
            io_ready_to_write.write(chunk)
          end
        else
          raise Puppet::Error.new "Unexpected response code #{resp.code}: #{resp.read_body}"
        end
      end
    end

    recursive_response || response
  end
end
