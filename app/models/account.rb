class Account < ActiveRecord::Base
  include AccountMethods

  ACCOUNT_TYPES = ["Asset", "Liability", "Equity", "Revenue", "Expense"]

  serialize :attrs

  validates :name,
            :presence => true,
            :uniqueness => true

  validates :type,
            :presence => true

  has_many :entries
  has_many :entry_amounts, :through => :entries

  acts_as_nested_set

  state_machine :initial => :active do

  end

  def destroy
    raise ActiveRecord::IndestructibleRecord
  end

  def as_base
    self.becomes(Account)
  end

#  account_types[5] ="Gain"
#  account_types[6] ="Loss"
#  account_types[7] ="Distribution from Equity"
#  account_types[8] ="Contribution to Equity"
#  account_types[9] ="Comprehensive Income"
#  account_types[10] ="Other"
end
