module Calabash
  class Query < String
    def self.web_query?(query_string)
      # :no, :double or :single
      in_quotes = :no

      # Number of slashes before the current char
      slash_count = 0

      # If the query starts with css: or xpath:
      # We could change the regex from /(\s|\'|\")css:/ to /(^|\s|\'|\")css:/
      # and change if (query[i, indicator[:length]] =~ indicator[:regex]) == 0
      # to if (query[0, i+indicator[:length]] =~ indicator[:regex]) == i
      # (not working)
      # to avoid having to do this check.
      results = WEB_QUERY_INDICATORS.map do |indicator|
        query_string =~ /^\s*#{indicator[:string]}/
      end

      if results.any?
        return true
      end

      length = query_string.length

      length.times do |i|
        char = query_string[i]

        if char == "\\"
          slash_count += 1
          next
        end

        if char == "'"
          if slash_count == 0
            if in_quotes == :no
              in_quotes = :single
            elsif in_quotes == :single
              in_quotes = :no
            end
          end
        elsif char == '"'
          if slash_count == 0
            if in_quotes == :no
              in_quotes = :double
            elsif in_quotes == :double
              in_quotes = :no
            end
          end
        end

        if slash_count == 0 && in_quotes == :no
          WEB_QUERY_INDICATORS.each do |indicator|
            if (query_string[i, indicator[:length]] =~ indicator[:regex]) == 0
              return true
            end
          end
        end

        slash_count = 0
      end

      false
    end

    def self.query_hash_to_string(hash)
      result = hash.fetch(:class, '*')

      if hash[:mark]
        result = "#{result} marked:'#{hash[:mark]}'"
      end

      if hash[:index]
        result = "#{result} index:#{hash[:index]}"
      end

      if hash[:css]
        result = "#{result} css:'#{hash[:css]}'"
      end

      if hash[:xpath]
        result = "#{result} xpath:'#{hash[:xpath]}'"
      end

      result
    end

    def self.new(query='')
      query_string = if query.is_a?(Hash)
                       Query.query_hash_to_string(query)
                     else
                       query.dup
                     end

      r = super(query_string)

      r
    end

    def initialize(*args)
      super

      freeze
    end

    def web_query?
      Query.web_query?(self)
    end

    WEB_QUERY_INDICATORS =
        [
            {
                string: 'css:',
                regex: /(\s|\'|\")css:/,
                length: 5
            },
            {
                string: 'xpath:',
                regex: /(\s|\'|\")xpath:/,
                length: 7
            }
        ]
  end
end
