
# load all files from gsv_cutter directory
path = File.expand_path(File.join(File.dirname(__FILE__), "gsv_cutter"))
$LOAD_PATH << path
Dir[ File.join(path, "*.rb") ].each { |file|
	require File.basename(file)
}

module Enumerable
  # Does not sort the values; do this yourself before calling if you like
  def median( &blk )
    values = blk ? map( &blk ) : self
    values[ values.length / 2 ]
  end
  def sum( &blk )
    values = blk ? map( &blk ) : self
    values.inject(0){ |sum,v| sum + v }
  end
  def average( &blk )
    (length==0) ? 0 : (sum( &blk ) * 1.0 / length)
  end
  alias_method :avg, :average
  def std_dev( &blk )
    values = blk ? map( &blk ) : self
    mean = values.average
    Math.sqrt( values.map{ |value| (value-mean)*(value-mean) }.average )
  end
  def dups_by
    keyvals = Hash.new{|h,v|h[v]=[]}
    each{ |v|   keyvals[yield(v)] << v }
    result = []
    keyvals.each{ |k,v| result << v if v.length > 1 }
    result
  end  
end