# frozen_string_literal: true

module Lograge
  module Formatters
    class Graylog2
      include Lograge::Formatters::Helpers::MethodAndPath

      def call(data)
        # Cloning because we don't want to mess with the original when mutating keys.
        data_clone = data.clone

        base = {
          short_message: short_message(data_clone)
        }

        # Add underscore to every key to follow GELF additional field syntax.
        data_clone.keys.each do |key|
          data_clone[underscore_prefix(key)] = data_clone[key]
          data_clone.delete(key)
        end

        data_clone.merge(base)
      end

      def underscore_prefix(key)
        "_#{key}".to_sym
      end

      def short_message(data)
        "[#{data[:status]}]#{method_and_path_string(data)}(#{data[:controller]}##{data[:action]})"
      end
    end
  end
end
