class Coach < ActiveRecord::Base
  # Remember to create a migration!
  #add validation
  validates_presence_of :name
  validates_presence_of :email
  validates_presence_of :phone
  has_many :clients
end

def find_by_name(name)
  Coach.where(:name => name).first
end

def find_by_id(id)
  Coach.find(id)
end
