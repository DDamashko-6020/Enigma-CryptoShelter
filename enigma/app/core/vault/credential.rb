# frozen_string_literal: true

#
# app/core/vault/credential.rb
# Responsibility: Value object representing a single vault credential.
#   Immutable after creation — fields cannot be modified.
#   Validation: site, username, password must be non-empty.
#

require 'securerandom'
require 'json'
require 'time'
require_relative '../errors'

module Enigma
  module Core
    module Vault
      class Credential
        # @return [String] UUID v4
        attr_reader :id

        # @return [String] service/site name
        attr_reader :site

        # @return [String] username or email
        attr_reader :username

        # @return [String] password
        attr_reader :password

        # @return [String] optional notes
        attr_reader :notes

        # @return [String] ISO8601 creation timestamp
        attr_reader :created_at

        # @param site [String] required
        # @param username [String] required
        # @param password [String] required
        # @param notes [String] optional, defaults to ''
        # @param id [String] optional UUID, auto-generated if nil
        # @param created_at [String] optional ISO8601, auto-generated if nil
        # @raise [Errors::VaultError] if site, username, or password is empty
        def initialize(site:, username:, password:, notes: '', id: nil, created_at: nil)
          raise Enigma::Errors::VaultError, 'site cannot be empty' if site.nil? || site.to_s.empty?
          raise Enigma::Errors::VaultError, 'username cannot be empty' if username.nil? || username.to_s.empty?
          raise Enigma::Errors::VaultError, 'password cannot be empty' if password.nil? || password.to_s.empty?

          @id = id || SecureRandom.uuid
          @site = site
          @username = username
          @password = password
          @notes = notes || ''
          @created_at = created_at || Time.now.utc.iso8601
        end

        # @return [Hash] symbol-keyed representation
        def to_h
          {
            id: @id,
            site: @site,
            username: @username,
            password: @password,
            notes: @notes,
            created_at: @created_at
          }
        end

        # Value equality: two Credentials are equal if they share the same id.
        #
        # @param other [Object]
        # @return [Boolean]
        def ==(other)
          other.is_a?(Credential) && @id == other.id
        end

        # @return [false] real credentials are never null objects
        def null?
          false
        end

        # Reconstruct a Credential from a hash (output of to_h).
        #
        # @param hash [Hash] symbol or string keys
        # @return [Credential]
        def self.from_h(hash)
          h = hash.transform_keys(&:to_sym)
          new(
            site: h[:site],
            username: h[:username],
            password: h[:password],
            notes: h[:notes] || '',
            id: h[:id],
            created_at: h[:created_at]
          )
        end
      end
    end
  end
end
