require "zabbix_graph/version"
require "zabbixapi"

module ZabbixGraph
  class CLI
    def self.start(argv)
      Opener.new.select_and_open
    end
  end

  class Opener
    def select_and_open
      hosts = zbx.hosts.get
      p hosts
    end

    private

    def zbx
      @zbx ||= ZabbixApi.connect(
        url: URI.join(zabbix_url, '/api_jsonrpc.php').to_s,
        user: zabbix_user,
        password: zabbix_password,
      )
    end

    def zabbix_url
      env('ZABBIX_URL')
    end

    def zabbix_user
      env('ZABBIX_USER')
    end

    def zabbix_password
      env('ZABBIX_PASSWORD')
    end

    def env(key)
      ret = ENV[key]

      unless ret
        $stderr.puts "#{key} is not set."
        abort
      end

      ret
    end
  end
end
