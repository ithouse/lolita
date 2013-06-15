module Lolita
  module Version
    MAJOR = 3
    MINOR = 2
    PATCH = 1
    BUILD = nil

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')

    def self.to_s
      STRING
    end

    def self.major
      MAJOR
    end

    def self.minor
      MINOR
    end

    def self.patch
      PATCH
    end

    def self.build
      BUILD
    end
  end
end
