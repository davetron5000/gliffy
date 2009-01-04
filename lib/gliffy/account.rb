require 'rexml/document'
require 'array_has_response'
require 'gliffy/rest'

include REXML

module Gliffy

  # Represents on account
  class Account < Response

    attr_reader :name
    attr_reader :id
    # Either :basic or :premium
    attr_reader :type
    attr_reader :max_users
    # A Time representing the date on which this account expires
    attr_reader :expiration_date

    attr_reader :users

    def self.from_xml(element)
      id = element.attributes['id'].to_i
      type = element.attributes['account-type']
      if type == 'Basic'
        type = :basic
      elsif type == 'Premium'
        type = :premium
      else
        raise "Unknown type #{type}"
      end
      max_users = element.attributes['max-users'].to_i
      expiration_date = Time.at(element.elements['expiration-date'].text.to_i / 1000)
      name = element.elements['name'].text
      users = Users.from_xml(element.elements['users'])

      Account.new(id,type,name,max_users,expiration_date,users)
    end

    protected

    def initialize(id,type,name,max_users,expiration_date,users=nil)
      super()
      @id = id
      @type = type
      @name = name
      @max_users = max_users
      @expiration_date = expiration_date
      @users = users
    end

  end

  class Accounts < ArrayResponseParser; end
end
