require File.dirname(__FILE__) + '/../spec_helper'

describe Calendar do
  before :each do
    @calendar = Calendar.new
  end
  
  it "is a kind of Section" do
    @calendar.should be_kind_of(Section)
  end

  it "has many events" do
    @calendar.should have_many(:events)
  end

  it "has many categories" do
    @calendar.should have_many(:categories)
  end

  it ".content_type returns 'CalendarEvent'" do
    Calendar.content_type.should == 'CalendarEvent'
  end
  
end