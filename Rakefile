require 'rake/clean'
require 'fileutils'

CLEAN.include "tmp", "target/*"
CLOBBER.include "*.log"

NEO_JARS="jars/neo4j-kernel-1.2-1.2.M03.jar:jars/geronimo-jta_1.1_spec-1.1.1.jar"

def ask(message)
  print message
  STDIN.gets.chomp
end

def yes_no(message)
  reply = ask(message + " (y/n) ")
  puts "GOT REPLY #{reply}"
  reply.first == 'y' || reply.first == 'Y'
end

task :compile do
  sh "mkdir -p target"
  sh "javac -cp #{NEO_JARS} -d target src/main/java/neo4j/NeoTraversal.java"
end

desc "Run Java Neo4j Performance Tests"
task :java => :compile do
  sh "java -Xms2048m -Xmx2048m -Xmn512m -server -cp #{NEO_JARS}:target neo4j.NeoTraversal"
end

desc "create db"
task "create" do
  loc = ask "location? "
  puts "loc #{loc}"
  fail "No folder at '#{loc}'" unless File.exist?(loc)
  if File.exist?('tmp')
    if yes_no("delete old database at ?")
      FileUtils.rm_rf('tmp')
    else
      puts "Exit. You need to delete the old database first"
      exit
    end
  end
  sh "jruby batch_import.rb #{loc}"
end

desc "Run just using Neo4j.rb wrapper"
task :wrapper do
  sh "/usr/bin/env jruby -J-Xms2048m -J-Xmx2048m -J-Xmn512m --server wrapper.rb"
end


desc "Run just using JRuby api to Java"
task :jruby do
  sh "/usr/bin/env jruby -J-Xms2048m -J-Xmx2048m -J-Xmn512m --server jruby.rb"
end
