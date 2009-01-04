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

    # Finds an account named account_name.  Will always return a Response instance.
    def self.find(account_name)
      accounts = Response.from_xml(@@rest.get("/accounts/#{account_name}",{'showUsers' => 'true'}))
      if (accounts.success?)
        accounts.each { |account| return account if account.name == account_name }
        return Error.new("No account named #{account_name}",404)
      else
        return accounts
      end
    end

    @@fake_methods = {
      :users => true,
      :diagrams => true,
      :folders => true,
      :users! => true,
      :diagrams! => true,
      :folders! => true,
    }

    # This handles the logic for accessing these six methods:
    #
    #   +users+ - returns account users as last fetched, fetching if needed
    #   +users!+ - returns account users fetching always
    #   +diagrams+ - returns account diagrams as last fetched, fetching if needed
    #   +diagrams!+ - returns account diagrams fetching always
    #   +folders+ - returns account folders as last fetched, fetching if needed
    #   +folders!+ - returns account folders fetching always
    #
    def method_missing(symbol,*args)
      if @@fake_methods[symbol]
        name = symbol.to_s.gsub(/\!$/,'')
        current_val = eval("@#{name}")
        if symbol.to_s.match(/\!$/) || !current_val
          new_val = Response.from_xml(@@rest.get(create_url(name)))
          if (new_val.success?)
            eval("@#{name} = new_val")
          else
            return new_val
          end
          eval("@#{name}")
        else
          current_val
        end
      else
        super.method_missing(symbol,*args)
      end
    end

    protected

    def create_url(url_fragment="")
      "/accounts/#{name}/#{url_fragment}"
    end

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
