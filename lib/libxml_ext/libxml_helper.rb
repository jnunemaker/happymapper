require "xml/libxml"
 
class XML::Node
  ##
  # Open up XML::Node from libxml and add convenience methods inspired
  # by hpricot.
  # (http://code.whytheluckystiff.net/hpricot/wiki/HpricotBasics)
  
  # find the child node with the given xpath
  def at(xpath)
    self.find_first(xpath)
  end
 
  # find the array of child nodes matching the given xpath
  def search(xpath)
    results = self.find(xpath).to_a
    if block_given?
      results.each do |result|
        yield result
      end
    end
    return results
  end
 
  # alias for search
  def /(xpath)
    search(xpath)
  end
 
  # return the inner contents of this node as a string
  def inner_xml
    child.to_s
  end
 
  # alias for inner_xml
 def inner_html
    inner_xml
  end
 
  # return this node and its contents as an xml string
  def to_xml
    self.to_s
  end
 
  # alias for path
  def xpath
    self.path
  end
end
 
class String
  def to_libxml_doc
    XML::Parser.string(self).parse
  end
end
