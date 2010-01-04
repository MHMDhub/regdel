[REGDEL](http://www.regdel.com/)
========

Summary
-------

Regdel is a double-entry accounting system written in Ruby, complete with
accounts, a general journal, general ledger, and account ledgers. It is mostly
based off of my experience writing [PBooks](http://www.pbooks.org), a double-entry system written in PHP.

[Regdel Demonstration](http://www.regdel.com/demo/regdel/)


Quick Start
-----------

<pre class="sh_sh">
git clone git://github.com/docunext/regdel.git
cd regdel
git submodule init
git submodule update
ruby regdel.rb
</pre>


Status
------

* 2010-01 Alpha
* 2009-12 Project Started


Requirements
------------

* Sinatra
* Rack-XSLView
* DataMapper
* SQLite / MySQL
* Builder, Sass, Yui-App-Theme
* Nokogiri


Components
----------

* Data model is specified in XML, transformed into classes for use by DataMapper
by XSL
* Views are XML-based and built Ruby Builder
* User interface is rendered via XHTML and XSL by Nokogiri or NGINX


License
-------

Regdel is licensed under the [Affero GPLv3](http://www.fsf.org/licensing/licenses/agpl-3.0.html).

The Regdel source includes components from several other open source projects
of varyious licenses.
