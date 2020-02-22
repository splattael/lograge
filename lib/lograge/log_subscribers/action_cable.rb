module Lograge
  module LogSubscribers
    class ActionCable < Base
      %i(perform_action subscribe unsubscribe connect disconnect).each do |method_name|
        alias_method method_name, :process_main_event
        public method_name
      end

      private

      def extract_request(data, event, _payload)
        super
        extract_runtimes(data, event)
      end

      def initial_data(payload)
        {
          params: payload[:data],
          controller: payload[:channel_class] || payload[:connection_class],
          action: payload[:action]
        }
      end

      def default_status
        200
      end

      def extract_runtimes(data, event)
        data[:duration] = event.duration.to_f.round(2)
      end
    end
  end
end
