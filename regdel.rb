###
# Program:: http://www.regdel.com
# Component:: regdel.rb
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
require 'sinatra/base'
require 'builder'
require 'xml/xslt'
require 'sass'
require 'grit'
include Grit
require 'rack/utils'
require 'rack/contrib'
require 'rack-rewrite'
require 'rack-xslview'
require 'rexml/document'
require 'rack-docunext-content-length'

require 'data/regdel-dm-modules'
require 'data/regdel_dm'
require 'data/account_types'
require 'data/development'
require 'helpers/xslview'

class Ledger
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

    return "%.2f" % ( (presum.to_i.to_r.to_d + self.amount) / 100)
  end
end

# The container for the Regdel application
module Regdel

  class << self
    # uripfx     the prefix before Regdel's paths
    # omitxsl    paths which should not be transformed by rack-xslview
    # passenv    env vars to pass to rack-xslview
    # dirpfx     directory where regdel is located
    # xslt       xslt object
    # xslfile    xsl file
    # started_at the time when regdel was started
    attr_accessor(:uripfx, :omitxsl, :passenv, :dirpfx, :xslt, :xslfile, :started_at)
  end

  # Set the uriprefix
  def self.new(uripfx='', dirpfx='/var/www/dev/regdel')
    self.uripfx = uripfx
    self.dirpfx = dirpfx
    Main
  end

  # Regdel money object inherits string
  class RdMoney < String

    # Converts string representation of USD to amounts in cents
    def no_d
        return (self.gsub(/[^0-9\.]/,'').to_d * 100).to_i
    end
  end

  # The Regdel Sinatra application
  class Main < Sinatra::Base

    # BEGIN Regdel Configuration and Rack middleware usage
    configure do
      Regdel.dirpfx = File.dirname(__FILE__)
      set :static, true
      set :pagination, 10
      set :views, Regdel.dirpfx + '/views'
      set :xslviews, Regdel.dirpfx + '/views/xsl/'
      set :public, Regdel.dirpfx + '/public'

      # Set request.env with application mount path
      use Rack::Config do |env|
        env['RACK_MOUNT_PATH'] = Regdel.uripfx
        env['RACK_ENV'] = ENV['RACK_ENV'] ? ENV['RACK_ENV'] : "none"
      end

      # Setup XSL
      Regdel.xslt = XML::XSLT.new()
      Regdel.xslfile = File.open(Regdel.dirpfx + '/views/xsl/html_main.xsl')
      Regdel.xslt.xsl = REXML::Document.new Regdel.xslfile

      # Used in runtime/info
      Regdel.started_at = Time.now.to_i

      # Setup paths to remove from Rack::XSLView, and params to include
      Regdel.omitxsl = ['/raw/', '/s/js/', '/s/css/', '/s/img/']
      Regdel.passenv = ['PATH_INFO', 'RACK_MOUNT_PATH', 'RACK_ENV']
    end

    configure :production do
      set :cachem, 3
    end

    configure :development do
      Sinatra::Application.reset!
      use Rack::Lint
      use Rack::Reloader
      set :logging, false
      set :cachem, 1
    end

    configure :demo do
      use Rack::CommonLogger
      set :logging, true
      set :cachem, 6
    end
    # CLOSE Regdel Configuration

    # Rewrite app url patterns to static files
    use Rack::Rewrite do
      rewrite Regdel.uripfx+'/ledger', '/d/xhtml/ledger.html'
      rewrite Regdel.uripfx+'/entry/new', '/s/xhtml/entry_all_form.html'
      rewrite %r{#{Regdel.uripfx}/entry/edit(.*)}, '/s/xhtml/entry_all_form.html'
      rewrite Regdel.uripfx+'/account/new', '/s/xhtml/account_form.html'
      rewrite %r{#{Regdel.uripfx}/account/new(.*)}, '/s/xhtml/account_form.html'
      rewrite %r{#{Regdel.uripfx}/account/edit/(.*)}, '/s/xhtml/account_form.html?id=$1'
      rewrite Regdel.uripfx+'/', '/s/xhtml/welcome.html'
      rewrite Regdel.uripfx+'/account/new', '/s/xhtml/account_form.html'
      r301 Regdel.uripfx+'/journal', Regdel.uripfx+'/journal/0'
    end

    # Recalculate Content-Length
    use Rack::DocunextContentLength

    # Use Rack-XSLView
    use Rack::XSLView, :myxsl => Regdel.xslt, :noxsl => Regdel.omitxsl, :passenv => Regdel.passenv

    # Sinatra Helpers
    helpers Sinatra::XSLView

    before do
      # More aggressive cache settings for static files
      if request.env['REQUEST_URI']
        if request.env['REQUEST_URI'].include? '/s/'
          if request.env['HTTP_IF_MODIFIED_SINCE']
            headers 'Cache-Control' => "public, max-age=#{options.cachem*80}"
          else
            headers 'Cache-Control' => "public, max-age=#{options.cachem*40}"
          end
        elsif request.env['REQUEST_URI'].include? '/d/'
          headers 'Cache-Control' => "must-revalidate, max-age=#{options.cachem*10}"
        else
          headers 'Cache-Control' => "max-age=#{options.cachem}"
        end
      end

      # POSTs indicate data alterations, rebuild cache and semi-dynamic database entries
      if request.env['REQUEST_METHOD'].upcase == 'POST'
        rebuild_ledger(Regdel.dirpfx + '/public/d/xhtml/ledger.html')
        Account.all.each do |myaccount|
          myaccount.update_ledger_balance
        end
      end
    end

    helpers do
      # Just the usual Sinatra redirect with App prefix
      def mredirect(uri)
        redirect Regdel.uripfx+uri
      end
      def xresult(message)
        "<result>#{message}</result>"
      end
      def json_entry(entry_id)
        Entry.get(entry_id).to_json(:relationships=>{:credits=>{:methods => [:to_usd]},:debits=>{:methods => [:to_usd]}})
      end
    end
###
#
#    # Example gates as written in Regdel:
#
#    get '/path' do
#      # DataMapper to get some data
#      @resultset = Stuff.open
#
#      # Builder to output data to XML
#      example = builder :'xml/example'
#
#      # XSLview Sinatra helper to transform XML to XML, HTML, or Text
#      xslview accounts, Regdel.dirpfx + '/views/xsl/accounts.xsl'
#    end
#
##

    get '/accounts' do
      # Set scoped account types - FIXME
      @my_account_types = @@account_types
      @accounts = Account.open
      accounts = builder :'xml/accounts'
      xslview accounts, 'accounts.xsl'
    end

    get '/json/account/:id' do
      content_type :json
      Account.get(params[:id]).to_json
    end

    post '/account/submit' do
      # Check if this is an existing record. If so, update it.
      if params[:id].to_i > 0
        @account = Account.get(params[:id])
        error_target = '/account/edit/' + params[:id]

      # If this is not an existing record, create a new one
      else
        @account = Account.new
        error_target = '/account/new'
      end

      @account.attributes = {
        :name => params[:name],
        :type_id => params[:type_id],
        :number => params[:number],
        :description => params[:description],
        :hide => params[:hide]
      }
      if @account.save
        mredirect '/accounts'
      else
        mredirect error_target + '?error=' + handle_error(@account.errors)
      end
    end

    post '/account/close' do
      content_type 'application/xml', :charset => 'utf-8'
      if @account = Account.get(params[:id])
        @account.attributes = { :closed_on => Time.now.to_i }
        if @account.save
          xresult 'Success'
        else
          handle_error(@account.errors)
        end
      else
        xresult 'No account found'
      end
    end
    post '/account/reopen' do
      content_type 'application/xml', :charset => 'utf-8'
      if @account = Account.get(params[:id])
        @account.attributes = { :closed_on => 0 }
        if @account.save
          xresult 'Success'
        else
          handle_error(@account.errors)
        end
      else
        xresult 'No account found'
      end
    end
    
    post '/account/delete' do
      # TODO Called via AJAX or real browser request?
      content_type 'application/xml', :charset => 'utf-8'
      @account = Account.get(params[:id])
      if @account.destroy!
        mredirect '/accounts'
      else
        handle_error(@account.errors)
      end
    end
    
    post '/entry/submit' do
      # Existing or new entry?
      if params[:id].to_i > 0
        @entry = Entry.get(params[:id])
      else
        @entry = Entry.new
      end
      @entry.attributes = { :memorandum => params[:memorandum] }
      @entry.save
      @entry.credits.destroy!
      @entry.debits.destroy!
      params[:credit_amount].each_index {|x|
        @myamt = @entry.credits.create(
          :amount => RdMoney.new(params[:credit_amount][x]).no_d,
          :account_id => params[:credit_account_id][x]
        )
        @myamt.save
      }
      params[:debit_amount].each_index {|x|
        @myamt = @entry.debits.create(
          :amount => RdMoney.new(params[:debit_amount][x]).no_d,
          :account_id => params[:debit_account_id][x]
        )
        @myamt.save
      }
      mredirect '/journal'
    end

    get '/json/entry/:id' do
      content_type :json
      json_entry params[:id]
    end

    get '/journal/:offset' do
      # How many journal entries are there?
      count = Entry.count()

      myoffset = params[:offset].to_i
      incr = options.pagination

      @myentries = Entry.all(:limit => options.pagination, :offset => myoffset)
      @prev   = (myoffset - incr) < 0 ? 0 : myoffset - incr
      @next   = myoffset + incr > count ? myoffset : myoffset + incr
      entries = builder :'xml/entries'
      xslview entries, 'journal.xsl'
    end

    get '/ledgers/account/:account_id' do
      @ledger_label    = Account.get(params[:account_id]).name
      @ledger_type     = "account"
      @mytransactions  = Ledger.all(:account_id => params[:account_id],:order => [ :posted_on.desc,:amount.desc ])
      transactions  = builder :'xml/transactions'
      xslview transactions, 'ledgers.xsl'
    end

    get '/stylesheet.css' do
      content_type 'text/css', :charset => 'utf-8'
      sass 'css/regdel'.to_sym
    end

    not_found do
      headers 'Last-Modified' => Time.now.httpdate, 'Cache-Control' => 'no-store'
      %(<p>This is nowhere to be found. <a href="#{Regdel.uripfx}/">Start over?</a></p>)
    end




    get '/raw/journal' do
      @myentries = Entry.all
      builder :'xml/journal_complete'
    end
    get '/raw/xml/ledger' do
      @ledger_label = "General"
      @ledger_type = "general"
      @mytransactions = Ledger.all( :order => [ :posted_on.desc ] )
      transactions = builder :'xml/transactions'
    end
    get '/raw/entries' do
        content_type 'application/xml', :charset => 'utf-8'
        @myentries = Entry.all
        builder :'xml/entries'
    end
    get '/raw/transactions' do
      content_type 'application/xml', :charset => 'utf-8'
      @mytrans = Ledger.all
      @mytrans.to_xml
    end
    get '/raw/account/select' do
      content_type 'application/xml', :charset => 'utf-8'
      @accounts = Account.open
      builder :'xml/account_select'
    end
    get '/raw/accounts' do
      Account.get(1).update_ledger_balance
      content_type 'application/xml', :charset => 'utf-8'
      @my_account_types = @@account_types
      @accounts = Account.open
      builder :'xml/accounts'
    end
    get '/raw/ledger' do
      @ledger_label = "General"
      @ledger_type = "general"
      @mytransactions = Ledger.all( :order => [ :posted_on.desc ])
      transactions = builder :'xml/transactions'
      xslview transactions, 'ledgers.xsl'
    end

    delete '/delete/ledger' do
      rebuild_ledger(Regdel.dirpfx + '/public/d/xhtml/ledger.html')
      mredirect '/ledger'
    end


    get '/regdel/runtime/info' do
      @uptime   = (0 + Time.now.to_i - Regdel.started_at).to_s
      runtime   = builder :'xml/runtime'
      xslview runtime, 'runtime.xsl'
    end


    private
    # This rebuilds a static file from updated dynamic data sets
    def rebuild_ledger(targetfile)

      if File.exists?(targetfile)
        File.delete(targetfile)
      end

      Ledger.all.destroy!
      # Data set from DataMapper
      amounts = Amount.all

      amounts.each do |myamount|

        myid = myamount.entry_id
        myentry = Entry.get(myid)

        newtrans = Ledger.new(
          :posted_on => myentry.entered_on,
          :memorandum => myentry.memorandum,
          :amount => myamount.amount,
          :account_id => myamount.account_id,
          :entry_id => myamount.entry_id,
          :entry_amount_id => myamount.id
          ).save
      end
      begin
        @ledger_label = "General"
        @ledger_type = "general"
        @mytransactions = Ledger.all( :order => [ :posted_on.desc ])
        transactions = builder :'xml/transactions'
        xhtmltransaction = xslview transactions, 'ledgers.xsl'
        myfile = File.new(targetfile,"w")
        myfile.write(xhtmltransaction)
        myfile.close
      rescue StandardError
        # Close file handle and then delete
        myfile.close
        File.delete(myfile)
        halt %(<p><a href="#{Regdel.uripfx}/">Error, start over?</a></p>)
      end
    end

    def handle_error(errors)
      myerrors = ""
      errors.each do |e|
        myerrors << e.to_s
      end
      return myerrors
    end
  end
end

if __FILE__ == $0
  Regdel.new('','.').run!
end
