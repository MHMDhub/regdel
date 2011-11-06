###
# Program:: http://www.regdel.com
# Component:: regdel_dm.rb
# Copyright:: Savonix Corporation
# Author:: Albert L. Lash, IV
# License:: Gnu Affero Public License version 3
# http://www.gnu.org/licenses
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, see http://www.gnu.org/licenses
# or write to the Free Software Foundation, Inc., 51 Franklin Street,
# Fifth Floor, Boston, MA 02110-1301 USA
##
require 'rubygems'
require 'bigdecimal'
require 'bigdecimal/util'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-serializer'
require 'dm-aggregates'
require 'dm-validations'

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3:///var/www/dev/regdel/rbeans.sqlite3')


# The Account class includes all the accounts held by the business,
# organization, or other entity with numerous financial accounts
class Account
  include DataMapper::Resource

  PUB_ATTR = [:name,:type_id,:number,:description,:hide]
  ACCTYPES = ['Assets','Liabilities','Equity','Revenues','Expenses','Gain','Loss','Distribution from Equity','Contribution to Equity','Comprehensive Income','Other']
  NOTFOUND = 'No account found'
  name_length_error = 'Name is too long or too short.'

  property :id,Serial
  property :number,String
  property :name,String
  property :type_id,Integer
  property :description,Text
  property :created_on,Integer, :default => Time.now.to_i
  property :closed_on,Integer, :default => 0
  property :hide,Boolean
  property :group_id,Integer
  property :cached_ledger_balance,Integer, :default => 0
  has n, :credits
  has n, :debits
  has n, :ledgers
  validates_present :name
  validates_length :name, :max => 12, :message => name_length_error
  validates_length :name, :min => 2, :message => name_length_error
  validates_is_unique :name

  # Return only accounts that have not been closed yet.
  def self.open
    all(:closed_on => 0)
  end

  # The most recent ledger balance for each account
  def cached_ledger_balance_usd
    return '%.2f' % (cached_ledger_balance.to_r.to_d / 100)
  end

  # Update the account balance with the calculated balance from the ledger
  def update_ledger_balance
    mybal = Ledger.sum(:amount, :account_id => self.id)
    self.cached_ledger_balance = mybal ? mybal : 0
    self.save
  end
  def reopen
    self.attributes = { :closed_on => 0 }
    self.save
  end
  def close
    self.attributes = { :closed_on => Time.now.to_i }
    self.save
  end
end


# Entries comprise the journal. Each entry must have one or more debit or
# credit amount.
class Entry

  include DataMapper::Resource
  include HasAmounts

  property :id,Serial
  property :memorandum,String
  property :status,Integer
  property :fiscal_period_id,Integer
  property :entered_on,Integer, :default => Time.now.to_i
  has n, :credits
  has n, :debits
  has n, :ledgers
  
  # This could be either credit or debit, whatever the balanced amount of the
  # entry is. Perhaps a better name would be amount_sum
  def credit_sum
    # Does not work:
    # !! Unexpected error while processing request:
    # +options[:fields]+ entry #<DataMapper::Property @model=Amount @name=:amount>
    # does not map to a property in Credit
    # UPDATE: I hacked dm-aggregates to make it work
    mysum = Credit.sum(:amount, :entry_id => self.id)
    return '%.2f' % (mysum.to_r.to_d / 100)

    # Works fine, but isn't it the same thing?
    #return '%.2f' % (Amount.sum(:amount, :type => 'Credit', :entry_id => self.id).to_r.to_d / 100)
  end
  def json_entry
    self.to_json(:relationships=>{:credits=>{:methods => [:to_usd]},:debits=>{:methods => [:to_usd]}})
  end

end

# Amounts are directly related to entries.
class Amount

  include DataMapper::Resource
  include HasAmounts

  property :id,Serial
  property :entry_id,Integer
  property :type,Discriminator
  property :amount,Integer
  property :account_id,Integer
  property :memorandum,String
  property :currency_id,Integer
  belongs_to :entry

end

# The Credit amount(s) of the Entry.
class Credit < Amount; end

# The Debit amount(s) of the Entry.
class Debit < Amount; end

# Ledgers are all the transactions which take place within each account.
class Ledger
  include DataMapper::Resource
  include HasAmounts
  
  GENERAL = 'General'
  GENTYPE = 'general'

  ACCTYPE = 'account'

  property :id,Serial
  property :posted_on,Integer
  property :memorandum,String
  property :amount,Integer
  property :account_id,Integer
  property :entry_id,Integer
  property :entry_amount_id,Integer
  property :fiscal_period_id,Integer
  property :currency_id,Integer
  belongs_to :account, :model => 'Account', :child_key => [ :account_id ]
  belongs_to :entry
  belongs_to :entry_amount, :model => 'Amount', :child_key => [ :entry_amount_id ]

  def self.account_ledger(account_id)
    all(:account_id => account_id,:order => [ :posted_on.desc, :amount.desc ])
  end

  # Called from a Ledger instance object, returns the ledger balance
  # for the account after the transaction
  def running_balance

    # The SQL part of the prepared statment
    # Selects all transactions posted on or before the reference transaction
    # that have the same account_id, excludes the reference transaction itself
    thesql = %{
      account_id = ? AND ( posted_on < ? OR (
        posted_on = ? AND ( amount < ? OR ( amount = ? AND id < ? ))
      ))
    }

    # Datamapper conditional query
    presum = Ledger.all( :conditions => [thesql, self.account_id,
              self.posted_on, self.posted_on, self.amount,
              self.amount, self.id ]).sum(:amount)

    return '%.2f' % ( (presum.to_i.to_r.to_d + self.amount) / 100)
  end
end


DataMapper.auto_upgrade!