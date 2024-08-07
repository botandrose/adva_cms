class TagList < Array
  cattr_accessor :delimiter
  self.delimiter = ' '
  
  attr_reader :owner
  
  def initialize(*names)
    add(*names)
  end
  
  # Add tags to the tag_list. Duplicate or blank tags will be ignored.
  #
  #   tag_list.add("Fun", "Happy")
  # 
  # Use the <tt>:parse</tt> option to add an unparsed tag string.
  #
  #   tag_list.add("Fun, Happy", :parse => true)
  def add(*names)
    extract_and_apply_options!(names)
    concat(names)
    clean!
    self
  end
  
  # Remove specific tags from the tag_list.
  # 
  #   tag_list.remove("Sad", "Lonely")
  #
  # Like #add, the <tt>:parse</tt> option can be used to remove multiple tags in a string.
  # 
  #   tag_list.remove("Sad, Lonely", :parse => true)
  def remove(*names)
    extract_and_apply_options!(names)
    delete_if { |name| names.include?(name) }
    self
  end

  # Add additional tags to effectively make the tag list plurality-insensitive.
  #
  #   tag_list = TagList.new("One", "Twos")
  #   tag_list.cover_pluralities!
  #   tag_list.to_s # "One, Ones, Two, Twos"
  def cover_pluralities!
    clean!
    new_tag_list = inject([]) do |tag_list, name|
      tag_list << name.singularize
      tag_list << name.pluralize
      tag_list
    end
    replace new_tag_list
  end
  
  # Transform the tag_list into a tag string suitable for edting in a form.
  # The tags are joined with <tt>TagList.delimiter</tt> and quoted if necessary.
  #
  #   tag_list = TagList.new("Round", "Square,Cube")
  #   tag_list.to_s # 'Round, "Square,Cube"'
  def to_s
    clean!
    
    map do |name|
      name.include?(delimiter) ? "\"#{name}\"" : name
    end.join(delimiter.end_with?(" ") ? delimiter : "#{delimiter} ")
  end
  
 private
  # Remove whitespace, duplicates, and blanks.
  def clean!
    reject!(&:blank?)
    map!(&:strip)
    uniq!(&:downcase)
  end
  
  def extract_and_apply_options!(args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.assert_valid_keys :parse
    
    if options[:parse]
      args.map! { |a| self.class.from(a) }
    end
    
    args.flatten!
  end
  
  class << self
    # Returns a new TagList using the given tag string.
    # 
    #   tag_list = TagList.from("One , Two,  Three")
    #   tag_list # ["One", "Two", "Three"]
    def from(*strings)
      strings = strings.flatten
      new.tap do |tag_list|
        strings.each do |string|
          string = string.to_s.dup
      
          # Parse the quoted tags
          string.gsub!(/"(.*?)"\s*#{delimiter}?\s*/) { tag_list << $1; "" }
      
          tag_list.add(string.split(delimiter))
        end
      end
    end
  end
end
