#!/usr/local/bin/ruby

require 'optparse'
require 'fileutils'

require 'optparse'
require 'ostruct'



def main
  @@options = OpenStruct.new

  OptionParser.new do |opts|
    opts.banner = "Usage: image_grab.rb [options]"
    opts.on("-d", "--disk DISK", String, "disk location") do |d|
      @@options.disk = d
    end
    opts.on("-c", "--camera CAMERA", String,  "use CAMERA as camera name prefix") do |c|
      @@options.camera = c
    end
  end.parse!


  disk = @@options.disk || guess_disk

  $stderr.puts "looking for images in #{disk}"
  begin
    dirs = Dir.open("#{disk}/DCIM").visible_entries
  rescue Errno::ENOENT
    $stderr.puts "#{disk} doesn't seem to be a Canon flash drive"
    exit 1
  end

  dirs.each do |dname|
    d = Dir.open("#{disk}/DCIM/#{dname}")
    process_dir(d)
  end

end


class Dir
  def visible_entries
    self.entries.collect do |e|
      if e.match(/^\./) 
        nil
      else
        e
      end
    end.compact
  end
end




def process_dir(d)
  path = d.path
  
  if md = d.path.match(/(\d+)(\D.+)$/)
    dirnum = md[1]
    camera = @@options.camera || md[2]
    d.visible_entries.each do |filename|
      num = filenum(filename)
      ext = fileext(filename)
      file = File.open("#{path}/#{filename}")
      dirname = sprintf("%04d-%02d-%02d", file.mtime.year, file.mtime.month, file.mtime.day)
      FileUtils.mkdir_p(dirname)
      new_name = "#{dirname}/#{camera}-#{dirnum}-#{num}.#{ext}"
      FileUtils.cp(file.path, new_name, :preserve => true)
      puts new_name
    end  
  end
end

def filenum(filename)
  md = filename.match(/\D+(\d+)/)
  return md[1]
end

def fileext(filename)
  md = filename.match(/\.([^\.]+)$/)
  return md[1]
end



def guess_disk
  volumes = Dir.open("/Volumes")
  volumes.visible_entries.each do |d|
    if d.match(/CANON/)
      return "/Volumes/#{d}"
    end
  end
end



main()
