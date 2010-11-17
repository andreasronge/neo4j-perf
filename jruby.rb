#!/usr/bin/env jruby -J-Xms2048m -J-Xmx2048m -J-Xmn512m --server --fast -J-Djruby.compile.fastest=true -J-Dcom.sun.management.jmxremote

include Java

require 'model'

require "jars/neo4j-kernel-1.2-1.2.M03.jar"
require "jars/geronimo-jta_1.1_spec-1.1.1.jar"


DB_PATH                 = "tmp/neo4j"

DynamicRelationshipType = org.neo4j.graphdb.DynamicRelationshipType
Direction               = org.neo4j.graphdb.Direction

class RubyTraversal
  attr_reader :traversed

  def initialize
    @db = org.neo4j.kernel.EmbeddedGraphDatabase.new(DB_PATH)
  end

  def visit_ref_node
    @traversed = 1
    rel        = @db.getReferenceNode().getSingleRelationship(DynamicRelationshipType.withName("root"), Direction::OUTGOING)
    root       = rel.getEndNode
    visit_folder(root)
  end

  def visit_folder(folder)
    size       = 0
    @traversed += 1
    folder.getRelationships(DynamicRelationshipType.withName("folder")).each do |rel|
      size += visit_file(rel.getOtherNode(folder))
    end

    folder.getRelationships(DynamicRelationshipType.withName("parent_folder"), Direction::INCOMING).each do |rel|
      size += visit_folder(rel.getOtherNode(folder))
    end
    size
  end

  def visit_file(file)
    @traversed += 1
    file.getProperty("size")
  end

  def shutdown
    @db.shutdown
  end
end



trav = RubyTraversal.new
TIMES = 25

total_time = 0
TIMES.times.each do |i|
  start_time = Time.now
  size       = trav.visit_ref_node
  delta = Time.now - start_time
  puts "#{i+1} -- traversed #{trav.traversed} nodes #{size} bytes, in #{delta} seconds"
  total_time += delta
end

trav.shutdown
