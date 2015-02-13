class Object
  def in?(*array)
    array = array.first if array.first.is_a?(Array)
    array.include?(self)
  end
end

