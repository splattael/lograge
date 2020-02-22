require 'json'
require 'action_pack'
require 'active_support/core_ext/class/attribute'
require 'active_support/log_subscriber'
require 'request_store'

module Lograge
  module LogSubscribers
    class Base < ActiveSupport::LogSubscriber
      def logger
        Lograge.logger.presence || super
      end

      private

      def process_main_event(event)
        return if Lograge.ignore?(event)

        payload = event.payload
        data = initial_data(payload)
        extract_request(data, event, payload)
        data = before_format(data, payload)
        formatted_message = Lograge.formatter.call(data)
        logger.send(Lograge.log_level, formatted_message)
      end

      def extract_request(data, event, payload)
        extract_status(data, payload)
        custom_options(data, event)
      end

      def initial_data(_payload)
        raise 'not implemented'
      end

      def extract_status(data, payload)
        if (status = payload[:status])
          data[:status] = status.to_i
        elsif (error = payload[:exception])
          exception, message = error
          data[:status] = get_error_status_code(exception)
          data[:error] = "#{exception}: #{message}"
        else
          data[:status] = default_status
        end
      end

      def default_status
        0
      end

      def get_error_status_code(exception)
        status = ActionDispatch::ExceptionWrapper.rescue_responses[exception]
        Rack::Utils.status_code(status)
      end

      def custom_options(data, event)
        options = Lograge.custom_options(event).dup || {}

        if (custom_payload = event.payload[:custom_payload])
          options.merge!(custom_payload)
        end

        data.merge!(options)
      end

      def before_format(data, payload)
        Lograge.before_format(data, payload)
      end
    end
  end
end
