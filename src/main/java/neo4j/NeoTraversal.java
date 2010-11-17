package neo4j;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.neo4j.graphdb.Direction;
import org.neo4j.graphdb.DynamicRelationshipType;
import org.neo4j.graphdb.GraphDatabaseService;
import org.neo4j.graphdb.Node;
import org.neo4j.graphdb.Relationship;
import org.neo4j.graphdb.Transaction;
import org.neo4j.kernel.EmbeddedGraphDatabase;

public class NeoTraversal
{
    private static final String DB_PATH = "tmp/neo4j";
    public static final int NUM_ITERATIONS = 25;
    
    private GraphDatabaseService db;
	private Transaction tx;

	private int traversed;
	
    NeoTraversal() {
        db = new EmbeddedGraphDatabase( DB_PATH );
        registerShutdownHook( db );
    	tx = db.beginTx();
    }

    public void shutdown() {
    	if (tx != null) {
    		tx.finish();
    	}
        System.out.println( "Shutting down database ..." );
    	db.shutdown();
    }

    public long visitRefNode() {
    	traversed = 1;
    	long size = 0;
    	Relationship rel = db.getReferenceNode().getSingleRelationship(DynamicRelationshipType.withName("root"), Direction.OUTGOING);
    	Node root = rel.getEndNode();
        size = visitFolder(root);
    	return size;
    }
    
    static void props(Node node) {
    	System.out.println("Node:: " + node);
		// TODO Auto-generated method stub
		for (String key : node.getPropertyKeys()) {
			System.out.println(key + " => " + node.getProperty(key));
		}
    }
    
    static void rels(Node node) {
    	Map<String, Integer> relTypes = new HashMap<String, Integer>();
    	for (Relationship rel : node.getRelationships()) {
    		Integer count = relTypes.get(rel.getType().name());
    		if (count == null) {
    			count = 0;
    		}
			relTypes.put(rel.getType().name(), count + 1);
    	}
    	for (Map.Entry<String, Integer> entry : relTypes.entrySet()) {
    		System.out.println(entry.getKey() + " => " + entry.getValue());
    	}
    }

	private long visitFolder(Node folder) {
		long size = 0;
		++traversed;
		for (Relationship child : folder.getRelationships(DynamicRelationshipType.withName("folder"))) {
   			size += visitFile(child.getOtherNode(folder));
    	}
		for (Relationship child : folder.getRelationships(DynamicRelationshipType.withName("parent_folder"), Direction.INCOMING)) {
			size += visitFolder(child.getOtherNode(folder));
    	}
    	return size;
    }

	public int traversed() {
		return traversed;
	}
	
    private long visitFile(Node file) {
    	++traversed;
		return ((Number) file.getProperty("size")).longValue(); // Runs around 20 s for all iterations ...
	}

	public static void main( final String[] args )
    {
    	NeoTraversal traverser = new NeoTraversal();
        try
        {
        	for (int i = 1; i <= NUM_ITERATIONS; ++i) {
	            long size = 0;
	            long startDate = new Date().getTime();
	        	size = traverser.visitRefNode();
	            System.out.println(i + " -- traversed " + traverser.traversed() + " nodes, " + size + " bytes, in "
	            		+ (new Date().getTime() - startDate) / 1000.0 + " seconds");
        	}
        }
        finally
        {
            traverser.shutdown();
        }
    }

    private static void registerShutdownHook( final GraphDatabaseService graphDb )
    {
        // Registers a shutdown hook for the Neo4j instance so that it
        // shuts down nicely when the VM exits (even if you "Ctrl-C" the
        // running example before it's completed)
        Runtime.getRuntime().addShutdownHook( new Thread()
        {
            @Override
            public void run()
            {
                graphDb.shutdown();
            }
        } );
    }
}
