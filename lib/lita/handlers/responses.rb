module Lita
  module Handlers
    class Responses < Handler
      on :loaded, :define_responses

      def define_responses(payload)
        puts "defining static routes"
        define_static_routes
        # define_dynamic_routes
      end

      def define_static_routes
        self.class.route(
          %r{^respond to "(.+?)" with "(.+?)"}i,
          :add_response,
          command: true
        )

        self.class.route(
          %r{^stop responding to "(.+?)"$}i,
          :remove_response,
          command: true
        )

        self.class.route(
          %r{^list all responses$}i,
          :list_responses,
          command: true
        )

        self.class.route(
          %r{^(.+?)$}i,
          :lookup_response
        )
      end

      def add_response(response)
        puts "Adding response"
        q = response.matches[0][0].strip
        a = response.matches[0][1]

        update_response q, a

        response.reply_with_mention "You got it!"
      end

      def remove_response(response)
        q = response.matches[0][0]

        remove q

        response.reply_with_mention "Consider it forgotten, cap'n!"
      end

      def list_responses(response)
        keys = redis.keys('lita-responses:*').sort
        responses = redis.mget(keys)
        body_pieces = []

        for i in 0..keys.length
          body_pieces.push("\"#{keys[i].gsub('lita-responses:', '')}\" ==> \"#{responses[i]}\"") if keys[i] != nil && responses[i] != nil
        end

        response.reply_privately body_pieces
        response.reply_with_mention "Check your DMs!" unless response.private_message?
      end

      def update_response(question, answer)
        redis.set full_key(question), answer
      end

      def remove(question)
        if redis.exists(full_key(question))
          redis.del(full_key(question))
        end
      end

      def lookup_response(response)
        q = response.matches[0][0]
        answer = nil
        if redis.exists(full_key(q))
          answer = redis.get(full_key(q))
        end
        response.reply_with_mention answer if answer
      end

      def full_key(key)
        "lita-responses:#{key.downcase}"
      end
    end

    Lita.register_handler(Responses)
  end
end
