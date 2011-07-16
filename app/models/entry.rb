class Entry < ActiveRecord::Base
  has_many :entry_amounts
  has_many :credits
  has_many :debits
  has_many :accounts, :through => :entry_amounts
  accepts_nested_attributes_for :credits
  accepts_nested_attributes_for :debits

  validates_size_of :credits, :minimum => 1
  validates_size_of :debits, :minimum => 1
  validate :credits_and_debits_must_balance

  validates :type,
            :presence => true,
            :exclusion => { :in => ['Entry'] }

  def destroy
    raise ActiveRecord::IndestructibleRecord
  end

private

  def credits_and_debits_must_balance
    credits.sum(:amount_in_cents) == debits.sum(:amount_in_cents)
  end

end