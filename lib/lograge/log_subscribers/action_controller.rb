module Lograge
  module LogSubscribers
    class ActionController < Base
      def process_action(event)
        process_main_event(event)
      end

      def redirect_to(event)
        RequestStore.store[:lograge_location] = event.payload[:location]
      end

      def unpermitted_parameters(event)
        RequestStore.store[:lograge_unpermitted_params] ||= []
        RequestStore.store[:lograge_unpermitted_params].concat(event.payload[:keys])
      end

      private

      def extract_request(data, event, payload)
        super
        extract_runtimes(data, event, payload)
        extract_location(data)
        extract_unpermitted_params(data)
      end

      def initial_data(payload)
        {
          method: payload[:method],
          path: extract_path(payload),
          format: extract_format(payload),
          controller: payload[:controller],
          action: payload[:action]
        }
      end

      def extract_path(payload)
        path = payload[:path]
        strip_query_string(path)
      end

      def strip_query_string(path)
        index = path.index('?')
        index ? path[0, index] : path
      end

      if ::ActionPack::VERSION::MAJOR == 3 && ::ActionPack::VERSION::MINOR.zero?
        def extract_format(payload)
          payload[:formats].first
        end
      else
        def extract_format(payload)
          payload[:format]
        end
      end

      def extract_runtimes(data, event, payload)
        payload = event.payload
        data[:duration] = event.duration.to_f.round(2)
        data[:view] = payload[:view_runtime].to_f.round(2) if payload.key?(:view_runtime)
        data[:db] = payload[:db_runtime].to_f.round(2) if payload.key?(:db_runtime)
      end

      def extract_location(data)
        location = RequestStore.store[:lograge_location]
        return unless location

        RequestStore.store[:lograge_location] = nil
        data[:location] = strip_query_string(location)
      end

      def extract_unpermitted_params(data)
        unpermitted_params = RequestStore.store[:lograge_unpermitted_params]
        return unless unpermitted_params

        RequestStore.store[:lograge_unpermitted_params] = nil

        data[:unpermitted_params] = unpermitted_params
      end
    end
  end
end
