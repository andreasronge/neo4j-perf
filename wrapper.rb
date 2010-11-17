include Java

require 'model'
DB_PATH = "tmp/neo4j"


class Neo4jTraversal
  attr_reader :traversed

  def visit_ref_node
    @traversed = 1
    rel        = Neo4j.ref_node._rel(:outgoing, 'root')
    root       = rel._end_node
    traverse(root)
  end

  def traverse(folder)
    size = folder[:size] || 0
    folder.incoming(:parent_folder).incoming(:folder).depth(:all).iterator.each do |node|
      size += node[:size] if node.property?(:size) #&& node.property?(:file_id)
      @traversed += 1
    end
    size
  end

  def shutdown
    Neo4j.shutdown
  end
end


trav       = Neo4jTraversal.new
TIMES      = 25

total_time = 0
TIMES.times.each do |i|
  start_time = Time.now
  size       = trav.visit_ref_node
  delta      = Time.now - start_time
  puts "#{i+1} -- traversed #{trav.traversed} nodes #{size} bytes, in #{delta} seconds"
  total_time += delta
end

trav.shutdown
