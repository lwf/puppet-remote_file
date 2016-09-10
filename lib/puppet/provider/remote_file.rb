require 'digest/md5'
require 'puppet/util/checksums'

class Puppet::Provider::Remote_file < Puppet::Provider
  include Puppet::Util::Checksums 

  def destroy
    File.unlink @resource[:path]
  end

  def exists?
    File.file?(@resource[:path]) &&
      (!checksum_specified? || specified_checksum == calculated_checksum)
  end

  # Return true if the resource specifies a checksum
  #
  def checksum_specified?
    !specified_checksum.nil?
  end

  # Return the resource checksum
  #
  def specified_checksum
    @resource[:checksum]
  end

  # Return the checksum calculated from the local resource.
  #
  def calculated_checksum
    send("#{@resource[:checksum_type]}_file".to_sym, @resource[:path]) 
  end
end
