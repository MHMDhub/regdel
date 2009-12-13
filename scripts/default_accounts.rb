require 'rubygems'
require 'builder'
require 'bigdecimal'
require 'bigdecimal/util'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-serializer'
require 'dm-aggregates'

require 'data/regdel_dm'


class RdMoney < String
    def no_d
        return (self.gsub(/[^0-9\.]/,'').to_d * 100).to_i
    end
end


Account.new(
:id =>  1,
:number =>  "12344",
:name =>  "Bank USA",
:type_id =>  10000,
:description =>  "",
:created_on =>  1260181164,
:closed_on =>  0
).save

Account.new(
:id =>  2,
:number =>  "11222",
:name =>  "Cash",
:type_id =>  10000,
:description =>  " ",
:created_on =>  1260181164,
:closed_on =>  0
).save

Account.new(
:id =>  3,
:number =>  "22333",
:name =>  "Electricity",
:type_id =>  20000,
:description =>  "",
:created_on =>  1260181164,
:closed_on =>  0
).save

Account.new(
:id =>  4,
:number =>  "22334",
:name =>  "Taxes",
:type_id =>  20000,
:description =>  "",
:created_on =>  1260181164,
:closed_on =>  0
).save

Account.new(
:id =>  5,
:number =>  "40011",
:name =>  "Professional Services",
:type_id =>  40000,
:description =>  "",
:created_on =>  1260181164,
:closed_on =>  0
).save
