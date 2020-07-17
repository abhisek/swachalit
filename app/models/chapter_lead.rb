class ChapterLead < ActiveRecord::Base
  audited

  # attr_accessible :title, :body
  attr_accessible :user_id, :chapter_id, :active
  validates :user_id, :uniqueness => { :scope => [:chapter_id], :message => 'is already a leader of this chapter.' }

  belongs_to :chapter
  belongs_to :user

  scope :active, lambda { where(:active => true) }

  def self.leadership_for_user(user)
    ChapterLead.where(user_id: user.id)
  end
end
