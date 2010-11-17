require 'fileutils'
require 'model'

@@counter = 0

def traverse(start_path)
  if @@counter % 100 == 0
    new_tx
  end

  parent_folder = NeoModel::Folder.new(:folder_name => File.basename(start_path), :description => "Description of folder at #{start_path}")
  Dir.new(start_path).each do |entry|
    path = start_path + "/" + entry
    if (FileTest.directory?(path) && entry != "." && entry != "..")
      putc "d"
      folder               = traverse(path)
      folder.parent_folder = parent_folder
    elsif (FileTest.file?(path))
      putc "-"
      file        = NeoModel::File.new(:file_name   => entry,
                                       :description => entry.inspect(),
                                       :size        => File.size(path))
      file.folder = parent_folder
      @@counter   += 1
    end
  end
  parent_folder
end

puts "Traverse "
new_tx
folder = traverse("/home/andreas/projects")
Neo4j::Relationship.new(:root, Neo4j.ref_node, folder)
#Neo4j.ref_node.outgoing(:root) << folder - not available in Neo4j 0.4.6
finish_tx
puts "added #{@@counter} files"
