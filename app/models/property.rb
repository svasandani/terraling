class Property < ActiveRecord::Base
  validates_presence_of :name, :category, :group
  validates_uniqueness_of :name, :scope => :group_id
  validates_existence_of :group, :category
  validates_existence_of :creator, :allow_nil => true
  validate :group_association_match

  belongs_to :group
  belongs_to :category
  belongs_to :creator, :class_name => "User"
  has_many :lings_properties, :dependent => :destroy

  include Extensions::Selects
  include Extensions::Wheres
  include Extensions::Orders
  # override
  scope :at_depth, lambda { |depth| scoped & Category.at_depth(depth) }

  def depth
    category.depth
  end

  def group_association_match
    errors.add(:category, "#{group.category_name.humanize} must belong to the same group as this #{group.property_name}") if group && category && category.group != group
  end
end
