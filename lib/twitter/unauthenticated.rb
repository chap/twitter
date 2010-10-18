module Twitter
  class Unauthenticated

    def initialize(options={})
      @adapter = options.delete(:adapter)
      @api_endpoint = "api.twitter.com/#{Twitter.api_version}"
      @api_endpoint = Addressable::URI.heuristic_parse(@api_endpoint)
      @api_endpoint = @api_endpoint.to_s
    end

    def firehose(options = {})
      perform_get("statuses/public_timeline.#{Twitter.format}", options)
    end

    def user(user_id_or_screen_name, options={})
      merge_user_into_options!(user_id_or_screen_name, options)
      perform_get("users/show.#{Twitter.format}", options)
    end

    def profile_image(screen_name, options={})
      connection_with_unparsed_response.get do |request|
        request.url("users/profile_image/#{screen_name}.#{Twitter.format}", options)
      end.headers["location"]
    end

    def suggestions(category_slug=nil, options={})
      path = case category_slug
      when nil
        "users/suggestions.#{Twitter.format}"
      when Hash
        options = category_slug
        "users/suggestions.#{Twitter.format}"
      else
        "users/suggestions/#{category_slug}.#{Twitter.format}"
      end
      perform_get(path, options)
    end

    def retweeted_to_user(user_id_or_screen_name, options={})
      merge_user_into_options!(user_id_or_screen_name, options)
      perform_get("statuses/retweeted_to_user.#{Twitter.format}", options)
    end

    def retweeted_by_user(user_id_or_screen_name, options={})
      merge_user_into_options!(user_id_or_screen_name, options)
      perform_get("statuses/retweeted_by_user.#{Twitter.format}", options)
    end

    def status(id, options={})
      perform_get("statuses/show/#{id}.#{Twitter.format}", options)
    end

    def friend_ids(user_id_or_screen_name, options={})
      merge_user_into_options!(user_id_or_screen_name, options)
      perform_get("friends/ids.#{Twitter.format}", options)
    end

    def follower_ids(user_id_or_screen_name, options={})
      merge_user_into_options!(user_id_or_screen_name, options)
      perform_get("followers/ids.#{Twitter.format}", options)
    end

    def timeline(user_id_or_screen_name, options={})
      merge_user_into_options!(user_id_or_screen_name, options)
      perform_get("statuses/user_timeline.#{Twitter.format}", options)
    end

    def lists_subscribed(user_id_or_screen_name, options={})
      merge_user_into_options!(user_id_or_screen_name, options)
      perform_get("lists/all.#{Twitter.format}", options)
    end

    # :per_page = max number of statues to get at once
    # :page = which page of tweets you wish to get
    def list_timeline(list_owner_screen_name, slug, options = {})
      perform_get("#{list_owner_screen_name}/lists/#{slug}/statuses.#{Twitter.format}", options)
    end

    private

    def connection
      builders = []
      builders << Faraday::Response::RaiseHttp5xx
      case Twitter.format.to_s
      when "json"
        builders << Faraday::Response::ParseJson
      when "xml"
        builders << Faraday::Response::ParseXml
      end
      builders << Faraday::Response::RaiseHttp4xx
      builders << Faraday::Response::Mashify
      connection_with_builders(builders)
    end

    def connection_with_unparsed_response
      builders = []
      builders << Faraday::Response::RaiseHttp5xx
      builders << Faraday::Response::RaiseHttp4xx
      connection_with_builders(builders)
    end

    def connection_with_builders(builders)
      headers = {:user_agent => Twitter.user_agent}
      ssl = {:verify => false}
      @connection = Faraday::Connection.new(:url => @api_endpoint, :headers => headers, :ssl => ssl) do |builder|
        builder.adapter(@adapter || Faraday.default_adapter)
        builders.each do |b| builder.use b end
      end
      @connection.scheme = Twitter.protocol
      @connection
    end

    def perform_get(path, options={})
      results = connection.get do |request|
        request.url(path, options)
      end.body
    end

    def merge_user_into_options!(user_id_or_screen_name, options={})
      case user_id_or_screen_name
      when Fixnum
        options[:user_id] = user_id_or_screen_name
      when String
        options[:screen_name] = user_id_or_screen_name
      end
      options
    end

  end
end
