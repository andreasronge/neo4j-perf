require 'rubygems'
require "bundler/setup"
require 'neo4j'
require 'benchmark'
require 'tx_util'

module NeoModel
  class File
    include Neo4j::NodeMixin
    property :file_id, :name, :description, :size
    has_one :folder

    def to_s
      "File #{name}"
    end
  end

  class Folder
    include Neo4j::NodeMixin
    property :folder_id, :name, :description, :size
    has_one :parent_folder

    has_n(:files).from(NeoModel::File, :folder)
    has_n(:child_folders).from(NeoModel::Folder, :parent_folder)

    def to_s
      "Folder #{name}"
    end
  end

end