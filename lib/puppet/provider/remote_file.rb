require 'digest/md5'

class Puppet::Provider::Remote_file < Puppet::Provider
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
end
