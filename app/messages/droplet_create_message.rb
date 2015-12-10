require 'messages/base_message'
require 'messages/validators'
require 'messages/docker_lifecycle_data_message'

module VCAP::CloudController
  class DropletCreateMessage < BaseMessage
    ALLOWED_KEYS = [:memory_limit, :disk_limit, :environment_variables, :lifecycle]

    attr_accessor(*ALLOWED_KEYS)

    def self.lifecycle_requested?
      @lifecycle_requested ||= proc { |a| a.requested?(:lifecycle) }
    end

    validates_with NoAdditionalKeysValidator
    validates_with LifecycleValidator, if: lifecycle_requested?

    validates :memory_limit, numericality: { only_integer: true }, allow_nil: true
    validates :disk_limit, numericality: { only_integer: true }, allow_nil: true
    validates :environment_variables, environment_variables: true, allow_nil: true

    validates :lifecycle_type,
      string: true,
      allow_nil: false,
      if: lifecycle_requested?

    validates :lifecycle_data,
      hash: true,
      allow_nil: true,
      if: lifecycle_requested?

    def self.create_from_http_request(body)
      DropletCreateMessage.new(body.deep_symbolize_keys)
    end

    def buildpack_data
      @buildpack_data ||= VCAP::CloudController::BuildpackLifecycleDataMessage.new((lifecycle_data || {}).symbolize_keys)
    end

    def lifecycle_data
      lifecycle.try(:[], 'data') || lifecycle.try(:[], :data)
    end

    def lifecycle_type
      lifecycle.try(:[], 'type') || lifecycle.try(:[], :type)
    end

    private

    def allowed_keys
      ALLOWED_KEYS
    end
  end
end
