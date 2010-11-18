include Java

require 'fileutils'

require "jars/neo4j-kernel-1.2-1.2.M03.jar"
require "jars/geronimo-jta_1.1_spec-1.1.1.jar"

DynamicRelationshipType = org.neo4j.graphdb.DynamicRelationshipType
Direction               = org.neo4j.graphdb.Direction


DB_PATH = "#{File.dirname(__FILE__)}/tmp/neo4j"


class BatchImport
  attr_reader :counter
  
  def initialize
    @inserter = org.neo4j.kernel.impl.batchinsert.BatchInserterImpl.new(DB_PATH)
    @counter = 1
    puts "Creating db at #{DB_PATH}"
  end
  
  def create_folder(name, desc)
    props = {'folder_name' => name, 'description' => desc, '_classname' => 'NeoModel::Folder'}
    @counter   += 1
    @inserter.create_node(props)
  end

  def create_file(name, desc, size)
    props = {'file_name' => name, 'description' => desc, 'size' => size, '_classname' => 'NeoModel::File'}
    @counter   += 1
    @inserter.create_node(props)
  end

  def import(start_path)
    root_folder = traverse(start_path)
    create_rel(@inserter.reference_node, root_folder, 'root')
  end

  def create_rel(a, b, rel)
    @inserter.create_relationship(a, b, DynamicRelationshipType.withName(rel), nil)
  end
  
  def traverse(start_path)
    parent_folder = create_folder(File.basename(start_path), "Description of folder at #{start_path}")
    Dir.new(start_path).each do |entry|
      path = start_path + "/" + entry
      if (FileTest.directory?(path) && !File.symlink?(path) && entry != "." && entry != ".." && path != DB_PATH)
        putc "d"
        folder               = traverse(path)
        create_rel(folder, parent_folder, 'parent_folder')
      elsif (FileTest.file?(path))
        putc "-"
        file        = create_file(entry, entry.inspect(), File.size(path))
        create_rel(file, parent_folder, 'folder')
      end
    end
    parent_folder
  end

  def shutdown
    @inserter.shutdown
  end
end


db = BatchImport.new
db.import(ARGV[0])

puts "\nImported #{db.counter} files and folders to #{DB_PATH}"
db.shutdown
